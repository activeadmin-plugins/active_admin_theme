# Demo page with a table wider than the viewport, so the page scrolls
# horizontally — used to show the header + title bar (title on the left, the
# action button on the right) staying pinned while the table scrolls under them.
ActiveAdmin.register_page "Wide table" do
  menu priority: 4

  action_item(:new_record) { link_to "New record", "#" }

  content do
    # Locals, not constants: assignment inside this block is lexically
    # top-level (it lands on Object), and AA re-loads every app/admin file on
    # dev reload, re-assigning the constant with a warning each time.
    cols = (1..12).map { |i| "Column #{i}" }
    # Enough rows that the page also scrolls vertically, so the sticky thead
    # (opted in below) actually sticks and the test can observe it.
    rows = (1..40).map { |r| (1..12).map { |c| "row #{r} / value #{c}" } }

    # nowrap + a min cell width so the 12 columns push the table past the
    # viewport and the page scrolls sideways (what the sticky bars are for).
    text_node <<~HTML.html_safe
      <style>#wrapper .wide-demo td, #wrapper .wide-demo th {
        white-space: nowrap; min-width: 150px;
      }</style>
    HTML
    panel "A table wider than the viewport" do
      head = "<thead><tr>" + cols.map { |c| "<th>#{ERB::Util.html_escape(c)}</th>" }.join + "</tr></thead>"
      body = rows.map do |row|
        "<tr>" + row.map { |cell| "<td>#{ERB::Util.html_escape(cell)}</td>" }.join + "</tr>"
      end.join
      text_node(
        # with-sticky-headers: the one place in the repo's test surface where
        # the sticky-thead selector matches a real element (AA's own index
        # tables need a database-backed resource the dummy doesn't have).
        (%(<table class="index_table with-sticky-headers wide-demo">) + head + "<tbody>" + body + "</tbody></table>")
          .html_safe
      )
    end
  end
end
