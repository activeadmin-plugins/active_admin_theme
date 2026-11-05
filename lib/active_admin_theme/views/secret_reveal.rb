module ActiveAdminTheme
  module Views
    # secret_reveal(url: secret_admin_account_path(account))
    # secret_reveal(url: token_path, mask: "*****", method: :post)
    #
    # Shows the mask. A click requests the URL with fetch and shows the
    # `value` of the JSON reply; a second click hides it again. Nothing secret
    # is in the page until then. The endpoint must answer `{"value": "..."}`.
    # Needs the opt-in module active_admin_theme/secret_reveal; see
    # ActiveAdminTheme.javascripts.
    class SecretReveal < ActiveAdmin::Component
      builder_method :secret_reveal

      METHODS = %i[get post put patch delete].freeze

      def tag_name
        "span"
      end

      def build(options = {})
        options = options.dup
        url = options.delete(:url)
        mask = options.delete(:mask) || "••••••••"
        method = (options.delete(:method) || :get).to_s.downcase.to_sym
        raise ArgumentError, "secret_reveal needs url:" if url.blank?
        raise ArgumentError, "secret_reveal method must be one of #{METHODS.join(", ")}, got #{method.inspect}" unless METHODS.include?(method)

        super(options)
        add_class "aat-secret-reveal"
        set_attribute "data-aat-secret-reveal", ""
        set_attribute "data-url", url
        set_attribute "data-method", method.to_s.upcase
        set_attribute "data-mask", mask
        button(mask, type: "button", class: "aat-secret-reveal-toggle", title: "Click to reveal")
        span("", class: "aat-secret-reveal-error", role: "alert", hidden: true)
      end
    end
  end
end
