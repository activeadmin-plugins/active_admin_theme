// Theme switch for active_admin_theme. Optional — the stylesheet works without
// it, following the operating system.
//
// Cycles auto -> light -> dark -> auto:
//   auto        no stored choice; follows prefers-color-scheme, live
//   light/dark  pins html[data-theme] and remembers it
//
// The only thing this writes to the page is data-mode on the control; the
// stylesheet draws the icon from it. That keeps appearance in the theme, where
// a project can restyle it, instead of in a script it would have to fork.
//
// Binds by delegation to anything carrying .dark-mode-toggle or #theme_toggle,
// the way ActiveAdmin 4 does, so the control can live anywhere and survive a
// re-render. If neither exists it appends its own entry to the utility
// navigation. No jQuery and no ujs, so it does not care how the admin is built.
(function () {
  "use strict";

  var KEY = "aa-theme";
  var ORDER = { auto: "light", light: "dark", dark: "auto" };
  var LABEL = {
    auto: "Theme: auto (follows the system) — click for light",
    light: "Theme: light — click for dark",
    dark: "Theme: dark — click for auto",
  };
  var root = document.documentElement;

  // localStorage throws in private mode in some browsers, and is absent in a few
  // embedded webviews. Losing the preference is acceptable; breaking the admin
  // is not.
  function stored() {
    try { return localStorage.getItem(KEY); } catch (e) { return null; }
  }
  function store(value) {
    try { value === null ? localStorage.removeItem(KEY) : localStorage.setItem(KEY, value); } catch (e) {}
  }

  function mode() {
    var value = stored();
    return value === "light" || value === "dark" ? value : "auto";
  }

  function apply() {
    // auto drops the attribute entirely so the media query decides.
    if (mode() === "auto") root.removeAttribute("data-theme");
    else root.setAttribute("data-theme", mode());
  }

  // Before DOMContentLoaded on purpose: applied later, the page paints in the
  // other theme first and flashes.
  apply();

  function ready(fn) {
    if (document.readyState !== "loading") fn();
    else document.addEventListener("DOMContentLoaded", fn);
  }

  var SELECTOR = ".dark-mode-toggle, #theme_toggle";

  function controls() {
    return document.querySelectorAll(SELECTOR);
  }

  function refresh() {
    var current = mode();
    Array.prototype.forEach.call(controls(), function (host) {
      // The host itself may be the anchor (a menu item) or wrap one (our own li).
      var link = host.tagName === "A" ? host : host.querySelector("a") || host;
      host.setAttribute("data-mode", current);
      link.setAttribute("title", LABEL[current]);
      link.setAttribute("aria-label", LABEL[current]);
    });
  }

  function cycle() {
    var next = ORDER[mode()];
    store(next === "auto" ? null : next);
    apply();
    refresh();
  }

  // Delegated, so a control added later — or replaced by a Turbo render — still
  // works without rebinding.
  document.addEventListener("click", function (event) {
    if (!event.target.closest || !event.target.closest(SELECTOR)) return;
    event.preventDefault();
    cycle();
  });

  // The control is a link with no destination, so it is reachable by Tab; that
  // makes Enter and Space its keyboard contract.
  document.addEventListener("keydown", function (event) {
    if (event.key !== "Enter" && event.key !== " ") return;
    if (!event.target.closest || !event.target.closest(SELECTOR)) return;
    event.preventDefault();
    cycle();
  });

  // Another tab changed the preference.
  window.addEventListener("storage", function (event) {
    if (event.key === KEY) { apply(); refresh(); }
  });

  // In auto mode, follow the operating system while the page is open.
  if (window.matchMedia) {
    var query = window.matchMedia("(prefers-color-scheme: dark)");
    var onChange = function () { if (mode() === "auto") { apply(); refresh(); } };
    if (query.addEventListener) query.addEventListener("change", onChange);
    else if (query.addListener) query.addListener(onChange);
  }

  ready(function () {
    if (controls().length === 0) {
      var nav = document.getElementById("utility_nav");
      if (!nav) return;
      var host = document.createElement("li");
      host.id = "theme_toggle";
      var link = host.appendChild(document.createElement("a"));
      // Not "#": ActiveAdmin treats a bare hash as a blank menu item.
      link.setAttribute("href", "#theme");
      link.setAttribute("role", "button");
      nav.insertBefore(host, nav.firstChild);
    }
    refresh();
  });
})();
