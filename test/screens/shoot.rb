# Takes one screenshot per scenario against a given revision of the theme.
#
#   ruby test/screens/shoot.rb --theme-root app/assets/stylesheets --out tmp/after
#
# The dummy app (test/screens/dummy.rb) supplies ActiveAdmin's real markup. The
# theme is compiled here with sassc and swapped into the page, rather than wired
# through the app's asset pipeline — that way "before" and "after" differ only
# by the stylesheet, and switching revisions costs a recompile instead of a
# rebuild.
require "json"
require "digest"
require "fileutils"
require "optparse"
require "net/http"
require "sassc"
require "ferrum"

require_relative "scenarios"

options = {
  theme_root: "app/assets/stylesheets",
  out: "tmp/screens",
  app: File.expand_path("tmp/screens-dummy", Dir.pwd),
  port: 3777,
  viewport: [1440, 900],
}
OptionParser.new do |opts|
  opts.on("--theme-root DIR") { |v| options[:theme_root] = v }
  opts.on("--out DIR")        { |v| options[:out] = v }
  opts.on("--app DIR")        { |v| options[:app] = v }
  opts.on("--port N", Integer) { |v| options[:port] = v }
end.parse!

BASE = "http://127.0.0.1:#{options[:port]}"
FileUtils.mkdir_p(options[:out])

# --- CSS ---------------------------------------------------------------------

ACTIVE_ADMIN = File.join(Gem::Specification.find_by_name("activeadmin").gem_dir,
                         "app/assets/stylesheets")

# Exactly what a host project's active_admin.scss does: overrides first, then
# ActiveAdmin, then the theme on top.
def compile(theme_root, overrides)
  source = <<~SCSS
    @import "active_admin/mixins";
    #{overrides}
    @import "active_admin/base";
    @import "wigu/active_admin_theme";
  SCSS
  SassC::Engine.new(source, load_paths: [ACTIVE_ADMIN, theme_root], style: :compressed).render
end

css_cache = Hash.new do |cache, overrides|
  cache[overrides] = compile(options[:theme_root], overrides)
end

# --- App ---------------------------------------------------------------------

def wait_for(url, seconds: 90)
  deadline = Time.now + seconds
  loop do
    begin
      return true if Net::HTTP.get_response(URI(url)).code
    rescue StandardError
      raise "app did not come up at #{url}" if Time.now > deadline
      sleep 1
    end
  end
end

env = %w[BUNDLE_GEMFILE BUNDLE_PATH RUBYOPT RUBYLIB].to_h { |k| [k, nil] }
server = spawn(env.merge("RAILS_ENV" => "development"),
               "bin/rails", "server", "-p", options[:port].to_s, "-b", "127.0.0.1",
               chdir: options[:app], out: File::NULL, err: File::NULL)
at_exit { Process.kill("TERM", server) rescue nil }
wait_for("#{BASE}/admin")

# --- Browser -----------------------------------------------------------------

browser = Ferrum::Browser.new(headless: true, window_size: options[:viewport],
                              browser_options: { "force-color-profile" => "srgb",
                                                 "hide-scrollbars" => nil })
at_exit { browser.quit rescue nil }

# Animations and transitions would make the same scenario render differently
# depending on how fast the machine is.
STEADY = <<~CSS
  *, *::before, *::after { transition: none !important; animation: none !important; }
CSS

def box(page, selector)
  page.evaluate(<<~JS)
    (() => {
      const el = document.querySelector(#{selector.to_json});
      if (!el) return null;
      const b = el.getBoundingClientRect();
      return { x: b.left, y: b.top, width: b.width, height: b.height };
    })()
  JS
end

def run_step(page, (action, argument))
  case action
  when :hover
    b = box(page, argument) or raise "hover: #{argument} not found"
    page.mouse.move(x: b["x"] + b["width"] / 2, y: b["y"] + b["height"] / 2)
    sleep 0.15
  when :click
    b = box(page, argument) or raise "click: #{argument} not found"
    page.mouse.move(x: b["x"] + b["width"] / 2, y: b["y"] + b["height"] / 2).down.up
    sleep 0.25
  when :focus
    page.execute("document.querySelector(#{argument.to_json}).focus()")
    sleep 0.15
  when :eval  then page.execute(argument)
  when :wait  then sleep(argument)
  else raise "unknown step #{action.inspect}"
  end
end

taken = []

SCENARIOS.each do |scenario|
  name = scenario[:name]
  width, height = scenario[:viewport] || options[:viewport]
  page = browser.create_page
  page.resize(width: width, height: height)

  page.go_to("#{BASE}#{scenario[:path]}")

  # Replace ActiveAdmin's own stylesheet with the compiled theme, so the page
  # shows this revision of the theme over this version of ActiveAdmin.
  # `execute`, not `evaluate`: the latter takes a single expression and would
  # drop this silently, leaving an unstyled page.
  page.execute(<<~JS)
    document.querySelectorAll('link[rel="stylesheet"], style[data-theme-css]').forEach(n => n.remove());
    const s = document.createElement('style');
    s.setAttribute('data-theme-css', '1');
    s.textContent = #{(css_cache[scenario[:overrides].to_s] + STEADY).to_json};
    document.head.appendChild(s);
    document.documentElement.setAttribute('data-theme', #{(scenario[:theme] || "light").to_json});
  JS
  sleep 0.2

  Array(scenario[:steps]).each { |step| run_step(page, step) }

  area = nil
  if scenario[:crop]
    # A list unions the boxes: an open dropdown is positioned absolutely, so
    # #header alone would crop it off even though it is the thing to look at.
    boxes = Array(scenario[:crop]).map do |selector|
      box(page, selector) or raise "#{name}: crop #{selector} not found"
    end
    pad = scenario.fetch(:pad, 12)
    left   = boxes.map { |b| b["x"] }.min - pad
    top    = boxes.map { |b| b["y"] }.min - pad
    right  = boxes.map { |b| b["x"] + b["width"] }.max + pad
    bottom = boxes.map { |b| b["y"] + b["height"] }.max + pad
    x = [left, 0].max
    y = [top, 0].max
    area = { x: x, y: y,
             width:  [right  - x, width  - x].min,
             height: [bottom - y, height - y].min }
  end

  path = File.join(options[:out], "#{name}.png")
  page.screenshot(path: path, **(area ? { area: area } : {}))
  page.close

  # Both revisions are shot on the same machine in the same run, so an identical
  # digest means the PR genuinely does not touch this scenario and it can be
  # folded away in the comment instead of adding noise.
  taken << { name: name, why: scenario[:why], file: File.basename(path),
             digest: Digest::SHA256.file(path).hexdigest }
  puts "shot #{name}"
rescue StandardError => e
  warn "shot #{name}: FAILED — #{e.message}"
  taken << { name: name, why: scenario[:why], error: e.message }
end

File.write(File.join(options[:out], "index.json"), JSON.pretty_generate(taken))
failed = taken.count { |t| t[:error] }
puts "shoot: #{taken.size - failed}/#{taken.size} scenarios"
exit(1) if failed.positive?
