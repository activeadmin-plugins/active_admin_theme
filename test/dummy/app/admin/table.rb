# Demo page with a plain index table so the crisscross highlighting (wigu/
# table_crisscross.js) can be exercised and screenshotted: clicking a cell marks
# its whole row and column with .selected, which the theme paints.
ActiveAdmin.register_page "Table" do
  menu priority: 3

  ROWS = [
    %w[101 Ada\ Lovelace ada@example.com UK Active],
    %w[102 Alan\ Turing alan@example.com UK Active],
    %w[103 Grace\ Hopper grace@example.com US Closed],
    %w[104 Katherine\ Johnson katherine@example.com US Active],
    %w[105 Edsger\ Dijkstra edsger@example.com NL Closed],
    %w[106 Donald\ Knuth donald@example.com US Active]
  ].freeze

  content do
    panel "Crisscross highlighting (click a cell)" do
      head = "<thead><tr><th>ID</th><th>Name</th><th>Email</th>" \
             "<th>Country</th><th>Status</th></tr></thead>"
      body = ROWS.map do |r|
        "<tr>" + r.map { |c| "<td>#{ERB::Util.html_escape(c)}</td>" }.join + "</tr>"
      end.join
      text_node(
        (%(<table class="index_table">) + head + "<tbody>" + body + "</tbody></table>")
          .html_safe
      )
    end
  end
end
