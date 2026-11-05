module ActiveAdminTheme
  # ActiveAdmin 4 dropped submenus deeper than one level (its UPGRADING.md), and
  # Menu#add raises TypeError for `parent: ["Customer", "Settings"]`. This puts
  # back ActiveAdmin 3's parent chain; the theme's menus render any depth.
  module NestedMenu
    def add(options, &block)
      chain = options[:parent]
      return super unless chain.is_a?(Array)

      first, *rest = chain
      return super(options.except(:parent), &block) unless first

      node = self[first] || add(label: first)
      node.add(rest.empty? ? options.except(:parent) : options.merge(parent: rest), &block)
    end

    # ActiveAdmin checks only direct children, so a top item would not be
    # marked current for a page two levels below it.
    def current?(item, children: true)
      super || (children && self.children.values.any? { |child| child.current?(item) })
    end
  end
end

ActiveAdmin::Menu.prepend(ActiveAdminTheme::NestedMenu)
ActiveAdmin::MenuItem.prepend(ActiveAdminTheme::NestedMenu)
