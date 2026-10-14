// Expose the vertical scrollbar width as a CSS custom property
// (--scrollbar-width) on the pinned bars. The sticky #header, #title_bar and
// .flashes are pinned to the viewport's left edge and sized with 100vw, but
// 100vw INCLUDES the vertical scrollbar gutter — so when a page has a vertical
// scrollbar the bars are ~15px wider than the visible viewport and, clamped
// inside their full-content-width containing block, get pushed left by that
// amount at the far-right horizontal scroll position. Subtracting this
// variable (0 when there is no scrollbar) sizes them to the visible viewport
// instead, so they stay put. Optional: the CSS falls back to
// `var(--scrollbar-width, 0px)` = plain 100vw when this script is absent.
//
// The value is written on the three consuming bars, NOT on <html>: a custom
// property changed on the root invalidates style for the entire document —
// one full recalc of a 500-row index table per write — while var() resolves
// from the element itself just as well, confining invalidation to three tiny
// subtrees.
//
// The property name is deliberately the bare --scrollbar-width, not --aa-*:
// consumer apps that already set the same variable with the same semantics
// from their own legacy script keep working before their manifest is updated
// (a root-level legacy value still reaches the bars through inheritance when
// this script is absent). The trade-off is a shared name — load one writer,
// not both.
(function () {
  "use strict";

  var BARS = "#header, #title_bar, .flashes";
  var last = null;

  // Idempotent and cheap: reads the inline style (no layout) and writes only
  // real changes, so it is safe to call on every observer delivery — which is
  // what picks up bars parsed after the value was first computed, and bars
  // replaced by a Turbo/Turbolinks body swap.
  function apply() {
    if (last === null) return;
    var val = last + "px";
    var bars = document.querySelectorAll(BARS);
    for (var i = 0; i < bars.length; i++) {
      if (bars[i].style.getPropertyValue("--scrollbar-width") !== val) {
        bars[i].style.setProperty("--scrollbar-width", val);
      }
    }
  }

  function update() {
    var w = window.innerWidth - document.documentElement.clientWidth;
    if (w < 0) w = 0;
    last = w;
    apply();
  }

  if (window.ResizeObserver) {
    // The observer alone is enough: it delivers once right after observe()
    // (post-layout, pre-paint, so the read forces nothing) and again whenever
    // the root's client box changes — which covers window resizes AND content
    // growth toggling the scrollbar. A resize listener on top of it would
    // force a synchronous style+layout per event during a window drag (the
    // clientWidth read lands before the frame's layout) for no extra
    // information. documentElement exists at parse time and survives body
    // swaps, so there is no DOMContentLoaded gate and nothing goes stale.
    new ResizeObserver(update).observe(document.documentElement);
  } else {
    // No ResizeObserver: fall back to resize events plus one eager read.
    window.addEventListener("resize", update);
    update();
  }
  // A body swap replaces the bars the value was written on without
  // necessarily resizing the root; re-apply the cached value to the fresh
  // elements.
  document.addEventListener("turbo:load", apply);
  document.addEventListener("turbolinks:load", apply);
})();
