# Browser test (headless Chrome): the confirm_dialog component opens, cancels, validates and submits.
require_relative "capybara_boot"
require "minitest/autorun"
require "capybara/minitest"

class ConfirmDialogTest < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  PAGE = "/admin/confirm_dialog".freeze

  def setup
    page.current_window.resize_to(1280, 900)
  end

  def teardown
    Capybara.reset_sessions!
  end

  def open_dialog(id)
    visit PAGE
    find("[data-modal-target='#{id}']").click
    assert_selector "##{id}", visible: :visible
  end

  def test_opens_on_click_and_moves_focus_inside
    visit PAGE
    assert_no_selector "#plain-confirm", visible: :visible
    find("[data-modal-target='plain-confirm']").click
    assert_selector "#plain-confirm[role=dialog][aria-modal=true]", visible: :visible
    assert_selector "#plain-confirm-title", text: "Archive customer?"
    assert_equal "plain-confirm-title", find("#plain-confirm")["aria-labelledby"]
    assert_selector "#plain-confirm button.aat-confirm-cancel:focus"
  end

  def test_cancel_closes_without_submitting
    open_dialog("plain-confirm")
    click_button "Cancel"
    assert_no_selector "#plain-confirm", visible: :visible
    assert_current_path PAGE
    assert_selector "[data-modal-target='plain-confirm']:focus"
  end

  def test_escape_closes
    open_dialog("plain-confirm")
    page.send_keys(:escape)
    assert_no_selector "#plain-confirm", visible: :visible
    assert_current_path PAGE
  end

  def test_confirm_submits_the_entered_values
    open_dialog("fields-confirm")
    assert_selector "#fields-confirm-reason:focus"
    fill_in "Reason", with: "Duplicate account"
    fill_in "Short title", with: "Dup"
    select "High", from: "Priority"
    check "Notify customer"
    click_button "Send"
    assert_text "POST"
    assert_text '"reason":"Duplicate account"'
    assert_text '"title":"Dup"'
    assert_text '"priority":"high"'
    assert_text '"notify":"1"'
  end

  def test_confirm_uses_the_method_override
    open_dialog("delete-confirm")
    click_button "Delete", exact: true
    assert_text "DELETE"
  end

  def test_required_field_blocks_submit
    open_dialog("fields-confirm")
    click_button "Send"
    assert_selector "#fields-confirm", visible: :visible
    assert_selector "#fields-confirm-reason[aria-invalid=true]"
    assert_current_path PAGE
    fill_in "Reason", with: "Now filled"
    assert_no_selector "#fields-confirm-reason[aria-invalid=true]"
    click_button "Send"
    assert_text "POST"
  end

  def test_required_field_rejects_spaces_only
    open_dialog("fields-confirm")
    fill_in "Reason", with: "   "
    click_button "Send"
    assert_selector "#fields-confirm", visible: :visible
    assert_current_path PAGE
  end

  def test_closing_resets_the_form
    open_dialog("fields-confirm")
    fill_in "Reason", with: "Typed"
    click_button "Cancel"
    find("[data-modal-target='fields-confirm']").click
    assert_equal "", find("#fields-confirm-reason").value
  end

  def test_fits_a_phone_and_follows_dark_mode
    page.current_window.resize_to(390, 800)
    open_dialog("fields-confirm")
    rect = page.evaluate_script("document.querySelector('#fields-confirm .aat-confirm-panel').getBoundingClientRect().toJSON()")
    assert_operator rect["left"], :>=, 0
    assert_operator rect["right"], :<=, 390
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
    light = page.evaluate_script("getComputedStyle(document.querySelector('#fields-confirm .aat-confirm-panel')).backgroundColor")
    page.execute_script("document.documentElement.classList.add('dark')")
    dark = page.evaluate_script("getComputedStyle(document.querySelector('#fields-confirm .aat-confirm-panel')).backgroundColor")
    refute_equal light, dark
  end
end
