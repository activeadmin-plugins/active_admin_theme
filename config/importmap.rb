# Pinned into ActiveAdmin.importmap (the map the AA layout renders), not into
# the host's own importmap. Not preloaded: a modulepreload of an opt-in module
# (searchable_select) also fetches its imports, so a host that skips the module
# would still load Tom Select.
pin_all_from File.expand_path("../app/javascript/active_admin_theme", __dir__), under: "active_admin_theme", preload: false

# Vendored Tom Select for active_admin_theme/searchable_select (the engine adds
# vendor/javascript to the asset paths).
pin "tom-select", preload: false
