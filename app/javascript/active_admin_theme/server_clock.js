// Server clock in the header. The layout renders [data-server-clock] with a
// [data-servertime] element holding the server's epoch seconds and IANA zone.
// The clock advances that instant by the browser's elapsed time, so a skewed
// browser clock does not move it, and formats it in the server's zone with
// Intl, so it follows the server through DST changes. Without the element
// (anonymous visitor, host-overridden header) it does nothing.
let serverTime = null
let clientTime = null
let format = null

const sync = () => {
  const source = document.querySelector("[data-server-clock] [data-servertime]")
  serverTime = null
  format = null
  if (!source) return
  const epoch = Number(source.dataset.servertimeEpoch)
  const zone = source.dataset.servertimeZone
  if (!Number.isFinite(epoch)) return
  try {
    format = new Intl.DateTimeFormat("en-US", {
      timeZone: zone || undefined, hourCycle: "h23",
      year: "numeric", month: "short", day: "2-digit",
      hour: "2-digit", minute: "2-digit", second: "2-digit",
      timeZoneName: "short"
    })
  } catch (e) {
    return // unknown zone name: keep the server-rendered text
  }
  serverTime = epoch * 1000
  clientTime = Date.now()
  tick()
}

const tick = () => {
  if (serverTime === null) return
  const time = document.querySelector("[data-server-clock] .clock-time")
  const date = document.querySelector("[data-server-clock] .clock-date")
  if (!time || !date) return
  const parts = {}
  format.formatToParts(new Date(serverTime + (Date.now() - clientTime)))
    .forEach((part) => { parts[part.type] = part.value })
  time.textContent = `${parts.hour}:${parts.minute}:${parts.second} ${parts.timeZoneName}`
  date.textContent = `${parts.year} ${parts.month} ${parts.day}`
}

const start = () => {
  sync()
  setInterval(tick, 1000)
}

if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start)
else start()
document.addEventListener("turbo:load", sync)
