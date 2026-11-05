module ActiveAdminTheme
  module Views
    # status_tag "Shipped"                     # color from --aat-status-shipped
    # status_tag "Late", color: "#b91c1c"      # one-off color
    #
    # ok, warning, error, info and empty are colored by the theme. For any
    # other value the tag points `--aat-status-color` at `--aat-status-<value>`,
    # which the host defines in its CSS; with no definition the tag stays
    # gray. `color:` sets `--aat-status-color` directly. Prepended to
    # ActiveAdmin's StatusTag; the CSS is components/status_tag.css.
    module StatusTagColor
      # Values the theme or ActiveAdmin already color, and names the CSS uses
      # for its own properties (--aat-status-color, -bg, -fg).
      OWN_STATUSES = %w[ok warning error info empty yes no unset color bg fg].freeze
      COLOR = /\A(\#(\h{3,4}|\h{6}|\h{8})|[a-zA-Z]+|(rgb|hsl)a?\([\d\s.,%\/a-zA-Z-]*\))\z/

      def build(status, options = {})
        color = options.delete(:color)
        super
        value = get_attribute("data-status").to_s
        css = if color
          "--aat-status-color:#{validate_color(color)}"
        elsif value.match?(/\A[a-z0-9_-]+\z/) && !OWN_STATUSES.include?(value)
          "--aat-status-color:var(--aat-status-#{value})"
        end
        return unless css

        add_class "aat-status"
        set_attribute :style, [get_attribute(:style), css].compact.join(";")
      end

      private

      def validate_color(color)
        color = color.to_s.strip
        raise ArgumentError, "status_tag color must be a plain CSS color, got #{color.inspect}" unless color.match?(COLOR)

        color
      end
    end

    ActiveAdmin::Views::StatusTag.prepend(StatusTagColor)
  end
end
