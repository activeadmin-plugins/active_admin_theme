# Browser test (headless Chrome): the searchable select loads, pages, filters
# and depends on its parent as the form and filter inputs promise.
require_relative "capybara_boot"
require "minitest/autorun"
require "capybara/minitest"

class SearchableSelectTest < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  OPTION = ".ts-dropdown-content .option[data-value]:not(.loading-more-results)".freeze

  def setup
    page.current_window.resize_to(1280, 900)
  end

  def teardown
    Capybara.reset_sessions!
  end

  def test_typing_filters_options_through_ajax
    visit "/admin/orders/new"
    wrapper = wrapper_for("order[customer_id]")
    open_dropdown(wrapper)
    wrapper.assert_selector OPTION, minimum: 10
    search(wrapper, "Customer 17")
    wrapper.assert_selector OPTION, count: 1
    wrapper.assert_selector OPTION, text: "Customer 17"
  end

  def test_scrolling_the_dropdown_loads_the_next_page
    visit "/admin/orders/new"
    wrapper = wrapper_for("order[customer_id]")
    open_dropdown(wrapper)
    wrapper.assert_selector OPTION, minimum: 10
    # Each page holds 10 of the 30 customers; scrolling to the bottom pulls the
    # next page until none is left.
    6.times do
      scroll_dropdown_to_bottom
      sleep 0.3
    end
    wrapper.assert_selector OPTION, count: 30
  end

  def test_selection_submits_with_the_form
    visit "/admin/orders/new"
    fill_in "Reference", with: "ORD-NEW"
    pick("order[customer_id]", "Customer 17")
    pick("order[country_id]", "Country 05")
    pick("order[city_id]", "Country 05 City 2")
    click_button "Create Order"
    assert_text "Order was successfully created"
    assert_selector "td", text: "Customer 17"
    assert_selector "td", text: "Country 05 City 2"
  end

  def test_edit_form_shows_the_selected_option_without_loading_the_list
    visit "/admin/orders/1/edit"
    wrapper = wrapper_for("order[customer_id]")
    wrapper.assert_selector ".item", text: "Customer 1"
    options = page.evaluate_script("document.querySelectorAll(\"select[name='order[customer_id]'] option\").length")
    assert_operator options, :<=, 2
  end

  def test_dependent_child_is_disabled_until_the_parent_has_a_value_and_reloads_on_change
    visit "/admin/orders/new"
    assert_selector ".ts-wrapper.disabled", count: 1
    assert_selector ".ts-wrapper.disabled input[placeholder='Select a country first']", visible: :all

    pick("order[country_id]", "Country 05")
    assert_no_selector ".ts-wrapper.disabled"
    city = wrapper_for("order[city_id]")
    open_dropdown(city)
    city.assert_selector OPTION, count: 3
    assert_equal ["Country 05 City 1", "Country 05 City 2", "Country 05 City 3"], city.all(OPTION).map(&:text)
    city.find(OPTION, text: "Country 05 City 2").click
    city.assert_selector ".item", text: "Country 05 City 2"

    pick("order[country_id]", "Country 06")
    city = wrapper_for("order[city_id]")
    city.assert_no_selector ".item"
    open_dropdown(city)
    city.assert_selector OPTION, count: 3
    assert_equal ["Country 06 City 1", "Country 06 City 2", "Country 06 City 3"], city.all(OPTION).map(&:text)
  end

  def test_works_on_a_phone_sized_screen
    page.current_window.resize_to(390, 800)
    visit "/admin/orders/new"
    wrapper = wrapper_for("order[customer_id]")
    open_dropdown(wrapper)
    wrapper.assert_selector OPTION, count: 10
    right = page.evaluate_script("document.querySelector('.ts-wrapper.dropdown-active .ts-dropdown').getBoundingClientRect().right")
    assert_operator right, :<=, 390
    scroll_dropdown_to_bottom
    wrapper.assert_selector OPTION, count: 20
    wrapper.find(OPTION, text: "Customer 17").click
    wrapper.assert_selector ".item", text: "Customer 17"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
  end

  def test_filter_input_filters_the_index
    visit "/admin/orders"
    assert_selector "table.data-table tbody tr", count: 30
    pick("q[customer_id_eq]", "Customer 17")
    click_button "Filter"
    expected = Order.where(customer_id: 17).count
    assert_operator expected, :>=, 2
    assert_selector "table.data-table tbody tr", count: expected
    assert_selector "table.data-table tbody tr", text: "Customer 17", count: expected
    wrapper_for("q[customer_id_eq]").assert_selector ".item", text: "Customer 17"
  end

  def test_dependent_filter_waits_for_its_parent
    visit "/admin/orders"
    assert_selector ".ts-wrapper.disabled", count: 1
    pick("q[country_id_eq]", "Country 05")
    assert_no_selector ".ts-wrapper.disabled"
    pick("q[city_id_eq]", "Country 05 City 1")
    click_button "Filter"
    assert_selector "table.data-table tbody tr", count: 1
    assert_selector "table.data-table tbody tr", text: "Country 05 City 1"
  end

  def test_option_labels_are_escaped
    visit "/admin/orders/new"
    wrapper = wrapper_for("order[country_id]")
    open_dropdown(wrapper)
    search(wrapper, "Italic")
    wrapper.assert_selector OPTION, count: 1
    assert_equal %(<i>Italic</i> & "Quoted"), wrapper.find(OPTION).text
    assert_no_selector ".ts-dropdown i"
  end

  private

  # Tom Select inserts its wrapper right after the original <select>.
  def wrapper_for(name)
    find(:xpath, "//select[@name='#{name}']/following-sibling::div[contains(@class, 'ts-wrapper')][1]", visible: :all)
  end

  # send_keys, not set: Tom Select listens for key events, which set bypasses.
  def search(wrapper, text)
    input = wrapper.find(".dropdown-input")
    input.click
    input.send_keys(text)
  end

  def open_dropdown(wrapper)
    wrapper.find(".ts-control").click
    wrapper.assert_selector ".ts-dropdown", visible: :visible
  end

  def pick(name, text)
    wrapper = wrapper_for(name)
    open_dropdown(wrapper)
    search(wrapper, text)
    # The previous query's single result can still be on screen until the new
    # response arrives, so wait for the option that matches.
    wrapper.assert_selector OPTION, count: 1, text: text
    wrapper.find(OPTION, text: text).click
    wrapper_for(name).assert_selector ".item", text: text
    wrapper_for(name).assert_no_selector ".ts-dropdown", visible: :visible
  end

  def scroll_dropdown_to_bottom
    page.execute_script("const c = document.querySelector('.ts-wrapper.dropdown-active .ts-dropdown-content'); c.scrollTop = c.scrollHeight")
  end
end
