# Browser test (headless Chrome): the opt-in components render and behave.
require_relative "capybara_boot"
require "minitest/autorun"
require "capybara/minitest"

class ComponentsTest < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def setup
    page.current_window.resize_to(1280, 900)
    visit "/admin/components"
  end

  def teardown
    Capybara.reset_sessions!
  end

  def style(selector, property)
    page.evaluate_script("getComputedStyle(document.querySelector(#{selector.to_json})).#{property}")
  end

  def test_status_tag_variants_have_their_own_colors
    colors = %w[ok warning error info empty].map { |status| style("[data-status=#{status}]", "backgroundColor") }
    assert_equal 5, colors.uniq.size
    colors.each { |color| refute_equal "rgba(0, 0, 0, 0)", color }
  end

  def test_status_tag_colors_follow_dark_mode
    light = [style("[data-status=ok]", "backgroundColor"), style("[data-status=ok]", "color")]
    page.execute_script("document.documentElement.classList.add('dark')")
    refute_equal light, [style("[data-status=ok]", "backgroundColor"), style("[data-status=ok]", "color")]
  end

  def test_status_tag_without_a_defined_color_keeps_the_default_look
    assert_equal style("[data-status=no]", "backgroundColor"), style("[data-status=unstyled]", "backgroundColor")
    assert_equal style("[data-status=no]", "color"), style("[data-status=unstyled]", "color")
    page.execute_script("document.documentElement.classList.add('dark')")
    assert_equal style("[data-status=no]", "backgroundColor"), style("[data-status=unstyled]", "backgroundColor")
    assert_equal style("[data-status=no]", "color"), style("[data-status=unstyled]", "color")
  end

  def test_status_tag_reads_a_custom_property_for_its_status
    shipped = style("[data-status=shipped]", "backgroundColor")
    refute_equal style("[data-status=unstyled]", "backgroundColor"), shipped
    expected = page.evaluate_script("(() => { const e = document.createElement('i'); e.style.backgroundColor = 'color-mix(in srgb, #7c3aed 18%, transparent)'; document.body.append(e); return getComputedStyle(e).backgroundColor })()")
    assert_equal expected, shipped
  end

  def test_status_tag_color_option_sets_the_color
    assert_equal "--aat-status-color:#b91c1c", find("#status-late")[:style]
    late = style("#status-late", "backgroundColor")
    refute_equal style("[data-status=error]", "backgroundColor"), late
    refute_equal "rgba(0, 0, 0, 0)", late
  end

  def test_status_tag_color_option_rejects_anything_but_a_color
    error = assert_raises(ArgumentError) do
      Arbre::Context.new { status_tag "x", color: "red;background:url(x)" }.to_s
    end
    assert_match(/plain CSS color/, error.message)
  end

  def test_truncate_text_shows_an_ellipsis_and_the_full_text_in_title
    assert_selector "#truncate-default .aat-truncate[title*='so it is cut']"
    assert_equal "ellipsis", style("#truncate-default .aat-truncate", "textOverflow")
    assert_equal "nowrap", style("#truncate-default .aat-truncate", "whiteSpace")
    assert page.evaluate_script("(() => { const e = document.querySelector('#truncate-narrow .aat-truncate'); return e.scrollWidth > e.clientWidth })()")
    assert_in_delta 128, page.evaluate_script("document.querySelector('#truncate-narrow .aat-truncate').getBoundingClientRect().width"), 1
  end

  def test_truncate_text_length_cuts_the_text
    assert_selector "#truncate-length .aat-truncate", text: "A long sentence t..."
    assert_match(/so it is cut/, find("#truncate-length .aat-truncate")[:title])
  end

  def test_secret_reveal_shows_the_value_on_click_and_hides_it_on_the_second
    assert_selector "#secret button", text: "••••••••"
    assert_no_text "s3cr3t"
    find("#secret button").click
    assert_selector "#secret button", text: "s3cr3t"
    find("#secret button").click
    assert_selector "#secret button", text: "••••••••"
    assert_no_text "s3cr3t"
  end

  def test_secret_reveal_shows_a_failed_request_inline
    page.execute_script("document.querySelector('#secret [data-aat-secret-reveal]').dataset.url = '/admin/components/forbidden'")
    find("#secret button").click
    assert_selector "#secret .aat-secret-reveal-error", text: /Could not load/
    assert_selector "#secret button", text: "••••••••"
  end

  def test_tooltip_title_is_a_title_attribute
    assert_selector "#tooltip-title span[title='Plain title tooltip']", text: "Hover for a title"
  end

  def test_html_tooltip_appears_on_hover_and_is_sanitized
    assert_no_selector "#tooltip-html [role=tooltip]", visible: :visible
    find("#tooltip-html span[data-tooltip-target]").hover
    assert_selector "[role=tooltip] strong", text: "Rich", visible: :visible
    assert_no_selector "[role=tooltip] script", visible: :all
  end

  def test_pre_wrap_wraps_a_long_string_without_widening_the_page
    assert_equal "pre-wrap", style("#pre-wrap pre", "whiteSpace")
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 1280
    assert_operator page.evaluate_script("document.querySelector('#pre-wrap pre').getBoundingClientRect().height"), :>, 40
    page.current_window.resize_to(390, 800)
    visit "/admin/components"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
  end
end
