# Поднимает стенд, на котором сняты before/after: компилирует тему вместе с
# настоящими стилями ActiveAdmin в каждой конфигурации, генерит страницы и
# отдаёт их по HTTP. Rails-приложение не нужно.
#
#   ruby docs/pr-47-fixes/preview.rb        # http://localhost:8731/
#
# "before" получается обратным применением патча к текущему файлу темы, так что
# вторую копию темы хранить не нужно.
require "sassc"
require "webrick"
require "tmpdir"
require "fileutils"

HERE  = __dir__
PORT  = Integer(ENV.fetch("PORT", 8731))
OUT   = File.join(Dir.tmpdir, "pr47-preview")

# Конфигурации, в которых снимались кадры. Ключ — суффикс в имени страницы.
CONFIGS = {
  "def"   => ["", ""],
  "light" => ['$skinMenuPanelColor:#ffffff; $skinMenuTextColor:#333333; $skinMenuPillColor:#f0f0f0;',
              '$skinMenuPanelColor:#ffffff; $skinMenuTextColor:#333333; $skinMenuPillColor:#f0f0f0; $skinMenuPillTextColor:#222222;'],
  "dark"  => ['$skinMenuPanelColor:#222222;'] * 2,
  "font"  => ['$skinMenuFontSize:1.6em;'] * 2,
  "pad"   => ['$skinMenuItemPaddingY:14px;'] * 2,
  "split" => ['$skinMenuPillColor:#e63946;'] * 2,
  "btn"   => ['$skinTitleBarButtonPaddingY:6px; $skinTitleBarButtonPaddingX:14px;'] * 2,
  "focus" => ['$skinMenuItemHoverColor:#3a7fb5;'] * 2,
}.freeze

# Какая страница + что навести, для каждой подпапки.
CASES = {
  "01-menu-text-color"           => ["p_%s_light", "навести System, потом пункт Users"],
  "02-dropdown-width"            => ["vp.html?src=s_%s_def.html", "навести System, потом Components (окно 1280px)"],
  "03-dropdown-row-height"       => ["p_%s_def", "навести System"],
  "04-pill-panel-seam"           => ["p_%s_split", "навести System, смотреть стык пилюли и панели"],
  "05-header-vertical-shift"     => ["p_%s_def", "ничего не наводить, смотреть на позицию текста в хедере"],
  "06-submenu-marker-color"      => ["p_%s_dark", "навести System, смотреть маркер у Configuration Settings"],
  "07-marker-vertical-centering" => ["p_%s_pad", "навести System, смотреть маркер относительно текста"],
  "08-menu-font-size-leak"       => ["p_%s_font", "навести System"],
  "09-titlebar-button-padding"   => ["p_%s_btn", "ничего не наводить, смотреть New Post и Batch Actions"],
  "10-keyboard-focus"            => ["p_%s_focus", "навести System, затем в консоли: $$('#sysmenu>ul>li>a')[2].focus()"],
}.freeze

def theme_dir(variant)
  dir = File.join(OUT, "theme_#{variant}", "wigu")
  FileUtils.mkdir_p(dir)
  dst = File.join(dir, "active_admin_theme.scss")
  FileUtils.cp(File.expand_path("../../app/assets/stylesheets/wigu/active_admin_theme.scss", HERE), dst)
  if variant == "before"
    patch = File.join(HERE, "active_admin_theme.scss.patch")
    system("patch", "-R", "-s", dst, patch, exception: true)
  end
  File.dirname(dir)
end

def compile(root, config)
  aa = File.join(Gem::Specification.find_by_name("activeadmin").gem_dir, "app/assets/stylesheets")
  src = %(@import "active_admin/mixins";\n#{config}\n@import "active_admin/base";\n) +
        %(@import "wigu/active_admin_theme";\n)
  SassC::Engine.new(src, load_paths: [aa, root], style: :expanded).render
end

FileUtils.mkdir_p(OUT)
tpl = File.read(File.join(HERE, "harness.tpl.html"))
# Стресс-разметка для кейса 02: System отжат вправо, длинный лейбл в подменю.
stress = tpl
  .sub('<li class="has_nested" id="sysmenu">',
       %w[Invoices Payments Webhooks].map { |t| %(<li><a href="#">#{t}</a></li>\n      ) }.join +
       '<li class="has_nested" id="sysmenu">')
  .sub("Outbound Notification Delivery Settings", "Outbound SMS Delivery Receipt Reconciliation Settings")

%w[before after].each do |variant|
  root = theme_dir(variant)
  CONFIGS.each do |name, (before_cfg, after_cfg)|
    css = "out_#{variant}_#{name}.css"
    File.write(File.join(OUT, css), compile(root, variant == "before" ? before_cfg : after_cfg))
    { "p" => tpl, "s" => stress }.each do |prefix, markup|
      File.write(File.join(OUT, "#{prefix}_#{variant}_#{name}.html"),
                 markup.gsub("__CSS__", css).gsub("__TITLE__", "#{variant} / #{name}"))
    end
  end
  puts "скомпилировано: #{variant}"
end

# Обёртка ровно в 1280px — «за краем окна» видно как красное поле.
File.write(File.join(OUT, "vp.html"), <<~HTML)
  <!doctype html><meta charset="utf-8"><title>viewport 1280</title>
  <style>body{margin:0;background:#c00;font:12px/1.4 monospace;color:#fff}
   .bar{padding:3px 6px} iframe{width:1280px;height:230px;border:0;display:block;background:#fff}</style>
  <div class="bar">viewport 1280px — красное поле находится за краем окна браузера</div>
  <iframe id="f"></iframe>
  <script>f.src = new URLSearchParams(location.search).get('src')</script>
HTML

puts "\nhttp://localhost:#{PORT}/  (Ctrl-C чтобы остановить)\n\n"
CASES.each do |folder, (page, how)|
  puts folder
  %w[before after].each { |v| puts "  #{v.ljust(6)} /#{page.include?('?') ? page % v : "#{page % v}.html"}" }
  puts "  #{how}\n\n"
end

server = WEBrick::HTTPServer.new(Port: PORT, DocumentRoot: OUT, AccessLog: [], Logger: WEBrick::Log.new(File::NULL))
trap("INT") { server.shutdown }
server.start
