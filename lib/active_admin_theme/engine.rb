module ActiveAdminTheme
  class Engine < ::Rails::Engine
    # ActiveAdmin releases without the layout hooks from activeadmin/activeadmin#9149
    # and #9150 get full copies of the views that render those hooks.
    paths["app/views"] << "app/views_compat" unless ActiveAdminTheme.layout_hooks?

    # ActiveAdmin keeps its own importmap (ActiveAdmin.importmap) and renders
    # it in the layout, so the theme's modules are pinned there. A host with no
    # importmap-rails has no such config; it imports the npm package instead.
    initializer "active_admin_theme.importmap", after: "active_admin.importmap" do |app|
      next unless app.config.respond_to?(:importmap)

      ActiveAdmin.importmap.draw(root.join("config", "importmap.rb"))
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/javascript")
        app.config.assets.paths << root.join("vendor/javascript")
      end

      if ActiveAdmin.application.respond_to?(:importmap_watches)
        ActiveAdmin.application.importmap_watches << root.join("app/javascript")
      elsif app.config.importmap.sweep_cache
        # Without importmap_watches (activeadmin/activeadmin#9153) each
        # cache_sweeper(watches:) call replaces the watcher, so rebuild
        # ActiveAdmin's with both directories.
        watches = [ActiveAdmin::Engine.root.join("app/javascript"), root.join("app/javascript")].map(&:to_s)
        app.config.after_initialize { ActiveAdmin.importmap.cache_sweeper(watches: watches) }
      end
    end

    # Host initializers edit ActiveAdminTheme.javascripts, so read it once they
    # have run. Without javascript_modules (activeadmin/activeadmin#9148) the
    # compat _html_head imports the list itself.
    config.after_initialize do
      if ActiveAdmin.application.respond_to?(:javascript_modules)
        ActiveAdmin.application.javascript_modules |= ActiveAdminTheme.javascripts
      end
    end

    # Before any host initializer, so a host that defines its own
    # searchable_select_options includes it later and wins.
    initializer "active_admin_theme.resource_dsl" do
      require "active_admin_theme/resource_dsl/searchable_select"
    end

    # Before any resource registers its menu item.
    initializer "active_admin_theme.nested_menu" do
      require "active_admin_theme/nested_menu"
    end

    rake_tasks do
      load File.expand_path("../tasks/active_admin_theme.rake", __dir__)
    end

    # Arbre's builder_method defines a method on a shared module, so a host
    # component with the same builder_method name replaces the theme's if it
    # loads later. The engine's to_prepare callback is registered before the
    # host's, so the host's loads later.
    config.to_prepare do
      # Every file under views/ and inputs/ defines Arbre components or
      # formtastic inputs; loading them here keeps their builder methods in
      # place before any resource registers.
      %w[views inputs].each do |dir|
        Dir[File.expand_path("#{dir}/*.rb", __dir__)].sort.each { |file| require file }
      end
    end
  end
end
