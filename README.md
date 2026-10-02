# ActiveAdminTheme

Custom ActiveAdmin templates


## Installation
As active_skin is the css theme for the [activeadmin](https://github.com/activeadmin/activeadmin) administration framework - you have to install if first.

#### As a Gem
Having active admin installed add the following line to your application's Gemfile:


```ruby
gem 'active_admin_theme'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_admin_theme

#### As a NPM module (Yarn package)
Execute:

    $ npm i @activeadmin-plugins/active_admin_theme

Or

    $ yarn add @activeadmin-plugins/active_admin_theme

Or add manually to `package.json`:

```
"dependencies": {
  "@activeadmin-plugins/active_admin_theme": "^2.0.0"
}
```
and execute:

    $ yarn

## Usage

In your base stylesheet entry point `active_admin.scss` (as example), add line:

#### As a Gem via Sprockets
```css
@import 'wigu/active_admin_theme';
```

#### As a NPM module (Yarn package) via Webpacker or any other assets bundler

```css
@import '@activeadmin-plugins/active_admin_theme';
```

## Customising

Set any of the variables below *above* the import line:

```scss
$skinMainFirstColor: #A5A7AA;
$skinMainSecondColor: #0066CC;
$skinBorderWindowColor: #B8BABE;

@import 'wigu/active_admin_theme';
```

Variables are typed. A value of the wrong kind — `none` where a colour is
expected, or a length without its unit — fails the build with a message
naming the variable, instead of silently emitting CSS the browser discards.

### Dark mode

The theme follows the operating system via `prefers-color-scheme`, and can be
pinned per page with `data-theme="light"` or `data-theme="dark"` on `<html>`.
Every colour below that has a `…Dark` twin is what dark mode uses; each twin
defaults to its light counterpart unless noted, so a project that only sets
the light value keeps one consistent colour in both modes.

### A worked example

The defaults are the configuration this theme is run with in
[yeti-web](https://github.com/yeti-switch/yeti-web). To go back to the blue
header the theme shipped before:

```scss
$skinMenuPillColor:          $skinMainSecondColor;
$skinMenuPanelColor:         $skinMainSecondColor;
$skinMenuTextColor:          #ffffff;
$skinMenuItemHoverColor:     transparent;
$skinMenuItemHoverTextColor: #ffffff;
$skinMenuFontSize:           1em;
$skinHeaderPaddingY:         null;      // 5px top / 9px bottom, as before
$skinTitleBarColor:          lighten($skinMainFirstColor, 8%);
$skinTitleBarBorderWidth:    3px;
$skinPanelHeaderColor:       $skinMainSecondColor;
$skinPanelHeaderTextColor:   #ffffff;
$skinTabInactiveColor:       $skinMainSecondColor;
$skinInactiveTabTextColor:   #ffffff;
$skinLinkColor:              $skinMainSecondColor;

@import 'wigu/active_admin_theme';
```

Note `var(--aa-page-bg)` works as a variable value: a custom property follows
the mode on its own, so one line covers both themes.

### Switching themes

Out of the box the theme follows the operating system. It also honours
`data-theme="light"` or `data-theme="dark"` on `<html>`, which is all a switch
needs — the gem ships CSS only and deliberately no JavaScript, because where
the control belongs is a decision per application.

This is the whole of it. Put it in your admin JS; it adds an entry to the
utility navigation and remembers the choice:

```js
// Theme switch for active_admin_theme. Drop into your admin JS.
(function () {
  var KEY = "aa-theme", root = document.documentElement;

  // Apply the stored choice as early as possible — if this runs after paint the
  // page flashes the other theme first.
  var saved = localStorage.getItem(KEY);
  if (saved) root.setAttribute("data-theme", saved);

  function isDark() {
    var set = root.getAttribute("data-theme");
    if (set) return set === "dark";
    return window.matchMedia("(prefers-color-scheme: dark)").matches;
  }

  document.addEventListener("DOMContentLoaded", function () {
    var nav = document.getElementById("utility_nav");
    if (!nav) return;

    var li = document.createElement("li"), a = document.createElement("a");
    a.href = "#";
    a.id = "theme_toggle";
    function label() { a.textContent = isDark() ? "Light mode" : "Dark mode"; }

    a.addEventListener("click", function (event) {
      event.preventDefault();
      var next = isDark() ? "light" : "dark";
      root.setAttribute("data-theme", next);
      localStorage.setItem(KEY, next);
      label();
    });

    label();
    li.appendChild(a);
    nav.insertBefore(li, nav.firstChild);
  });
})();
```

Two things worth keeping if you rewrite it: read `localStorage` **before**
`DOMContentLoaded`, or the page paints in the other theme first and flashes;
and with no attribute set, fall back to `prefers-color-scheme` rather than
assuming light, so the label matches what the user is actually looking at.

### Upgrading

Two things changed shape in this release and are worth knowing if you already
set variables:

* Dropdown panels — the title-bar menu, the batch-actions menu and the
  table-tools menus — now follow the surface palette (`$skinSurfaceColor` and
  friends) instead of `$skinMainFirstColor` / `$skinMainSecondColor`. That is
  what lets them work in both modes. If you branded those panels through the
  two main colours, point `$skinSurfaceColor` and `$skinSurfaceHoverColor` at
  the same values.
* The default content link colour is darker (`#1f5f8d` rather than the accent).
  The accent is a fill colour and failed WCAG AA as body text. Set
  `$skinLinkColor` back to `$skinMainSecondColor` if you prefer the old look.

### Variables

#### Core

| Variable | Default (light / dark) | |
|---|---|---|
| `$skinMainFirstColor` | `#23282f` |  |
| `$skinMainSecondColor` | `#5ea3d3` |  |
| `$skinBorderRadius` | `4px` |  |
| `$skinBorderWindowColor` | `#e6e9ee` |  |
| `$skinTablePadding` | `10px` |  |

#### Surfaces, text and borders

| Variable | Default (light / dark) | |
|---|---|---|
| `$skinPageBgColor` / `$skinPageBgColorDark` | `#f7f9fb` / `#161a1e` | page background |
| `$skinSurfaceColor` / `$skinSurfaceColorDark` | `#ffffff` / `#25292f` | panels / cards / content |
| `$skinSurface2Color` / `$skinSurface2ColorDark` | `#f0f2f5` / `#2c3137` | table headers / striping / subtle fills |
| `$skinSurfaceHoverColor` / `$skinSurfaceHoverColorDark` | `#f5f7fa` / `#3f454d` | row / item hover |
| `$skinSelectedRowColor` / `$skinSelectedRowColorDark` | `#d9e4ec` / `#304457` | checked table row |
| `$skinElevatedColor` / `$skinElevatedColorDark` | `$skinSurfaceColor` / `#3f454d` | tool buttons and dropdown panels floating above the page |
| `$skinTextColor` / `$skinTextColorDark` | `#323537` / `#dde2e8` | body text |
| `$skinTextMutedColor` / `$skinTextMutedColorDark` | `#6b7177` / `#b0b8c2` | secondary text / axis labels |
| `$skinBorderColor` / `$skinBorderColorDark` | `#e0e4e9` / `#404750` | borders / grid lines |
| `$skinInputBgColor` / `$skinInputBgColorDark` | `#ffffff` / `#2c3137` | form control background |
| `$skinInputBorderColor` / `$skinInputBorderColorDark` | `#c9ced4` / `#4d555f` | form control border |

#### Header menu

| Variable | Default (light / dark) | |
|---|---|---|
| `$skinMenuPillColor` | `$skinMainSecondColor` | top-level current/hover pill |
| `$skinMenuPillTextColor` | `$skinMenuTextColor` | text on that pill; follows the dropdown text so a |
| `$skinMenuPanelColor` | `$skinMainSecondColor` | dropdown panel bg + hover "bridge" border |
| `$skinMenuTextColor` | `#ffffff` | dropdown item text (was: inherited #fff) |
| `$skinMenuItemHoverColor` | `transparent` | dropdown item hover/current bg (was: none) |
| `$skinMenuItemHoverTextColor` | `$skinMenuTextColor` | hover/current dropdown item text, same reason |
| `$skinMenuFontSize` | `1em` | header menu text size |
| `$skinMenuItemPaddingY` | `8px` | dropdown item top/bottom padding (was 6px/4px + a 7px border) |
| `$skinMenuItemLineHeight` | `1.5` | dropdown item line-height |
| `$skinMenuPanelMaxWidth` | `260px` | dropdown panel ceiling; longer labels wrap instead of leaving the viewport |
| `$skinHeaderPaddingY` | `null` | sets both halves at once |
| `$skinHeaderPaddingTop` | `5px` | header top padding (base value, kept so the header does not shift) |
| `$skinHeaderPaddingBottom` | `9px` | header bottom padding |
| `$skinHeaderLogoMaxHeight` | `none` | cap the site_title logo image height |

#### Title bar

| Variable | Default (light / dark) | |
|---|---|---|
| `$skinTitleBarColor` | `lighten($skinMainFirstColor, 8%)` |  |
| `$skinTitleBarBorderColor` | `$skinMainSecondColor` |  |
| `$skinTitleBarBorderWidth` | `3px` |  |
| `$skinTitleBarButtonPaddingY` | `10px` | action button vertical padding |
| `$skinTitleBarButtonPaddingX` | `20px` | action button horizontal padding |

#### Panels, tabs and labels

| Variable | Default (light / dark) | |
|---|---|---|
| `$skinPanelHeaderColor` / `$skinPanelHeaderColorDark` | `$skinMainSecondColor` / `$skinPanelHeaderColor` |  |
| `$skinPanelHeaderTextColor` / `$skinPanelHeaderTextColorDark` | `#ffffff` / `$skinPanelHeaderTextColor` |  |
| `$skinPanelHeaderPaddingY` | `8px` | panel + sidebar header height |
| `$skinLabelColor` / `$skinLabelColorDark` | `#8494a8` / `$skinTextColorDark` |  |
| `$skinTabInactiveColor` / `$skinTabInactiveColorDark` | `$skinPanelHeaderColor` / `$skinPanelHeaderColorDark` | inactive tab fill |
| `$skinActiveTabTextColor` / `$skinActiveTabTextColorDark` | `$skinLinkColor` / `$skinLinkColorDark` | selected tab label |
| `$skinInactiveTabTextColor` / `$skinInactiveTabTextColorDark` | `$skinPanelHeaderTextColor` / `$skinInactiveTabTextColor` | inactive tab label |
| `$skinTableHeaderTextColor` / `$skinTableHeaderTextColorDark` | `#5e6469` / `#dde2e8` | index-table column header text |
| `$skinTabPaddingY` | `10px` | tab height |
| `$skinTabPaddingX` | `20px` | tab label horizontal padding (text → border) |

#### Buttons and table tools

| Variable | Default (light / dark) | |
|---|---|---|
| `$skinButtonColor` / `$skinButtonColorDark` | `$skinMainSecondColor` / `darken($skinButtonColor, 20%)` | darker in dark mode so a white label clears 4.5:1 |
| `$skinButtonTextColor` / `$skinButtonTextColorDark` | `#ffffff` / `$skinButtonTextColor` | label on those buttons |
| `$skinTableToolsHeight` | `30px` |  |
| `$skinTableToolsPaddingX` | `$skinTableToolsHeight * 0.4` | 12px at 30px |

#### Links

| Variable | Default (light / dark) | |
|---|---|---|
| `$skinAccentColor` / `$skinAccentColorDark` | `$skinMainSecondColor` / `$skinAccentColor` | focus ring / accent outline |
| `$skinLinkColor` / `$skinLinkColorDark` | `#1f5f8d` / `#7cc0ec` |  |
| `$skinDeleteLinkColor` / `$skinDeleteLinkColorDark` | `$skinLinkColor` / `#eb7b7b` |  |

## Screen

Index with filters, show page, nested `has_many` form, an open batch-actions
menu and the datepicker — the same admin in both modes. The theme follows the
operating system and can be pinned per page with `data-theme`.

#### Light

[![Light](./img/light.png)](./img/light.png)

#### Dark

[![Dark](./img/dark.png)](./img/dark.png)

## Contributing

1. Fork it ( https://github.com/activeadmin-plugins/active_admin_theme/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
