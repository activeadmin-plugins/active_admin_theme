# One entry per thing worth looking at. Adding a case to the gallery is adding
# a hash here — there is no code to touch.
#
#   name      folder/file name and the heading in the PR comment
#   why       one line explaining what to look at, printed under the heading
#   overrides SCSS variable overrides, exactly as a host project would write them
#   path      path in the dummy admin
#   steps     [[:hover, selector], [:click, selector], [:focus, selector],
#              [:eval, "js"], [:wait, seconds]]
#   crop      selector whose box is captured; omit for the full viewport
#   pad       pixels added around the crop box (default 12)
#   theme     "light" (default) or "dark" — sets data-theme on <html>
#
# Selectors are ActiveAdmin's own: menu items get an id from the menu label, so
# "System" is #system and its children are #system > ul > li.

SCENARIOS = [
  {
    name: "menu-dropdown",
    why: "Dropdown panel: row height, text colour, the current-item marker, " \
         "and the seam where the pill meets the panel.",
    path: "/admin/posts",
    steps: [[:hover, "#system > a"]],
    crop: ["#header", "#system > ul"],
  },
  {
    name: "menu-light-theme",
    why: "The whole point of the menu variables: a light panel must stay " \
         "readable, including the hovered item and the current one.",
    overrides: '$skinMenuPanelColor: #ffffff; $skinMenuTextColor: #333333;
                $skinMenuPillColor: #f0f0f0;',
    path: "/admin/settings",
    steps: [[:hover, "#system > a"], [:hover, "#system > ul > li:first-child > a"]],
    crop: ["#header", "#system > ul"],
  },
  {
    name: "menu-dark-panel",
    why: "A dark panel must keep its hover feedback and its submenu marker.",
    overrides: '$skinMenuPanelColor: #222222;',
    path: "/admin/posts",
    steps: [[:hover, "#system > a"]],
    crop: ["#header", "#system > ul"],
  },
  {
    name: "menu-long-label",
    why: "A long submenu label must stay inside the window — scrolling to " \
         "reach it breaks the :hover chain and closes the menu.",
    path: "/admin/posts",
    steps: [[:hover, "#system > a"], [:hover, "#components > a"]],
    viewport: [1280, 420],
  },
  {
    name: "menu-roomy",
    why: "With the size knobs turned up, the marker must stay centred and the " \
         "dropdown must not inherit the top-level font size.",
    overrides: '$skinMenuFontSize: 1.6em; $skinMenuItemPaddingY: 12px;',
    path: "/admin/posts",
    steps: [[:hover, "#system > a"]],
    crop: ["#header", "#system > ul"],
  },
  {
    name: "menu-split-colours",
    why: "Pill and panel coloured independently — the junction between them " \
         "must not show the header through.",
    overrides: '$skinMenuPillColor: #e63946;',
    path: "/admin/posts",
    steps: [[:hover, "#system > a"]],
    crop: ["#header", "#system > ul"],
    pad: 4,
  },
  {
    name: "menu-keyboard-focus",
    why: "A dropdown item reached by keyboard needs the theme's own indicator, " \
         "not just the browser outline.",
    overrides: '$skinMenuItemHoverColor: #3a7fb5;',
    path: "/admin/posts",
    steps: [[:hover, "#system > a"], [:focus, "#system > ul > li:nth-child(2) > a"]],
    crop: ["#header", "#system > ul"],
  },
  {
    name: "header-and-title-bar",
    why: "Header padding and the title bar: logo baseline, breadcrumb, and the " \
         "two action buttons, which must agree with each other.",
    overrides: '$skinTitleBarButtonPaddingY: 6px; $skinTitleBarButtonPaddingX: 14px;',
    path: "/admin/posts",
    crop: "#title_bar",
    pad: 60,
  },
  {
    name: "index-table",
    why: "Index table: header cells, zebra striping, row hover, and the " \
         "selected state after ticking checkboxes.",
    path: "/admin/posts",
    steps: [[:click, "#collection_selection_toggle_all"],
            [:hover, "table.index_table tbody tr:nth-child(3)"]],
    crop: "#active_admin_content",
  },
  {
    name: "index-table-tools",
    why: "Scopes, batch actions and the rest of the tool row — one height, one " \
         "fill, and the active scope has to be identifiable.",
    path: "/admin/posts",
    steps: [[:click, "#collection_selection_toggle_all"],
            [:click, "div.batch_actions_selector a.dropdown_menu_button"]],
    crop: "div.table_tools",
    pad: 24,
  },
  {
    name: "pagination",
    why: "Page numbers, including the hovered one, and the record count line.",
    path: "/admin/posts",
    steps: [[:hover, ".pagination span.page a"]],
    crop: "#index_footer",
    pad: 24,
  },
  {
    name: "filters-sidebar",
    why: "Filter sidebar: labels, inputs, focus ring and the buttons.",
    path: "/admin/posts",
    steps: [[:focus, "#q_title"]],
    crop: "#filters_sidebar_section",
  },
  {
    name: "form",
    why: "Form: fieldset header, labels, inputs, and the submit button.",
    path: "/admin/posts/new",
    crop: "form.formtastic",
  },
  {
    name: "show-page",
    why: "Show page: panel header, attribute table and the action buttons.",
    path: "/admin/posts/1",
    crop: "#active_admin_content",
  },
  {
    name: "status-tags-and-links",
    why: "Content link colour against the page background, and status tags.",
    path: "/admin/posts",
    crop: "table.index_table",
    pad: 0,
  },
].freeze
