# Migrating from theme 3 to theme 4

Theme 4 is a rework for ActiveAdmin 4. ActiveAdmin 4 replaced SCSS and Sprockets with Tailwind CSS 4, ERB partials, and import maps, so theme 3 cannot run on it. On screen the result looks almost the same. In your app, a few things change.

Upgrade ActiveAdmin first, and follow ActiveAdmin's own [upgrade guide](https://github.com/activeadmin/activeadmin/blob/master/UPGRADING.md). Then switch the theme. Theme 3.x stays on the `3.x` branch and keeps getting bug fixes.

## Checklist

1. In the `Gemfile`, set `gem "active_admin_theme", "~> 4.0"` and `activeadmin` to 4.0 or newer. Ruby 3.3 or newer is required.
2. Remove the theme 3 lines from your stylesheet and script manifests:
   - `@import "wigu/active_admin_theme";` and any `$skin*` variable assignments
   - `//= require wigu/all` (or the individual `wigu/*` files)
3. Add the theme CSS to your Tailwind entry file and the gem's files to the Tailwind `content` globs. See the README, "CSS". If you use the gem route, run `bin/rails active_admin_theme:css` in your build and git-ignore the generated file.
4. Move your color settings from Sass variables to CSS custom properties (below).
5. Replace anything that relied on the utility navigation (below).
6. Remove calls to ActiveAdmin 3 DSL that ActiveAdmin 4 dropped (below).
7. Check your own scripts: ActiveAdmin 4 has no jQuery.

## Colors: `$skin*` variables are now `--aat-*` properties

Sass variables are gone. Set CSS custom properties instead, light on `:root` and dark under `.dark`:

| Theme 3 variable | Theme 4 property |
| --- | --- |
| `$skinPageBgColor` / `$skinPageBgColorDark` | `--aat-page-bg` |
| `$skinSurfaceColor` | `--aat-surface` |
| `$skinSurface2Color` | `--aat-surface-2` |
| `$skinSurfaceHoverColor` | `--aat-surface-hover` |
| `$skinSelectedRowColor` | `--aat-selected-row` |
| `$skinTextColor`, `$skinTextMutedColor` | `--aat-text`, `--aat-text-muted` |
| `$skinBorderColor` | `--aat-border` |
| `$skinInputBgColor`, `$skinInputBorderColor` | `--aat-input-bg`, `--aat-input-border` |
| `$skinMainSecondColor` (accent) | `--aat-accent` |
| `$skinLinkColor` | `--aat-link` |
| `$skinButtonColor`, `$skinButtonTextColor` | `--aat-button`, `--aat-button-text` |
| `$skinMainFirstColor` (header) | `--aat-header-bg` |
| `$skinMenu*` | `--aat-menu-*` |

Sizing variables (header padding, title bar height, and so on) are not ported. Override the Tailwind classes in the partials, or copy the partial into your app.

## Utility navigation, server clock, and logout

ActiveAdmin 4 removed `build_menu :utility_navigation` and `add_logout_button_to_menu`. The theme now renders the server clock, the current user, and the logout icon in its header partial, so you no longer add them:

- Delete any `ActiveAdminTheme.add_current_user = false` line. To hide the user or the clock, override `app/views/active_admin/_site_header.html.erb`.
- Delete any items you added to the `:utility_navigation` menu. Put the content in the header partial instead.
- Logout still follows `config.logout_link_path`; set it to `nil` to remove the icon.

## JavaScript

- The theme loads as ES modules through `ActiveAdmin.importmap`, not through Sprockets. A pin in your own `config/importmap.rb` does not load on ActiveAdmin pages; pin your scripts into `ActiveAdmin.importmap` (README, "JavaScript").
- `theme_toggle.js` is gone. The header uses ActiveAdmin 4's dark mode switch.
- `scrollbar_width.js` is gone. The header no longer uses `100vw`, so it is not needed.
- `table_crisscross.js` is rewritten without jQuery as `active_admin_theme/table_crisscross`, and loads by default. The `td.selected` marker is now `td[data-selected]`.
- `server_clock.js` is rewritten as `active_admin_theme/server_clock`. It reads `data-servertime-epoch` and `data-servertime-zone` from `[data-server-clock]`; the old `data-servertime` wall-clock format is not supported.

## DSL

| Theme 3 / ActiveAdmin 3 | Theme 4 |
| --- | --- |
| `columns` / `column` | Restored by the theme, with a ratio string and a `mobile:` option. `column span: N` still works. |
| `tabs` / `tab` | Restored by the theme. |
| `panel` around `sidebar` and show `attributes_table` | Restored by the theme. |
| `Panel#header_action` | Removed. |
| `dropdown_menu` in action items | Removed by ActiveAdmin 4. |
| `index_as_blog`, `index_as_block`, `index_as_grid`, `index_column` | Removed by ActiveAdmin 4. |
| Sortable has-many forms | Removed by ActiveAdmin 4. |

Extensions that depend on ActiveAdmin 3 internals (calendar, table footer, and others) are not part of this gem and may block your migration.

## Not ported

- Trix and ActionText theming.
- Pinned bars and sticky table headers.
- The `$skin*` sizing variables.

Open an issue if you need one of these.
