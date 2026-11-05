ActiveAdmin.setup do |config|
  config.site_title = "ActiveAdmin Theme Demo"

  # No devise: the dummy only renders themed pages. A fake signed-in user makes
  # the header show the clock, user name, and logout icon.
  config.authentication_method = false
  config.current_user_method = :current_admin_user
  config.logout_link_path = "/admin"

  # No ActiveRecord-backed comments, so the app needs no schema.
  config.comments = false
end

# The optional modules the demo pages use.
ActiveAdminTheme.javascripts += %w[
  active_admin_theme/confirm_dialog
  active_admin_theme/secret_reveal
  active_admin_theme/searchable_select
]
