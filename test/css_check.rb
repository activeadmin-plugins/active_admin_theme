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
    "black status tag labels" => '$skinStatusTagTextColor: #000000;',
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
    "$skinStatusTagTextColor: none"       => '$skinStatusTagTextColor: none;',
  }.freeze

  # The variables table in the README is the public contract people configure
  # against, and it had drifted from the declarations in 30 of 52 rows after the
  # defaults moved to yeti-web's configuration. Nothing noticed, because nothing
  # was comparing them.
  def self.readme_table_matches_declarations
    scss = File.read(File.join(STYLESHEETS, "wigu/active_admin_theme.scss"))
    declared = {}
    scss.scan(/(\$skin[A-Za-z0-9]+)\s*:\s*(.+?)!default/) do |name, value|
      # `if($x == null, 4.5px, $x)` documents as the fallback it falls back to.
      declared[name] ||= value.strip.sub(/\Aif\(\$\w+ == null, (.+?), \$\w+\)\z/, '\\1')
    end

    readme = File.read(File.expand_path("../README.md", __dir__))
    rows = readme.scan(/^\|\s*`(\$skin[A-Za-z0-9]+)`(?:\s*\/\s*`(\$skin[A-Za-z0-9]+)`)?\s*\|\s*([^|]*?)\s*\|/)

    rows.flat_map do |light, dark, documented|
      parts = documented.split("/").map { |part| part.strip.delete("`") }
      pairs = [[light, parts[0]]]
      pairs << [dark, parts[1]] if dark
      pairs.filter_map do |name, value|
        next if value.nil? || value.empty?
        actual = declared[name]
        next if actual && actual.casecmp?(value)
        "#{name}: README says `#{value}`, the stylesheet declares `#{actual || "nothing"}`"
      end
    end
  end

  DECLARED_ROWS = 53

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

    # ActiveAdmin keeps the utility nav on one line with `li { display: inline }`.
    # A block-level item (flex, block, grid) breaks that row and stacks the
    # username, theme switch and logout on top of each other.
    utility = compile(GOOD["defaults"]).scan(/^[^{}]*#utility_nav\s*>\s*li[^{}\s,]*\s*\{[^}]*\}/m)
    blocky = utility.select { |rule| rule =~ /^\s*display:\s*(?:flex|block|grid)\s*;/ }
    unless blocky.empty?
      failures << "utility nav: #{blocky.size} item rule(s) make the li block-level and break the inline row: " \
                  "#{blocky.map { |rule| rule[/\A[^{]*/].strip }.join(", ")}"
    end

    if failures.empty?
      drift = readme_table_matches_declarations
      unless drift.empty?
        drift.each { |line| warn "css_check: #{line}" }
        abort "css_check: the README variables table is out of sync in #{drift.size} place(s)"
      end

      puts "css_check: #{GOOD.size} overrides compile clean, #{BAD.size} bad ones rejected, " \
           "README table matches #{DECLARED_ROWS} declarations"
    else
      failures.each { |failure| warn "css_check: #{failure}" }
      abort "css_check: #{failures.size} problem(s)"
    end
  end
end

CssCheck.run if $PROGRAM_NAME == __FILE__
