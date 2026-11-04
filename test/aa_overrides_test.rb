# The theme replaces some of ActiveAdmin's own view files with its copies, so
# ActiveAdmin's later fixes to those files never reach a host. This test records
# a digest of each original as it was when the theme's copy was last reviewed,
# and fails when the installed ActiveAdmin's original differs.
#
# After raising the ActiveAdmin floor, diff each reported file against the
# theme's copy, port what applies, then refresh the record:
#   UPDATE_AA_DIGESTS=1 bundle exec ruby test/aa_overrides_test.rb
require "bundler/setup"
require "minitest/autorun"
require "digest"
require "yaml"

class AaOverridesTest < Minitest::Test
  THEME_VIEWS = File.expand_path("../app/views", __dir__)
  RECORD = File.expand_path("fixtures/active_admin_originals.yml", __dir__)

  def aa_views
    File.join(Gem.loaded_specs.fetch("activeadmin").full_gem_path, "app/views")
  end

  def overridden
    Dir.chdir(THEME_VIEWS) { Dir["**/*"].select { |path| File.file?(path) } }.select do |path|
      File.file?(File.join(aa_views, path))
    end.sort
  end

  def digests
    overridden.to_h { |path| [path, Digest::SHA256.file(File.join(aa_views, path)).hexdigest] }
  end

  def test_activeadmin_originals_match_the_reviewed_versions
    if ENV["UPDATE_AA_DIGESTS"]
      File.write(RECORD, {"activeadmin" => Gem.loaded_specs.fetch("activeadmin").version.to_s, "files" => digests}.to_yaml)
    end

    recorded = YAML.load_file(RECORD)
    changed = digests.reject { |path, digest| recorded["files"][path] == digest }.keys
    new_overrides = overridden - recorded["files"].keys

    assert_empty changed, "ActiveAdmin changed files the theme replaces: #{changed.join(', ')}. Diff them against app/views, port what applies, then run with UPDATE_AA_DIGESTS=1."
    assert_empty new_overrides, "New theme views replace ActiveAdmin files: #{new_overrides.join(', ')}. Record them with UPDATE_AA_DIGESTS=1."
  end
end
