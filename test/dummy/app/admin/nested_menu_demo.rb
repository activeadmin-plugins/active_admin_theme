# Menu items three and four levels deep (parent chains).
ActiveAdmin.register_page "Deep page" do
  menu parent: ["Demo pages", "More demos"], priority: 1

  content do
    para "Third menu level."
  end
end

ActiveAdmin.register_page "Deeper page" do
  menu parent: ["Demo pages", "More demos", "Even more"], priority: 2

  content do
    para "Fourth menu level."
  end
end
