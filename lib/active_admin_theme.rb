# ActiveAdmin first: Rails prepends each engine's view path in the order the
# engine classes are defined, so the theme's partials win over ActiveAdmin's
# only when ActiveAdmin::Engine is defined before ActiveAdminTheme::Engine.
require "active_admin"
require "active_admin_theme/version"
require "active_admin_theme/engine"

module ActiveAdminTheme
  # ES modules the layout imports after ActiveAdmin's own entry point. Edit the
  # list in an initializer to load fewer scripts or to add the opt-in ones:
  #   ActiveAdminTheme.javascripts -= %w[active_admin_theme/table_crisscross]
  DEFAULT_JAVASCRIPTS = %w[
    active_admin_theme/layout
    active_admin_theme/server_clock
    active_admin_theme/table_crisscross
  ].freeze

  class << self
    attr_writer :javascripts

    def javascripts
      @javascripts ||= DEFAULT_JAVASCRIPTS.dup
    end
  end
end
