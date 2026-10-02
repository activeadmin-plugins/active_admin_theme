// Theme switch for active_admin_theme. Optional — the stylesheet works without
// it, following the operating system.
//
// Cycles auto -> light -> dark -> auto:
//   auto        no stored choice; follows prefers-color-scheme, live
//   light/dark  pins html[data-theme] and remembers it
//
// Wires an existing #theme_toggle element if the application renders one (see
// the README for the ActiveAdmin menu item), otherwise appends its own entry to
// the utility navigation. No jQuery, so it does not care how the admin is built.
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

  ready(function () {
    var host = document.getElementById("theme_toggle");

    if (!host) {
      var nav = document.getElementById("utility_nav");
      if (!nav) return;
      host = document.createElement("li");
      host.id = "theme_toggle";
      host.appendChild(document.createElement("a")).href = "#";
      nav.insertBefore(host, nav.firstChild);
    }

    var link = host.tagName === "A" ? host : host.querySelector("a") || host;

    function refresh() {
      var current = mode();
      host.setAttribute("data-mode", current);
      link.setAttribute("title", LABEL[current] + " — click for " + ORDER[current]);
      link.setAttribute("aria-label", link.getAttribute("title"));
      if (!link.getAttribute("data-keep-label")) link.textContent = LABEL[current];
    }

    link.addEventListener("click", function (event) {
      event.preventDefault();
      var next = ORDER[mode()];
      store(next === "auto" ? null : next);
      apply();
      refresh();
    });

    refresh();

    // In auto mode, follow the operating system while the page is open.
    if (window.matchMedia) {
      var query = window.matchMedia("(prefers-color-scheme: dark)");
      var onChange = function () { if (mode() === "auto") { apply(); refresh(); } };
      if (query.addEventListener) query.addEventListener("change", onChange);
      else if (query.addListener) query.addListener(onChange);
    }
  });
})();
