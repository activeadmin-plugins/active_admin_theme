# Compiles the theme against ActiveAdmin's own stylesheets and checks the
# result. Run with `rake css`.
#
# The gem ships SCSS, not CSS, so nothing in this repo's build ever compiles
# the theme: a change that only breaks under a particular variable override
# reaches consumers unnoticed. This is the only thing here that does compile it.
require "sassc"

module CssCheck
  STYLESHEETS = File.expand_path("../app/assets/stylesheets", __dir__)
  THEME = "wigu/active_admin_theme"

  # Overrides a host project would plausibly write. Each must compile and keep
  # producing CSS the browser accepts.
  GOOD = {
    "defaults"      => "",
    "accent"        => '$skinMainSecondColor: #0066cc;',
    "dark chrome"   => '$skinMainFirstColor: #111418; $skinBorderWindowColor: #b8babe;',
    "square + wide" => '$skinBorderRadius: 0; $skinTablePadding: 14px;',
    "rem radius"    => '$skinBorderRadius: 0.25rem;',
    "light menu"    => '$skinMenuPanelColor: #ffffff; $skinMenuTextColor: #333333;
                        $skinMenuPillColor: #f0f0f0; $skinMenuPillTextColor: #222222;',
    "dark menu"     => '$skinMenuPanelColor: #222222; $skinMenuItemHoverColor: #3a3a3a;',
    "roomy menu"    => '$skinMenuFontSize: 1.6em; $skinMenuItemPaddingY: 12px;',
    "header padding shorthand" => '$skinHeaderPaddingY: 7px;',
    # The panel header pair is documented as taking a custom property, so the
    # colour guard has to let one through.
    "panel header as a custom property" => '$skinPanelHeaderColor: var(--aa-surface);',
    "repainted palette" => '$skinPageBgColor: #fafafa; $skinSurfaceColor: #ffffff;
                            $skinTextColor: #202020; $skinLinkColor: #0b5;',
  }.freeze

  # Wrong-typed overrides. All of these are legal SassScript, so without the
  # guards in the theme they compile silently and emit declarations the browser
  # drops — the rule simply vanishes and ActiveAdmin's own value reappears, with
  # nothing in the build output to say why.
  BAD = {
    "$skinBorderRadius without a unit"    => '$skinBorderRadius: 4;',
    "$skinTablePadding: none"             => '$skinTablePadding: none;',
    "$skinBorderWindowColor: none"        => '$skinBorderWindowColor: none;',
    "$skinMenuItemPaddingY without a unit" => '$skinMenuItemPaddingY: 8;',
    "$skinMenuItemHoverColor: none"       => '$skinMenuItemHoverColor: none;',
    "$skinTitleBarBorderWidth: none"      => '$skinTitleBarBorderWidth: none;',
    "$skinPageBgColor as a length"        => '$skinPageBgColor: 10px;',
    "$skinTextColor: none"                => '$skinTextColor: none;',
    "$skinLinkColorDark: none"            => '$skinLinkColorDark: none;',
    "$skinPanelHeaderColor as a length"   => '$skinPanelHeaderColor: 10px;',
  }.freeze

  def self.load_paths
    activeadmin = Gem::Specification.find_by_name("activeadmin").gem_dir
    [File.join(activeadmin, "app/assets/stylesheets"), STYLESHEETS]
  end

  def self.compile(overrides)
    source = <<~SCSS
      @import "active_admin/mixins";
      #{overrides}
      @import "active_admin/base";
      @import "#{THEME}";
    SCSS
    SassC::Engine.new(source, load_paths: load_paths, style: :expanded).render
  end

  def self.run
    failures = []

    GOOD.each do |name, overrides|
      compile(overrides)
    rescue SassC::SyntaxError => e
      failures << "#{name}: should compile, but does not — #{e.message.lines.first.strip}"
    end

    BAD.each do |name, overrides|
      compile(overrides)
      failures << "#{name}: should be rejected with @error, but compiled silently"
    rescue SassC::SyntaxError
      # expected — the theme's type guards caught it
    end

    # The header menu's text colours must follow the variables. A hard-coded
    # white that out-specifies $skinMenuTextColor is invisible on a light panel,
    # which is the whole point of being able to set the panel colour.
    menu = compile(GOOD["light menu"]).scan(/^[^{}]*#wrapper #header ul\.tabs[^{}]*\{[^}]*\}/m).join("\n")
    whites = menu.scan(/^\s*color:\s*(?:#f{3,6}|white)\s*;/i)
    unless whites.empty?
      failures << "light menu: #{whites.size} hard-coded white colour(s) left in the header menu; " \
                  "they out-specify $skinMenuTextColor and render invisible on a light panel"
    end

    if failures.empty?
      puts "css_check: #{GOOD.size} overrides compile clean, #{BAD.size} bad ones rejected"
    else
      failures.each { |failure| warn "css_check: #{failure}" }
      abort "css_check: #{failures.size} problem(s)"
    end
  end
end

CssCheck.run if $PROGRAM_NAME == __FILE__
