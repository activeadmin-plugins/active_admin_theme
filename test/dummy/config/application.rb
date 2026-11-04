# Minimal ActiveAdmin 4 host app (importmap + propshaft, Tailwind CSS built by
# the npm CLI). It renders AA pages with the theme active for the Capybara
# tests and the screenshot scripts. No DB schema: AA comments are off.
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "propshaft"
require "importmap-rails"

# The gem under test. It requires active_admin first, then registers its engine.
require "active_admin_theme"

module Dummy
  class Application < Rails::Application
    # Booted by requiring this file directly (not from test/dummy as cwd), so
    # pin the root or Rails looks for config/database.yml in the repo root.
    config.root = File.expand_path("..", __dir__)
    config.load_defaults 8.0
    config.eager_load = false
    config.consider_all_requests_local = true
    config.secret_key_base = "dummy-secret-key-base-for-tests-only"
    config.hosts.clear

    config.logger = Logger.new($stdout)
    config.log_level = :warn

    config.public_file_server.enabled = true
  end
end
