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
  }.freeze

  # Wrong-typed overrides. All of these are legal SassScript, so without the
  # guards in the theme they compile silently and emit declarations the browser
  # drops — the rule simply vanishes and ActiveAdmin's own value reappears, with
  # nothing in the build output to say why.
  BAD = {
    "$skinBorderRadius without a unit"  => '$skinBorderRadius: 4;',
    "$skinTablePadding: none"           => '$skinTablePadding: none;',
    "$skinBorderWindowColor: none"      => '$skinBorderWindowColor: none;',
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

    if failures.empty?
      puts "css_check: #{GOOD.size} overrides compile clean, #{BAD.size} bad ones rejected"
    else
      failures.each { |failure| warn "css_check: #{failure}" }
      abort "css_check: #{failures.size} problem(s)"
    end
  end
end

CssCheck.run if $PROGRAM_NAME == __FILE__
