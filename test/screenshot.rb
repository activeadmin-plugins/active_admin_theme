# Screenshots of demo pages at the theme's target widths, light and dark.
#   bundle exec ruby test/screenshot.rb                       # all defaults
#   PAGES=/admin/customers WIDTHS=1280 MODES=dark OUT=tmp/shots bundle exec ruby test/screenshot.rb
require_relative "capybara_boot"
require "fileutils"

# A Session, not Capybara::DSL: top-level DSL methods land on Object, and
# `page` then collides with Kaminari's scope.
browser = Capybara::Session.new(:cuprite, Dummy::Application)

pages = (ENV["PAGES"] || "/admin/customers,/admin/customers/1,/admin/customers/1/edit").split(",")
widths = (ENV["WIDTHS"] || "1280,820,390").split(",").map(&:to_i)
modes = (ENV["MODES"] || "light,dark").split(",")
out = File.expand_path(ENV["OUT"] || "../tmp/screenshots", __dir__)
FileUtils.mkdir_p(out)

pages.each do |path|
  widths.each do |width|
    modes.each do |mode|
      browser.current_window.resize_to(width, 900)
      browser.visit path
      browser.execute_script("document.documentElement.classList.#{mode == 'dark' ? 'add' : 'remove'}('dark')")
      file = File.join(out, "#{path.delete_prefix('/').tr('/', '_')}-#{width}-#{mode}.png")
      browser.driver.save_screenshot(file, full: true)
      puts file
    end
  end
end
browser.quit
