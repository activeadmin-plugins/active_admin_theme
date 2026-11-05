# Browser test (headless Chrome): the layout behaves as the visual contract says.
require_relative "capybara_boot"
require "minitest/autorun"
require "capybara/minitest"

class LayoutTest < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def setup
    page.current_window.resize_to(1280, 900)
  end

  def teardown
    Capybara.reset_sessions!
  end

  def test_desktop_has_top_menu_and_no_drawer
    visit "/admin/customers"
    assert_selector "#site-header nav a", text: "Customers"
    assert_no_selector "#main-menu", visible: :visible
  end

  def test_top_menu_breakpoint_is_768
    page.current_window.resize_to(768, 900)
    visit "/admin/customers"
    assert_selector "#site-header nav a", text: "Customers"
  end

  def test_menu_group_opens_on_hover
    visit "/admin/customers"
    assert_no_selector "#top-menu-demo_pages", visible: :visible
    find("#site-header nav a", text: "Demo pages").hover
    assert_selector "#top-menu-demo_pages a", text: "Wide table", visible: :visible
  end

  def test_mobile_menu_opens_in_a_drawer
    page.current_window.resize_to(390, 800)
    visit "/admin/customers"
    assert_no_selector "#site-header nav a", text: "Customers"
    find("#site-header button[data-drawer-show='main-menu']").click
    assert_selector "#main-menu a", text: "Customers", visible: :visible
  end

  def test_filters_sit_left_of_the_table_on_desktop_and_above_on_mobile
    visit "/admin/customers"
    filters = page.evaluate_script("document.querySelector('[data-aat-sidebar]').getBoundingClientRect().toJSON()")
    table = page.evaluate_script("document.querySelector('table.data-table').getBoundingClientRect().toJSON()")
    assert_operator filters["right"], :<=, table["left"]

    page.current_window.resize_to(390, 800)
    visit "/admin/customers"
    filters = page.evaluate_script("document.querySelector('[data-aat-sidebar]').getBoundingClientRect().toJSON()")
    table = page.evaluate_script("document.querySelector('table.data-table').getBoundingClientRect().toJSON()")
    assert_operator filters["bottom"], :<=, table["top"]
  end

  def test_filters_collapse_and_the_table_takes_the_width
    visit "/admin/customers"
    before = page.evaluate_script("document.querySelector('.paginated-collection').getBoundingClientRect().width")
    find("[data-aat-sidebar-toggle]").click
    assert_no_selector "[data-aat-sidebar]", visible: :visible
    after = page.evaluate_script("document.querySelector('.paginated-collection').getBoundingClientRect().width")
    assert_operator after, :>, before + 200
    find("[data-aat-sidebar-toggle]").click
    assert_selector "[data-aat-sidebar]", visible: :visible
  end

  def test_wide_index_tables_scroll_inside_their_wrapper_not_the_page
    page.current_window.resize_to(390, 800)
    visit "/admin/customers"
    scroll = page.evaluate_script("document.documentElement.scrollWidth")
    assert_operator scroll, :<=, 390
    assert page.evaluate_script("(() => { const w = document.querySelector('.index-as-table'); return w.scrollWidth > w.clientWidth })()")
  end

  def test_index_cells_stay_on_one_line
    visit "/admin/customers"
    assert_equal "nowrap", page.evaluate_script("getComputedStyle(document.querySelector('table.data-table tbody td')).whiteSpace")
  end

  def test_server_clock_renders_and_ticks
    visit "/admin/customers"
    assert_selector "[data-server-clock] .clock-time", text: /\A\d{2}:\d{2}:\d{2}\s+\S+\z/
    first = find("[data-server-clock] .clock-time").text
    assert_no_selector "[data-server-clock] .clock-time", text: first, wait: 3
    data = find("[data-server-clock] [data-servertime-epoch]", visible: :all)
    assert_equal Time.zone.tzinfo.identifier, data["data-servertime-zone"]
  end

  def test_header_has_user_and_logout
    visit "/admin/customers"
    assert_selector "[data-test-current-user]", text: "Demo Admin"
    assert_selector "#site-header a.aat-logout"
  end

  def test_action_items_are_buttons
    visit "/admin/customers"
    background = page.evaluate_script("getComputedStyle(document.querySelector('[data-test-action-items] a')).backgroundColor")
    refute_equal "rgba(0, 0, 0, 0)", background
  end

  def test_crisscross_marks_row_and_column
    visit "/admin/customers"
    cells = all("table.data-table tbody tr:nth-child(2) td")
    cells[3].click
    assert_selector "table.data-table td[data-selected-cell]", count: 1
    assert_selector "table.data-table tbody td[data-selected]", minimum: 30
    assert_no_selector "table.data-table tbody tr.selected"
  end

  def test_tabs_switch_panels
    visit "/admin/customers/1"
    assert_selector "[role=tab]", count: 2
    assert_selector "#notes", visible: :visible
    assert_no_selector "#raw", visible: :visible
    find("[role=tab]", text: "Raw").click
    assert_selector "#raw", visible: :visible
    assert_no_selector "#notes", visible: :visible
  end

  def test_columns_split_by_ratio_and_stack_on_mobile
    visit "/admin/columns"
    widths = page.evaluate_script("[...document.querySelectorAll('.aat-columns')[0].children].map(c => c.getBoundingClientRect().width)")
    assert_in_delta 3.0, widths[1] / widths[0], 0.4
    page.current_window.resize_to(390, 800)
    visit "/admin/columns"
    tops = page.evaluate_script("[...document.querySelectorAll('.aat-columns')[0].children].map(c => c.getBoundingClientRect().top)")
    assert_operator tops[1], :>, tops[0]
    side = page.evaluate_script("[...document.querySelectorAll('.aat-columns')[1].children].map(c => c.getBoundingClientRect().top)")
    assert_equal side[0], side[1]
  end

  def test_columns_wrap_instead_of_clipping
    visit "/admin/columns"
    lines = page.evaluate_script("new Set([...document.querySelectorAll('.aat-columns')[4].children].map(c => Math.round(c.getBoundingClientRect().top))).size")
    assert_operator lines, :>, 1
  end

  def test_show_page_and_sidebar_are_panels
    visit "/admin/customers/1"
    assert_selector ".panel .panel-title", text: "Customer Details"
    assert_selector "[data-aat-sidebar] .panel .panel-title", text: "Help"
  end
end
