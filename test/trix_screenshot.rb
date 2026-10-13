# Regenerates img/trix-light.png / img/trix-dark.png — the themed Trix editor
# (toolbar + sample content) in both palettes, for the PR/README. Same dummy app
# and driver the clock screenshot uses; crops to the editor panel.
require_relative "capybara_boot"
require "capybara/dsl"

include Capybara::DSL

def shoot(theme, out)
  visit "/admin/rich_text"
  # Trix enhances <trix-editor> into a full toolbar on load; wait for it.
  find("trix-toolbar .trix-button--icon-bold", wait: 5)
  # Place the cursor in the content so Trix enables the block-format buttons
  # (quote/code/lists/nesting), which it disables while the editor is unfocused —
  # the screenshot then shows the toolbar in its normal in-use state.
  page.execute_script(<<~JS)
    var ed = document.querySelector('trix-editor');
    ed.focus();
    if (ed.editor) ed.editor.setSelectedRange([5, 5]);
  JS
  page.execute_script(%(document.documentElement.setAttribute('data-theme', '#{theme}')))
  sleep 0.4
  page.driver.save_screenshot(out, selector: ".panel")
  puts "wrote #{out} (#{File.size(out)} bytes)"
end

page.driver.resize_window_to(page.driver.window_handles.first, 980, 720) rescue nil

shoot("light", File.expand_path("../img/trix-light.png", __dir__))
shoot("dark",  File.expand_path("../img/trix-dark.png", __dir__))

Capybara.reset_sessions!
