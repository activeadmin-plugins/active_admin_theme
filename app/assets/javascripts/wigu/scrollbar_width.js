// Expose the vertical scrollbar width as a CSS custom property
// (--scrollbar-width) on <html>. The sticky #header and #title_bar are pinned to
// the viewport's left edge and sized with 100vw, but 100vw INCLUDES the vertical
// scrollbar gutter — so when a page has a vertical scrollbar the bars are ~15px
// wider than the visible viewport and, clamped inside their full-content-width
// containing block, get pushed left by that amount at the far-right horizontal
// scroll position. Subtracting this variable (0 when there is no scrollbar) sizes
// them to the visible viewport instead, so they stay put. Optional: the CSS falls
// back to `var(--scrollbar-width, 0px)` = plain 100vw when this script is absent.
//
// The property name is deliberately the bare --scrollbar-width, not --aa-*:
// consumer apps that already set the same variable with the same semantics from
// their own legacy script keep working before their manifest is updated, and
// the theme's CSS picks up either writer. The trade-off is a shared name — an
// app using --scrollbar-width for something else will collide with this
// script's inline writes on <html>; load one writer, not both.
(function () {
  var last;
  function update() {
    var w = window.innerWidth - document.documentElement.clientWidth;
    if (w < 0) w = 0;
    // The value only changes when the scrollbar toggles, but the callers fire
    // constantly (resize + ResizeObserver both hit during a drag-resize, and
    // every content growth pings the observer). Skip same-value writes: the
    // property feeds width: calc(...) of the pinned bars, and redundant inline
    // style writes on <html> are restyle churn.
    if (w === last) return;
    last = w;
    document.documentElement.style.setProperty("--scrollbar-width", w + "px");
  }
  window.addEventListener("resize", update);
  // The presence of a vertical scrollbar can change after load (content grows/
  // shrinks) without firing resize. Observe the root element, not <body>:
  // documentElement exists at parse time (no DOMContentLoaded gate, so
  // deferred/async loading works) and survives Turbo/Turbolinks body swaps,
  // where a body observer would keep watching a detached node. Content growth
  // resizes the root's client box too — exactly when the scrollbar toggles.
  if (window.ResizeObserver) {
    new ResizeObserver(update).observe(document.documentElement);
  }
  update();
})();
