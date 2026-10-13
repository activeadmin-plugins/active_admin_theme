ActiveAdmin.setup do |config|
  config.site_title = "ActiveAdmin Theme Demo"

  # No devise / no auth: the dummy exists only to render a themed page.
  config.authentication_method = false
  config.current_user_method = false
  config.logout_link_path = "/admin"

  # No ActiveRecord-backed comments, so the app needs no schema.
  config.comments = false
end

# Auth is off (no login wall), but the theme's logout item is guarded by AA's
# `current_active_admin_user?`, which is false with current_user_method = false.
# Stub it true in the dummy so the theme-added li#logout actually renders — the
# whole point being to show the clock and logout sitting together in the nav.
Rails.application.config.to_prepare do
  ActiveAdmin::BaseController.class_eval do
    def current_active_admin_user?
      true
    end
  end
end
