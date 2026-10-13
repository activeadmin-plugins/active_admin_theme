// Server clock for the utility navigation. Shows the server's time ticking once
// a second in li#servertime inside #utility_nav, where the stylesheet styles it.
//
// The instant comes from a [data-servertime] element the host app renders — the
// body in some apps, a footer element in others — holding
// "YYYY MM DD HH MM SS ZONE" (space-separated, exactly what Ruby's
// Time#strftime('%Y %m %d %H %M %S %Z') produces). The clock keeps that server
// instant and advances it by the client's own elapsed time, so a skewed browser
// clock does not throw it off. With no such element it renders nothing: a
// fabricated client clock would bypass every server-side suppression (anonymous
// visitors, hosts without current_user, consumer opt-outs) and show browser
// time masquerading as the server clock.
//
// Vanilla, no deps, mounts itself into #utility_nav. Turbo/Turbolinks swap the
// body without firing DOMContentLoaded, so the clock re-reads the fresh
// [data-servertime] on their load events and re-queries the DOM every tick
// instead of holding node references — a held reference goes detached on the
// first navigation and the visible clock freezes.
(function () {
  "use strict";

  var serverTime, clientTime, zone, fmt;
  var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  function pad2(n) {
    return (n < 10 ? "0" : "") + n;
  }

  function ready(fn) {
    if (document.readyState !== "loading") fn();
    else document.addEventListener("DOMContentLoaded", fn);
  }

  // (Re)read the server instant from the current document.
  function sync() {
    // Prefer the theme's own span inside the nav: a host mid-migration may
    // still render its old body[data-servertime] (possibly in another format),
    // which would win on first-match-in-tree-order and shadow the fresh
    // per-request instant. Fall back to anywhere in the document for hosts
    // that only render the attribute on the body or a footer element.
    var nav = document.getElementById("utility_nav");
    var source = (nav && nav.querySelector("[data-servertime]")) ||
                 document.querySelector("[data-servertime]");

    // Preferred source: an absolute instant plus the server's IANA zone
    // (rendered by the gem's Ruby backend). Intl re-applies the zone's offset
    // on every tick, so a long-lived page follows the server through its own
    // DST transitions — the wall-clock path below keeps the offset and label
    // frozen from page load.
    fmt = null;
    serverTime = undefined; // no source on this page: tick() renders nothing
    var epoch = source && source.getAttribute("data-servertime-epoch");
    var tz = source && source.getAttribute("data-servertime-zone");
    if (epoch && tz && window.Intl &&
        Intl.DateTimeFormat.prototype.formatToParts) {
      try {
        fmt = new Intl.DateTimeFormat("en-US", {
          timeZone: tz, hour12: false, hourCycle: "h23",
          year: "numeric", month: "short", day: "2-digit",
          hour: "2-digit", minute: "2-digit", second: "2-digit",
          timeZoneName: "short"
        });
        serverTime = epoch * 1000;
        // A malformed epoch is truthy but NaN; formatToParts(new Date(NaN))
        // would throw on every tick. Drop to the wall-clock path instead.
        if (!isFinite(serverTime)) fmt = null;
      } catch (e) {
        fmt = null; // unknown zone name: fall through to the wall-clock path
      }
    }

    var raw = !fmt && source && source.getAttribute("data-servertime");

    if (raw) {
      var bits = raw.split(" ");
      // A fixed epoch via Date.UTC, NOT new Date(y,m,d,...): local-zone
      // parsing shifts a server instant that falls into the client's DST gap,
      // and a tab left open across a client transition jumps the display an
      // hour while the server had none. The zone label is carried verbatim.
      serverTime = Date.UTC(bits[0], bits[1] - 1, bits[2], bits[3], bits[4], bits[5]);
      // No fabricated label: a missing %Z just renders no zone.
      zone = bits[6] || "";
    }
    clientTime = Date.now();
    tick();
  }

  // The two display lines for this li, created on first use and reused every
  // later tick. The server-rendered inner span [data-servertime] is the data
  // source for later sync() calls (turbo:load, bfcache restores) — never
  // overwrite it; hide it and append the lines beside it. textContent only,
  // no innerHTML: the zone token of a host-rendered attribute is untrusted
  // text and must not be able to become markup — and skipping the per-second
  // innerHTML re-parse stops the node churn too.
  function lines(li) {
    var time = li.querySelector(".clock-time");
    if (time) return { time: time, date: li.querySelector(".clock-date") };
    var data = li.querySelector("[data-servertime]");
    // Append target: the outer Arbre span when the gem rendered the item, the
    // li's own span otherwise. No inline colour — the span inherits the nav's
    // text colour from the stylesheet cascade.
    var host = data ? data.parentNode : li.querySelector("span");
    if (!host) {
      host = document.createElement("span");
      li.appendChild(host);
    }
    if (data) data.style.display = "none";
    time = document.createElement("span");
    time.className = "clock-time";
    var date = document.createElement("span");
    date.className = "clock-date";
    host.appendChild(time);
    host.appendChild(date);
    return { time: time, date: date };
  }

  function tick() {
    var nav = document.getElementById("utility_nav");
    // isFinite, not an undefined check: a host-rendered data-servertime in an
    // unexpected format parses to NaN, which must render nothing — not a
    // ticking "NaN:NaN:NaN".
    if (!nav || !isFinite(serverTime)) return;

    // Reuse an existing li (idempotent across re-renders); never duplicate.
    var li = nav.querySelector("#servertime");
    if (!li) {
      li = document.createElement("li");
      li.id = "servertime";
      // Mark it as ours, so the ownership check below keeps passing.
      li.setAttribute("data-theme-clock", "");
      nav.appendChild(li);
    } else if (!li.hasAttribute("data-theme-clock") &&
               !li.querySelector("[data-servertime]")) {
      // The li belongs to the host — their own servertime menu item, e.g.
      // rendered as a plain link. Appending display lines would show the
      // host's label and a second clock side by side in one item.
      return;
    }
    var out = lines(li);

    // Two lines, as in yeti-web: time + timezone on top (larger), year month
    // day below (smaller). The stylesheet sizes .clock-time / .clock-date.
    var now = new Date(serverTime + (Date.now() - clientTime));
    var time, date;
    if (fmt) {
      // serverTime is an absolute instant; Intl renders it in the server's
      // zone, offset and abbreviation recomputed per tick.
      var p = {};
      fmt.formatToParts(now).forEach(function (part) { p[part.type] = part.value; });
      time = p.hour + ":" + p.minute + ":" + p.second + " " + p.timeZoneName;
      date = p.year + " " + p.month + " " + p.day;
    } else {
      // UTC getters only — serverTime is a fixed epoch holding a wall clock,
      // so the client's zone and DST rules never touch the math.
      time = pad2(now.getUTCHours()) + ":" + pad2(now.getUTCMinutes()) + ":" +
             pad2(now.getUTCSeconds()) + (zone ? " " + zone : "");
      date = now.getUTCFullYear() + " " + MONTHS[now.getUTCMonth()] + " " +
             pad2(now.getUTCDate());
    }
    out.time.textContent = time;
    out.date.textContent = date;
  }

  ready(function () {
    sync();
    setInterval(tick, 1000);
  });
  document.addEventListener("turbo:load", sync);
  document.addEventListener("turbolinks:load", sync);
})();
