module ActiveAdminTheme
  module Views
    # columns "1:3", mobile: "1:1" do
    #   column { ... }
    #   column(span: 2) { ... }
    # end
    #
    # The ratio string gives one weight per column. With no ratio, every column
    # has the same width, or its own `span:` weight. Weights set `--aat-w`
    # (desktop) and `--aat-mw` (mobile) on each column; the CSS in
    # active_admin_theme.css turns them into flex sizes. Below the theme
    # breakpoint the columns stack unless `mobile:` gives a ratio.
    class Columns < ActiveAdmin::Component
      builder_method :columns

      def build(ratio = nil, options = {})
        # columns(mobile: "1:1") passes the options hash as the first argument.
        ratio, options = nil, ratio if ratio.is_a?(Hash)
        @ratio = parse(ratio)
        @mobile_ratio = parse(options[:mobile])
        super(options.except(:mobile))
        add_class "aat-columns"
        set_attribute "data-mobile", "" if @mobile_ratio
      end

      def to_s
        columns = children.select { |child| child.is_a?(Column) }
        weights = columns.each_with_index.map { |column, i| @ratio&.fetch(i, nil) || column.span }
        mobile = columns.each_with_index.map { |_, i| @mobile_ratio&.fetch(i, nil) || 1 }
        columns.each_with_index { |column, i| column.apply_weights(weights[i], weights.sum, mobile[i], mobile.sum) }
        super
      end

      # An instance method, not a global builder_method: `column` also names
      # ActiveAdmin's index-table column, and a global one would shadow it.
      def column(options = {}, &block)
        insert_tag Column, options, &block
      end

      private

      def parse(ratio)
        return nil if ratio.blank?

        weights = ratio.to_s.split(":").map { |part| Float(part) }
        raise ArgumentError, "columns ratio must be positive numbers: #{ratio.inspect}" if weights.empty? || weights.any? { |w| w <= 0 }

        weights.map { |w| w.to_i == w ? w.to_i : w }
      rescue ArgumentError, TypeError
        raise ArgumentError, "columns ratio must look like \"1:3\", got #{ratio.inspect}"
      end
    end

    class Column < ActiveAdmin::Component
      attr_reader :span

      def build(options = {})
        @span = options.delete(:span) || 1
        super(options)
        add_class "aat-column"
      end

      def apply_weights(weight, total, mobile_weight, mobile_total)
        existing = get_attribute(:style)
        style = "--aat-w:#{weight};--aat-t:#{total};--aat-mw:#{mobile_weight};--aat-mt:#{mobile_total}"
        set_attribute :style, [existing, style].compact.join(";")
      end
    end
  end
end
