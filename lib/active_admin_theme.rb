require "active_admin_theme/version"

module ActiveAdminTheme
  module Rails
    class Engine < ::Rails::Engine
      # Register the server clock once AA is available. server_clock.js (shipped
      # in this gem) ticks li#servertime in #utility_nav and reads the server
      # instant from [data-servertime]; here we render both server-side, per
      # namespace, so every consumer gets the clock without reimplementing it.
      # after :load_config_initializers, or hosts loading AA from a config
      # initializer (gem "activeadmin", require: false) fail the defined?
      # check and silently get no clock — engine initializers otherwise run
      # before the host's config/initializers.
      initializer "active_admin_theme.server_clock", after: :load_config_initializers do
        if defined?(::ActiveAdmin)
          ActiveAdminTheme.install!
        else
          # Evaluated once; a host requiring activeadmin even later (routes.rb,
          # an ENV-gated engine) gets no theme at all — say so instead of
          # silently shipping a README-promised feature that never appears.
          ::Rails.logger&.warn(
            "active_admin_theme: ActiveAdmin was not loaded when the engine " \
            "initialized; the utility-nav clock and logout handling are " \
            "disabled. Require \"active_admin\" no later than config/initializers."
          )
        end
      end
    end
  end

  # Opt-out for the restored current-user item. Unlike logout (which AA turns
  # off per namespace via logout_link_path = nil), AA has no switch short of
  # unsetting current_user_method — which also breaks authorization — and
  # Menu has no removal API, so hosts that deliberately run a user-link-free
  # header (e.g. display_name would leak an email) set this in an initializer:
  # ActiveAdminTheme.add_current_user = false
  class << self
    attr_accessor :add_current_user
  end
  self.add_current_user = true

  # Add a utility-nav clock item (and ensure a logout item) to every AA namespace.
  #
  # data-servertime must be fresh on every request, but only a menu item's
  # :label/:url/:if are evaluated per request — :html_options is captured once at
  # build time. So the instant is embedded in the label as html_safe markup
  # rather than an html_option. The label is "YYYY MM DD HH MM SS ZONE" (exactly
  # what server_clock.js parses) on an inner span; the JS overwrites the visible
  # text each tick. Timezone comes from the host app's Time.current/Time.zone.
  def self.install!
    # after_load fires on every ActiveAdmin.load! (each dev reload), and each
    # build_menu call registers a before_build callback that MenuCollection#clear!
    # never removes — so register once per namespace or callbacks pile up for
    # the life of the process. Namespace objects and their MenuCollection
    # survive unload! (it only clears the built menus), so once is enough.
    seen = {}.compare_by_identity
    register = lambda do |namespace|
      next if seen[namespace]
      seen[namespace] = true
      namespace.build_menu(:utility_navigation) do |menu|
        # A consumer item with the same id wins, but NOT through these
        # guards: before_build unshifts, so the LAST registration runs
        # first, and consumer hooks (config/initializers) subscribe before
        # this engine's initializer — on a production first load THIS
        # callback runs first against an empty menu and the guards all
        # pass. What protects consumer overrides is Menu#_add replacing by
        # id when their callback runs afterwards. The guards only matter
        # from the second dev reload on, when consumer items are already
        # present — do not tighten them into the primary mechanism.
        unless menu["servertime"]
          menu.add id: "servertime",
                   priority: 99_990,
                   url: -> {},
                   # same guard both default utility items carry — the nav
                   # stays empty for anonymous visitors, as it was pre-theme
                   if: :current_active_admin_user?,
                   label: lambda {
                     now = Time.current
                     data = now.strftime("%Y %m %d %H %M %S %Z")
                     shown = now.strftime("%Y %b %d %H:%M:%S %Z")
                     # epoch + IANA zone let the JS re-apply the server
                     # zone's offset on every tick (DST included); the
                     # wall-clock attribute stays as the documented contract
                     # for host-rendered elements and older scripts.
                     # Time.zone is nil under Time.use_zone(nil) — the
                     # common around_action(user.time_zone) pattern with a
                     # nil column — while Time.current still works; skip the
                     # precise attributes then instead of 500ing the page.
                     tz = Time.zone
                     precise = tz ? %( data-servertime-epoch="#{now.to_i}" data-servertime-zone="#{tz.tzinfo.identifier}") : ""
                     %(<span data-servertime="#{data}"#{precise}>#{shown}</span>).html_safe
                   }
        end
        # Claiming :utility_navigation stops AA's build_default_utility_nav
        # (it returns early once the menu exists), so restore the default
        # current-user item it would have added. No-op when the host has no
        # current_user_method, exactly like the default nav.
        if ActiveAdminTheme.add_current_user && !menu["current_user"]
          namespace.add_current_user_to_menu(menu)
        end
        # Opting out is ActiveAdmin's own per-namespace switch, not a theme
        # flag: config.logout_link_path = nil makes add_logout_button_to_menu
        # a no-op (AA guards on `if logout_link_path`). Hosts with custom
        # auth and no logout route — where rendering the default item would
        # public_send a missing helper and 500 — set exactly that.
        # The wigu-logout class (lands on the <a> — AA passes html_options to
        # link_to) scopes the stylesheet's icon treatment to THIS item, so a
        # consumer-rendered logout with its own label keeps its text. The
        # aria-label is the accessible name: the stylesheet hides the link
        # text with font-size: 0, which some screen readers prune from the
        # accessibility tree. html_options are captured at menu-build time, so
        # the label uses the locale active then — good enough for a nav icon.
        unless menu["logout"]
          namespace.add_logout_button_to_menu(
            menu, 99_999,
            class: "wigu-logout", "aria-label": I18n.t("active_admin.logout")
          )
        end
      end
    end

    ::ActiveAdmin.after_load do |app|
      app.namespaces.each(&register)
    end
    # Production fires after_load exactly once (load! gates on @@loaded), so a
    # namespace created later — e.g. another engine's later-subscribed hook
    # registering a resource into a new namespace — would keep AA's stock
    # default nav, inconsistently with its siblings. Namespace creation has
    # its own notification; theme late arrivals through it.
    ActiveSupport::Notifications.subscribe(::ActiveAdmin::Namespace::RegisterEvent) do |*args|
      register.call(args.last[:active_admin_namespace])
    end
  end
end
