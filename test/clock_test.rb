# Integration test: the server clock renders as two ticking lines in the
# utility nav, and the logout item sits beside it. Proves the gem's JS
# (server_clock.js) + Ruby backend (install!) work end to end in a
# real browser against a real ActiveAdmin page.
require_relative "capybara_boot"
require "minitest/autorun"
require "capybara/minitest"

class ClockTest < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def teardown
    Capybara.reset_sessions!
  end

  def test_clock_renders_two_ticking_lines_and_logout
    visit "/admin"

    # 1. Two-line structure: li#servertime with a .clock-time and a .clock-date.
    assert_selector "#utility_nav li#servertime", wait: 5
    assert_selector "#utility_nav li#servertime .clock-time", wait: 5
    assert_selector "#utility_nav li#servertime .clock-date", wait: 5

    time_text = find("#utility_nav li#servertime .clock-time").text
    date_text = find("#utility_nav li#servertime .clock-date").text

    # Shapes: "HH:MM:SS <ZONE>" over "YYYY <Mon> DD".
    assert_match(/\A\d{2}:\d{2}:\d{2}\s+\S+\z/, time_text,
                 "clock-time should read 'HH:MM:SS <ZONE>', got #{time_text.inspect}")
    assert_match(/\A\d{4}\s+[A-Z][a-z]{2}\s+\d{2}\z/, date_text,
                 "clock-date should read 'YYYY <Mon> DD', got #{date_text.inspect}")

    # 2. Ticking: a retrying Capybara assertion, not a one-shot sample — a busy
    # CI runner can delay the 1s interval past any fixed sleep, and tick()
    # replaces the node each second, so re-querying until the text changes is
    # the only race-free check.
    assert_no_selector "#utility_nav li#servertime .clock-time", text: time_text, wait: 3

    # 3. Logout lives in the utility nav too — specifically the THEME's item
    # (a.wigu-logout), not AA's default, which would also appear if install!
    # never ran.
    assert_selector "#utility_nav li#logout > a.wigu-logout"

    # 4. The displayed clock is the SERVER's. Every assertion above would also
    # pass against a client-side fallback (same selectors, same shapes, same
    # ticking), so pin the data span the backend renders: the app's own zone
    # and a fresh epoch. visible: :all — the JS hides it once mounted.
    data = find("#utility_nav li#servertime [data-servertime-epoch]", visible: :all)
    assert_equal Time.zone.tzinfo.identifier, data["data-servertime-zone"]
    assert_in_delta Time.now.to_i, data["data-servertime-epoch"].to_i, 60
  end

  def test_sticky_headers_apply_to_the_demo_table
    visit "/admin/wide_table"
    assert_selector ".wide-demo thead th", minimum: 12
    # Computed style, not class presence: a selector typo or an AA DOM rename
    # would otherwise pass every suite silently — before this test the sticky
    # rules matched nothing in the repo's own test surface.
    position = page.evaluate_script(
      "getComputedStyle(document.querySelector('.wide-demo thead th')).position"
    )
    assert_equal "sticky", position,
                 "the demo table opts in via .with-sticky-headers; its thead should be sticky"
  end
end
