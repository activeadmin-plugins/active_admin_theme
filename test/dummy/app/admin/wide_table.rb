# Demo page with a table wider than the viewport, so the page scrolls
# horizontally — used to show the header + title bar (title on the left, the
# action button on the right) staying pinned while the table scrolls under them.
ActiveAdmin.register_page "Wide table" do
  menu priority: 4

  action_item(:new_record) { link_to "New record", "#" }

  WIDE_COLS = (1..12).map { |i| "Column #{i}" }.freeze
  WIDE_ROWS = (1..5).map { |r| (1..12).map { |c| "row #{r} / value #{c}" } }.freeze

  content do
    # nowrap + a min cell width so the 12 columns push the table past the
    # viewport and the page scrolls sideways (what the sticky bars are for).
    text_node <<~HTML.html_safe
      <style>#wrapper .wide-demo td, #wrapper .wide-demo th {
        white-space: nowrap; min-width: 150px;
      }</style>
    HTML
    panel "A table wider than the viewport" do
      head = "<thead><tr>" + WIDE_COLS.map { |c| "<th>#{c}</th>" }.join + "</tr></thead>"
      body = WIDE_ROWS.map do |row|
        "<tr>" + row.map { |cell| "<td>#{ERB::Util.html_escape(cell)}</td>" }.join + "</tr>"
      end.join
      text_node(
        (%(<table class="index_table wide-demo">) + head + "<tbody>" + body + "</tbody></table>")
          .html_safe
      )
    end
  end
end
