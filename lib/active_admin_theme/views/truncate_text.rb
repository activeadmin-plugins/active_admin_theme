module ActiveAdminTheme
  module Views
    # truncate_text(text)                           # CSS ellipsis, 20rem wide
    # truncate_text(text, max_width: "12rem")       # width limit
    # truncate_text(text, length: 40)               # also cut to 40 characters
    #
    # One line; the full value is in the `title` attribute. `max_width` is a
    # number (pixels) or a number with px, rem, em, ch, % or vw.
    class TruncateText < ActiveAdmin::Component
      builder_method :truncate_text

      MAX_WIDTH = /\A\d+(\.\d+)?(px|rem|em|ch|%|vw)?\z/

      def tag_name
        "span"
      end

      def build(text, options = {})
        options = options.dup
        length = options.delete(:length)
        max_width = options.delete(:max_width)
        text = text.to_s
        super(options)
        add_class "aat-truncate"
        set_attribute :title, text if text.present? && !get_attribute(:title)
        set_attribute :style, [get_attribute(:style), "--aat-truncate-width:#{width(max_width)}"].compact.join(";") if max_width
        text_node(length ? text.truncate(length) : text)
      end

      private

      def width(value)
        value = value.is_a?(Numeric) ? "#{value}px" : value.to_s.strip
        raise ArgumentError, "truncate_text max_width must be a number or a CSS length, got #{value.inspect}" unless value.match?(MAX_WIDTH)

        value.match?(/\d\z/) ? "#{value}px" : value
      end
    end
  end
end
