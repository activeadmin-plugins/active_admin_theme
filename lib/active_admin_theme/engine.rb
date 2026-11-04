module ActiveAdminTheme
  class Engine < ::Rails::Engine
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
