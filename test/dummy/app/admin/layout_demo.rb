# Demo of the columns DSL: ratios, mobile ratio, equal widths, minimum width.
ActiveAdmin.register_page "Columns" do
  menu parent: "Demo pages", priority: 5

  content do
    columns "1:3" do
      column { panel("1/4") { para "Stacked on mobile." } }
      column { panel("3/4") { para "Side by side from 768px." } }
    end
    columns "1:1", mobile: "1:1" do
      column { panel("A") { para "Side by side on mobile too." } }
      column { panel("B") { para "Side by side on mobile too." } }
    end
    columns do
      column { panel("Equal 1") { para "No ratio." } }
      column { panel("Equal 2") { para "No ratio." } }
      column { panel("Equal 3") { para "No ratio." } }
    end
    columns do
      column(span: 2) { panel("span 2") { para "column span: 2 counts as weight 2." } }
      column { panel("span 1") { para "Weight 1." } }
    end
    columns "1:1:1:1:1:1" do
      6.times { |i| column { panel("Narrow #{i + 1}") { para "Wraps when it cannot keep its minimum width." } } }
    end
  end
end
