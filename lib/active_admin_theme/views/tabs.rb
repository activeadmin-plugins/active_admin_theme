module ActiveAdminTheme
  module Views
    # tabs do
    #   tab("Details") { ... }
    #   tab("History", id: "history") { ... }
    # end
    #
    # Built on Flowbite's tabs (data-tabs-toggle / data-tabs-target), which
    # ActiveAdmin already loads, so no extra script is needed.
    class Tabs < ActiveAdmin::Component
      builder_method :tabs

      def build(options = {})
        super(options)
        add_class "aat-tabs"
        @tab_ids = []
        @nav = ul(class: "aat-tabs-nav", role: "tablist", id: "#{object_id}-tabs", "data-tabs-toggle": "##{object_id}-panels")
        @panels = div(id: "#{object_id}-panels")
      end

      # An instance method, not a global builder_method, so `tab` stays free
      # for other components.
      def tab(title, options = {}, &block)
        insert_tag Tab, title, options, &block
      end

      def add_child(child)
        if @panels && child.is_a?(Tab)
          @panels << child
        else
          super
        end
      end

      def add_tab_button(title, id)
        first = @tab_ids.empty?
        @tab_ids << id
        with_current_arbre_element(@nav) do
          li(class: "aat-tab-item", role: "presentation") do
            button(title, type: "button", class: "aat-tab", role: "tab", id: "#{id}-tab",
                          "data-tabs-target": "##{id}", "aria-controls": id,
                          "aria-selected": first.to_s)
          end
        end
        first
      end
    end

    class Tab < ActiveAdmin::Component
      def build(title, options = {})
        id = options.delete(:id) || title.to_s.parameterize.presence || "tab-#{object_id}"
        tabs = [parent, parent&.parent].find { |element| element.is_a?(Tabs) }
        first = tabs ? tabs.add_tab_button(title, id) : true
        super(options.merge(id: id, role: "tabpanel", "aria-labelledby": "#{id}-tab"))
        add_class "aat-tab-panel"
        add_class "hidden" unless first
      end
    end
  end
end
