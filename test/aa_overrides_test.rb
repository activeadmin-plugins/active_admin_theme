# The theme replaces some of ActiveAdmin's own view files with its copies, so
# ActiveAdmin's later fixes to those files never reach a host. This test records
# a digest of each original as it was when the theme's copy was last reviewed,
# and fails when the installed ActiveAdmin's original differs.
#
# The record holds the originals of both modes: app/views_compat is in use only
# with an ActiveAdmin that lacks the layout hooks, and the hook partials exist
# only in one that has them. Run the test once per mode.
#
# After raising the ActiveAdmin floor, diff each reported file against the
# theme's copy, port what applies, then refresh the record:
#   UPDATE_AA_DIGESTS=1 bundle exec ruby test/aa_overrides_test.rb
require "bundler/setup"
require "minitest/autorun"
require "digest"
require "yaml"

class AaOverridesTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  RECORD = File.expand_path("fixtures/active_admin_originals.yml", __dir__)

  def aa_views
    File.join(Gem.loaded_specs.fetch("activeadmin").full_gem_path, "app/views")
  end

  # Mirrors ActiveAdminTheme.layout_hooks?, which needs the full gem loaded.
  def theme_view_dirs
    hooks = File.file?(File.join(aa_views, "active_admin/_page_heading.html.erb"))
    hooks ? ["app/views"] : ["app/views", "app/views_compat"]
  end

  def overridden
    theme_view_dirs.flat_map do |dir|
      Dir.chdir(File.join(ROOT, dir)) { Dir["**/*"].select { |path| File.file?(path) } }
    end.select { |path| File.file?(File.join(aa_views, path)) }.uniq.sort
  end

  def digests
    overridden.to_h { |path| [path, Digest::SHA256.file(File.join(aa_views, path)).hexdigest] }
  end

  def test_activeadmin_originals_match_the_reviewed_versions
    if ENV["UPDATE_AA_DIGESTS"]
      record = File.exist?(RECORD) ? YAML.load_file(RECORD) : {"files" => {}}
      File.write(RECORD, {"files" => record["files"].merge(digests).sort.to_h}.to_yaml)
    end

    recorded = YAML.load_file(RECORD)
    changed = digests.reject { |path, digest| recorded["files"][path] == digest }.keys
    new_overrides = overridden - recorded["files"].keys

    assert_empty changed, "ActiveAdmin changed files the theme replaces: #{changed.join(', ')}. Diff them against the theme's copies, port what applies, then run with UPDATE_AA_DIGESTS=1."
    assert_empty new_overrides, "New theme views replace ActiveAdmin files: #{new_overrides.join(', ')}. Record them with UPDATE_AA_DIGESTS=1."
  end
end
