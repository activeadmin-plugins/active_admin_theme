// Theme switch for active_admin_theme. Optional — the stylesheet works without
// it, following the operating system.
//
// Cycles auto -> light -> dark -> auto:
//   auto        no stored choice; follows prefers-color-scheme, live
//   light/dark  pins html[data-theme] and remembers it
//
// Binds by delegation to anything carrying .dark-mode-toggle or #theme_toggle,
// the way ActiveAdmin 4 does, so the control can live anywhere and survive a
// re-render. If neither exists it appends its own entry to the utility
// navigation. No jQuery and no ujs, so it does not care how the admin is built.
(function () {
  "use strict";

  var KEY = "aa-theme";
  var ORDER = { auto: "light", light: "dark", dark: "auto" };
  var LABEL = { auto: "Theme: auto", light: "Theme: light", dark: "Theme: dark" };
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
      var link = host.tagName === "A" ? host : host.querySelector("a") || host;
      host.setAttribute("data-mode", current);
      link.setAttribute("title", LABEL[current] + " — click for " + ORDER[current]);
      link.setAttribute("aria-label", link.getAttribute("title"));
      // An application that renders its own control (an icon, say) keeps it.
      if (link.children.length === 0) link.textContent = LABEL[current];
    });
  }

  // Delegated, so a control added later — or replaced by a Turbo render — still
  // works without rebinding.
  document.addEventListener("click", function (event) {
    var target = event.target.closest && event.target.closest(SELECTOR);
    if (!target) return;
    event.preventDefault();
    store(ORDER[mode()] === "auto" ? null : ORDER[mode()]);
    apply();
    refresh();
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
      host.appendChild(document.createElement("a")).href = "#";
      nav.insertBefore(host, nav.firstChild);
    }
    refresh();
  });
})();
