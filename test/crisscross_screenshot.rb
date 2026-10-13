# Regenerates img/crisscross-light.png / img/crisscross-dark.png — the crisscross
# cell highlighting (wigu/table_crisscross.js) in both palettes. Clicks a middle
# cell so the screenshot shows the highlighted row + column crossing at it, then
# crops to the demo panel.
require_relative "capybara_boot"
require "capybara/dsl"

include Capybara::DSL

visit "/admin/table"
# Click a cell away from the edges so the cross is clearly centred (row 3, Email).
find("table.index_table tbody tr:nth-child(3) td:nth-child(3)").click
page.driver.resize_window_to(page.driver.window_handles.first, 1120, 640)

{ "light" => "crisscross-light.png", "dark" => "crisscross-dark.png" }.each do |theme, file|
  page.execute_script(%(document.documentElement.setAttribute('data-theme', '#{theme}')))
  sleep 0.3
  out = File.expand_path("../img/#{file}", __dir__)
  page.driver.browser.screenshot(path: out, selector: ".panel")
  puts "wrote #{out} (#{File.size(out)} bytes)"
end

Capybara.reset_sessions!
