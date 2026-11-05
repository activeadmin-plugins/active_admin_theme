module ActiveAdminTheme
  module Helpers
    module Tooltip
      # with_tooltip("42", "Total orders")
      # with_tooltip("42", "<b>Total</b> orders", html: true)
      #
      # A plain tooltip is a `title` attribute. With `html: true` the tooltip
      # is sanitized HTML shown by ActiveAdmin's Flowbite tooltip.
      def with_tooltip(content, tooltip, html: false)
        return content_tag(:span, content, title: tooltip) unless html

        id = "aat-tooltip-#{SecureRandom.hex(4)}"
        safe_join([
          content_tag(:span, content, "data-tooltip-target": id),
          content_tag(:div, sanitize(tooltip.to_s), id: id, role: "tooltip",
            class: "absolute z-10 invisible inline-block px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-xs opacity-0 tooltip dark:bg-gray-700")
        ])
      end
    end
  end
end

ActiveSupport.on_load(:action_view) { include ActiveAdminTheme::Helpers::Tooltip }
