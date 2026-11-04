module ActiveAdminTheme
  module Helpers
    module PreWrap
      # pre_wrap(record.raw_payload)
      #
      # A <pre> that keeps line breaks and wraps long lines. The text is escaped.
      def pre_wrap(text)
        content_tag(:pre, text.to_s, class: "aat-pre-wrap")
      end
    end
  end
end

ActiveSupport.on_load(:action_view) { include ActiveAdminTheme::Helpers::PreWrap }
