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
    # Every colour here must clear LABEL_MINIMUM against the label, because the
    # contrast guard measures the shipped palette: an example that fails the
    # contract documents the wrong thing.
    "status tags recoloured" => '$skinStatusTagOkColor: #1f7a3a;
                                 $skinStatusTagNeutralColor: #55595f;
                                 $skinStatusTagNoticeColor: #2f62b4;
                                 $skinStatusTagWarnColor: #875c12;
                                 $skinStatusTagErrorColor: #b03a2e;',
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
    "$skinStatusTagOkColor: none"         => '$skinStatusTagOkColor: none;',
    "$skinStatusTagNeutralColor: none"    => '$skinStatusTagNeutralColor: none;',
    "$skinStatusTagNoticeColor: none"     => '$skinStatusTagNoticeColor: none;',
    "$skinStatusTagWarnColor: none"       => '$skinStatusTagWarnColor: none;',
    "$skinStatusTagErrorColor: none"      => '$skinStatusTagErrorColor: none;',
    "$skinStatusTagTextColor as a length" => '$skinStatusTagTextColor: 10px;',
  }.freeze

  # The variables table in the README is the public contract people configure
  # against, and it had drifted from the declarations in 30 of 52 rows after the
  # defaults moved to yeti-web's configuration. Nothing noticed, because nothing
  # was comparing them.
  def self.readme_table_matches_declarations
    scss = strip_comments(File.read(File.join(STYLESHEETS, "wigu/active_admin_theme.scss")))
    declared = {}
    duplicates = []
    scss.scan(/(\$skin[A-Za-z0-9]+)\s*:\s*(.+?)!default/) do |name, value|
      # Sass keeps the first !default and ignores the rest, so a second
      # declaration is dead code that drifts from the live one in silence.
      duplicates << name if declared.key?(name)
      # `if($x == null, 4.5px, $x)` documents as the fallback it falls back to.
      declared[name] ||= value.strip.sub(/\Aif\(\$\w+ == null, (.+?), \$\w+\)\z/, '\\1')
    end

    readme = File.read(File.expand_path("../README.md", __dir__))
    rows = readme.scan(/^\|\s*`(\$skin[A-Za-z0-9]+)`(?:\s*\/\s*`(\$skin[A-Za-z0-9]+)`)?\s*\|\s*([^|]*?)\s*\|/)

    documented = {}
    listed_twice = []
    blank = []
    rows.each do |light, dark, values|
      # Drop any inline swatch images (`![#hex](…/get/hex/16x16)`) the README
      # adds next to each value, then read the backticked hex(es). Without this
      # the image URL's slashes break the light/dark split below.
      cleaned = values.gsub(/!\[[^\]]*\]\([^)]*\)/, "")
      parts = cleaned.split("/").map { |part| part.strip.delete("`") }.reject(&:empty?)
      [[light, parts[0]], [dark, parts[1]]].each do |name, value|
        next if name.nil?
        # Every row counts towards duplicate detection, blank or not. Skipping
        # blanks here instead would let a name carry one blank row and one good
        # row: the good row satisfies `documented`, the blank one never reaches
        # `listed_twice`, and the contradiction passes.
        listed_twice << name if documented.key?(name) || blank.include?(name)
        # A cell with no value documents nothing, so it does not go into
        # `documented` — otherwise the name would be exempt from the
        # undocumented check below while the mismatch check skipped it for
        # having no value, and it would pass on both sides.
        if value.nil? || value.empty?
          blank << name
        else
          documented[name] = value
        end
      end
    end
    @compared_declarations = declared.size

    mismatched = documented.filter_map do |name, value|
      actual = declared[name]
      next if actual && actual.casecmp?(value)
      "#{name}: README says `#{value}`, the stylesheet declares `#{actual || "nothing"}`"
    end

    # Both directions: comparing only the documented names would let a new
    # variable ship undocumented while the success line still claimed the table
    # matched every declaration. Absent is measured against every row, blank
    # ones included — a name with a blank row is listed, just not documented,
    # and telling its author it is absent sends them looking for a row that is
    # already there.
    undocumented = (declared.keys - documented.keys - blank).map do |name|
      "#{name}: declared in the stylesheet, absent from the README table"
    end
    duplicated = duplicates.uniq.map do |name|
      "#{name}: declared more than once; Sass keeps the first !default and drops the rest"
    end
    # The last row wins when a name is listed twice, so the table can agree with
    # the stylesheet while a reader meets the stale row first.
    redocumented = listed_twice.uniq.map do |name|
      "#{name}: listed more than once in the README table"
    end
    undefaulted = blank.uniq.map do |name|
      "#{name}: listed in the README table with no default"
    end

    mismatched + undocumented + duplicated + redocumented + undefaulted
  end


  # Reported in the success line. Counted from the declarations themselves, so
  # it cannot drift the way a hand-maintained constant does.
  def self.compared_declarations
    @compared_declarations || 0
  end

  # The status tag label is the one thing in this stylesheet that has been got
  # wrong twice: once by shipping white on a mid-tone fill, once by darkening
  # the fill and leaving the label. Nothing was checking it, so nothing caught
  # either. 4.5:1 is what WCAG AA asks of text this size.
  LABEL_MINIMUM = 4.5

  def self.relative_luminance(rgb)
    linear = rgb.map do |channel|
      value = channel / 255.0
      value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
    end
    0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
  end

  def self.contrast(one, two)
    lighter, darker = [relative_luminance(one), relative_luminance(two)].minmax.reverse
    (lighter + 0.05) / (darker + 0.05)
  end

  # Sass resolves the colour, not a regular expression over its output. Hex,
  # rgb(), hsl() and named colours are all legal here and the type guard accepts
  # every one; sassc normalises most of them to hex but emits names as names, so
  # a regex over the stylesheet silently skipped `darkseagreen` and crashed on a
  # four-digit hex. Asking Sass for the channels removes the question.
  # Read from the stylesheet, not typed out here. A hand-kept list is the same
  # drift this file removed when DECLARED_ROWS went: add a sixth tag colour and
  # it would be silently exempt from the contrast check for ever.
  # Sass ignores a commented-out declaration; this file used to count one, and
  # with the duplicate and mismatch checks in place that turned a note like
  # `// was: $skinStatusTagOkColor: #8daa92!default;` into a red build blaming
  # the live declaration.
  def self.strip_comments(scss)
    scss.gsub(%r{/\*.*?\*/}m, "").gsub(%r{//[^\n]*}, "")
  end

  def self.tag_colours
    @tag_colours ||= begin
      scss = strip_comments(File.read(File.join(STYLESHEETS, "wigu/active_admin_theme.scss")))
      names = scss.scan(/\$skinStatusTag([A-Za-z0-9]+)Color\s*:[^;]*!default/).flatten
      names.reject! { |name| name == "Text" }
      raise "css_check: no $skinStatusTag*Color declarations found" if names.empty?
      names.uniq.to_h { |name| [name.downcase, "$skinStatusTag#{name}Color"] }
    end
  end

  def self.status_tag_palette
    probe = tag_colours.merge("label" => "$skinStatusTagTextColor").map do |name, variable|
      ".css-check-#{name} { r: red(#{variable}); g: green(#{variable}); " \
        "b: blue(#{variable}); a: alpha(#{variable}); }"
    end
    css = compile("", probe.join("\n"))
    # Fractional channels, because red() on an hsl() colour does not return a
    # whole number and an integer-only pattern silently matched nothing.
    channels = css.scan(%r{\.css-check-(\w+)\s*\{\s*r:\s*([\d.]+);\s*g:\s*([\d.]+);\s*
                           b:\s*([\d.]+);\s*a:\s*([\d.]+);?\s*\}}x)
    found = channels.to_h do |name, r, g, b, a|
      [name, { rgb: [r, g, b].map { |v| v.to_f.round }, alpha: a.to_f }]
    end
    missing = (tag_colours.keys + ["label"]) - found.keys
    raise "css_check: the status tag probe returned nothing for #{missing.join(", ")}" unless missing.empty?
    found
  end

  # Alpha is read, not dropped. A translucent colour has no measurable ratio —
  # it would be against whatever shows through, which this stylesheet does not
  # know — and dropping it would score `transparent` as black, so a transparent
  # fill under a white label would pass at 21:1. The shipped palette has no
  # reason to be translucent, so say so rather than skip it: a check that goes
  # quiet is the failure this guard exists to avoid.
  def self.status_tag_labels_are_readable
    palette = status_tag_palette
    label = palette.fetch("label")
    problems = []

    # The label is not a tag, and reporting it as one sent a reader looking for
    # a `label` status class that does not exist.
    problems << "$skinStatusTagTextColor is translucent, so no tag ratio can be measured" if label[:alpha] < 1

    tag_colours.each_key do |name|
      fill = palette.fetch(name)
      # Reported, not skipped, and without abandoning the other four: a single
      # translucent fill used to return early and hide every failure behind it.
      if fill[:alpha] < 1 || label[:alpha] < 1
        problems << "status tag #{name}: translucent, so the label ratio cannot be measured"
        next
      end
      ratio = contrast(fill[:rgb], label[:rgb])
      next if ratio >= LABEL_MINIMUM
      problems << "status tag #{name}: label #{hex(label[:rgb])} on #{hex(fill[:rgb])} is " \
                  "#{format("%.3f", ratio)}:1, under #{LABEL_MINIMUM}"
    end
    problems
  end

  def self.hex(rgb)
    format("#%02x%02x%02x", *rgb)
  end

  def self.load_paths
    activeadmin = Gem::Specification.find_by_name("activeadmin").gem_dir
    [File.join(activeadmin, "app/assets/stylesheets"), STYLESHEETS]
  end

  def self.compile(overrides, appended = nil)
    source = <<~SCSS
      @import "active_admin/mixins";
      #{overrides}
      @import "active_admin/base";
      @import "#{THEME}";
      #{appended}
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
    rescue SassC::SyntaxError => e
      # Rejected is not enough: the point of the guards is that the message
      # names the variable the host set. Without this, a fixture passes when
      # the wrong value merely crashes something downstream — `none` reaching
      # mix() inside the theme reads as a rejection while naming gem internals,
      # and the guard it was written to prove can be deleted unnoticed.
      variable = name[/\$skin[A-Za-z0-9]+/]
      next if variable.nil? || e.message.include?(variable)
      failures << "#{name}: rejected, but the message does not name #{variable} — " \
                  "#{e.message.lines.first.to_s.strip}"
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
    # The body, not the start of a line: sassc happens to put the first
    # declaration on its own line, so matching from `^` only works while
    # `display` is written first in the stylesheet. Reorder the two lines in the
    # source and the guard goes blind.
    blocky = utility.select do |rule|
      rule[/\{(.*)\}/m, 1].to_s.split(";").any? { |d| d.strip =~ /\Adisplay:\s*(?:flex|block|grid)\z/ }
    end
    unless blocky.empty?
      failures << "utility nav: #{blocky.size} item rule(s) make the li block-level and break the inline row: " \
                  "#{blocky.map { |rule| rule[/\A[^{]*/].strip }.join(", ")}"
    end

    # One list, reported together. Behind `if failures.empty?` these two were
    # invisible whenever anything else failed, and the first of them aborted
    # before the second ran — so a run could report one problem while holding
    # three, and each fix revealed the next.
    failures.concat(status_tag_labels_are_readable)
    failures.concat(readme_table_matches_declarations)

    unless failures.empty?
      failures.each { |failure| warn "css_check: #{failure}" }
      abort "css_check: #{failures.size} problem(s)"
    end

    puts "css_check: #{GOOD.size} overrides compile clean, #{BAD.size} bad ones rejected, " \
         "README table matches #{compared_declarations} declarations"
  end
end

CssCheck.run if $PROGRAM_NAME == __FILE__
