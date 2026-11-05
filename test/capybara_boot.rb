# Shared Capybara + cuprite setup for the browser tests and the screenshot
# task. Boots the dummy ActiveAdmin app (test/dummy) and points Capybara at it,
# driven by headless system Chrome via cuprite/ferrum.
ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment"
require "capybara"
require "capybara/cuprite"

Capybara.app = Dummy::Application
Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 5

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1280, 800],
    headless: true,
    js_errors: true,
    # CI runners need --no-sandbox; their small /dev/shm makes Chrome crash on
    # launch unless --disable-dev-shm-usage is set. --disable-gpu is the usual
    # headless companion. All harmless locally.
    browser_options: {
      "no-sandbox" => nil,
      "disable-dev-shm-usage" => nil,
      "disable-gpu" => nil
    },
    process_timeout: 30
  )
end

Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite
