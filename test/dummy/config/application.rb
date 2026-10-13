# Minimal ActiveAdmin host app. Its only jobs are to render an AA page with the
# theme active so the Capybara test can prove the server clock renders + ticks,
# and to be the source for the neutral README screenshot. Deliberately no DB
# schema: AA comments are off and there are no resources, so nothing queries.
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "sprockets/railtie"

require "active_admin"
# The gem under test. Requiring it registers ActiveAdminTheme::Rails::Engine,
# whose initializer calls install! — that injects li#servertime (with the
# data-servertime instant) and the logout item into every namespace.
require "active_admin_theme"

module Dummy
  class Application < Rails::Application
    # Booted by requiring this file directly (not from test/dummy as cwd), so
    # pin the root or Rails looks for config/database.yml in the repo root.
    config.root = File.expand_path("..", __dir__)
    config.load_defaults 7.1
    config.eager_load = false
    config.consider_all_requests_local = true
    config.secret_key_base = "dummy-secret-key-base-for-tests-only"
    config.hosts.clear

    config.logger = Logger.new($stdout)
    config.log_level = :warn

    # action_text-trix ships trix.js / trix.css but doesn't add them to the
    # Sprockets load path on its own, so `//= require trix` / `@import "trix"`
    # (in active_admin.js / active_admin.scss) can't find them. Add its asset
    # dirs so the demo editor page gets Trix's base JS + CSS.
    trix_root = Gem::Specification.find_by_name("action_text-trix").gem_dir
    config.assets.paths << File.join(trix_root, "app/assets/javascripts")
    config.assets.paths << File.join(trix_root, "app/assets/stylesheets")

    # Sprockets: compile on the fly, no digests — simplest thing that serves
    # active_admin.css / active_admin.js in dev/test.
    config.assets.compile = true
    config.assets.debug = false
    config.public_file_server.enabled = true
  end
end
