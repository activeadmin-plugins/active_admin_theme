// Layout behavior: the collapsible filters sidebar (desktop) and top-menu
// flyout placement. The sidebar state persists in localStorage; without it
// the sidebar starts open.
const KEY = "aat-sidebar-collapsed"

const read = () => {
  try { return localStorage.getItem(KEY) === "1" } catch (e) { return false }
}

const write = (collapsed) => {
  try { localStorage.setItem(KEY, collapsed ? "1" : "0") } catch (e) { /* storage blocked */ }
}

const apply = (collapsed) => {
  const page = document.querySelector("[data-aat-page]")
  if (!page) return
  page.toggleAttribute("data-aat-sidebar-collapsed", collapsed)
  document.querySelectorAll("[data-aat-sidebar-toggle]").forEach((button) => {
    button.setAttribute("aria-expanded", String(!collapsed))
  })
}

document.addEventListener("click", (event) => {
  const toggle = event.target.closest("[data-aat-sidebar-toggle]")
  if (!toggle) return
  const page = document.querySelector("[data-aat-page]")
  const collapsed = !page.hasAttribute("data-aat-sidebar-collapsed")
  apply(collapsed)
  write(collapsed)
})

const init = () => apply(read())
if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init)
else init()

// A top-menu flyout that would run past the viewport edge opens on the other
// side of its item instead.
const placeFlyout = (event) => {
  const item = event.target.closest("[data-aat-submenu]")
  if (!item || item.contains(event.relatedTarget)) return
  const flyout = item.querySelector(":scope > .aat-flyout")
  if (!flyout) return
  item.removeAttribute("data-aat-flip")
  const rect = flyout.getBoundingClientRect()
  const rtl = getComputedStyle(item).direction === "rtl"
  item.toggleAttribute("data-aat-flip", rtl ? rect.left < 0 : rect.right > document.documentElement.clientWidth)
}
document.addEventListener("mouseover", placeFlyout)
document.addEventListener("focusin", placeFlyout)
