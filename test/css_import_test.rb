# The generated @import for hosts that take the theme CSS from the installed gem.
require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../lib/active_admin_theme/css_import"

class CssImportTest < Minitest::Test
  CssImport = ActiveAdminTheme::CssImport

  def with_entry(content)
    Dir.mktmpdir do |dir|
      entry = File.join(dir, "app/assets/stylesheets/active_admin.css")
      FileUtils.mkdir_p(File.dirname(entry))
      File.write(entry, content)
      yield entry
    end
  end

  def test_the_generated_file_resolves_to_the_gem_css
    with_entry("@import \"tailwindcss\";\n") do |entry|
      CssImport.write(entry)
      generated = CssImport.generated_path(entry)
      relative = generated.read[/@import "([^"]*active_admin_theme\.css)"/, 1]
      assert relative, "expected an active_admin_theme.css import"
      assert_equal CssImport.gem_css_path.to_s, File.expand_path(relative, File.dirname(entry))
    end
  end

  def test_the_entry_file_holds_only_a_machine_independent_line
    with_entry("@import \"tailwindcss\";\n") do |entry|
      CssImport.write(entry)
      text = File.read(entry)
      assert_includes text, "@import \"./active_admin_theme.generated.css\";"
      refute_includes text, CssImport.gem_css_path.to_s
      refute_match(%r{\.\./}, text)
      assert text.end_with?("\n")
    end
  end

  def test_rerun_changes_nothing_and_a_moved_gem_rewrites_only_the_generated_file
    with_entry("@import \"tailwindcss\";\n") do |entry|
      CssImport.write(entry)
      before = File.read(entry)
      assert_empty CssImport.write(entry)

      moved = Pathname.new("/somewhere/else/active_admin_theme.css")
      assert_equal [[:generated, :updated]], CssImport.write(entry, css: moved)
      assert_equal before, File.read(entry)
      assert_equal 1, before.scan("active_admin_theme:begin").size
    end
  end

  def test_missing_entry_file_is_an_error
    assert_raises(ArgumentError) { CssImport.write("/nonexistent/active_admin.css") }
  end
end
