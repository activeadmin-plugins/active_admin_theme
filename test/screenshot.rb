# Regenerates img/clock.png — the neutral README/PR screenshot of the two-line
# server clock sitting in the utility nav. Same dummy app and driver the test
# uses; crops to the AA header so the shot is just the top bar (site title
# "ActiveAdmin Theme Demo", dashboard menu, clock, logout) — no real content.
require_relative "capybara_boot"
require "capybara/dsl"

include Capybara::DSL

OUT = File.expand_path("../img/clock.png", __dir__)

visit "/admin"
# Let the clock tick once so the two lines are populated by the JS.
find("#utility_nav li#servertime .clock-time", wait: 5)
sleep 1.1

page.driver.save_screenshot(OUT, selector: "#header")
Capybara.reset_sessions!

puts "wrote #{OUT} (#{File.size(OUT)} bytes)"
