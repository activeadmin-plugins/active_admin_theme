// Opt-in: add "active_admin_theme/searchable_select" to ActiveAdminTheme.javascripts.
// Upgrades select[data-searchable-select] (rendered by the `searchable_select`
// form and filter inputs) to a Tom Select that loads its options as JSON from
// data-searchable-select-url, one page at a time as the dropdown scrolls.
// A select with data-searchable-select-parent-name stays disabled until the
// input of that name in the same form has a value; when the parent changes,
// the select is cleared and rebuilt against the new value.
import TomSelect from "tom-select"

const SELECTOR = "select[data-searchable-select]"
const listening = new WeakSet()

const parentOf = (el) => {
  const name = el.dataset.searchableSelectParentName
  if (!name) return null
  const fields = el.form ? Array.from(el.form.elements) : Array.from(document.querySelectorAll("select, input"))
  const parent = fields.find((field) => field.name === name)
  if (!parent) console.warn(`searchable_select: parent input ${name} not found`, el)
  return parent || null
}

// Every request carries the search term, the page and the parent's value. The
// next page's URL is the one just fetched with the page advanced.
const firstUrl = (el, parent, query) => {
  const url = new URL(el.dataset.searchableSelectUrl, window.location.href)
  if (query.trim()) url.searchParams.set("term", query.trim())
  url.searchParams.set("page", "1")
  if (parent && parent.value) url.searchParams.set(el.dataset.searchableSelectParentParam, parent.value)
  return url.toString()
}

const nextUrl = (href) => {
  const url = new URL(href)
  url.searchParams.set("page", String(Number(url.searchParams.get("page")) + 1))
  return url.toString()
}

const settingsFor = (el, parent) => {
  const waiting = parent && !parent.value
  const hasBlank = Array.from(el.options).some((option) => option.value === "")
  const plugins = ["virtual_scroll"]
  if (el.multiple) plugins.push("remove_button")
  else plugins.push("dropdown_input")
  if (!el.multiple && hasBlank) plugins.push("clear_button")

  // Ids the server returned for the query on screen. Tom Select keeps every
  // option it has seen, so the score below hides the ones from earlier queries.
  let current = new Set()

  const settings = {
    plugins,
    valueField: "id",
    labelField: "text",
    searchField: ["text"],
    maxOptions: null,
    selectOnTab: true,
    preload: "focus",
    loadThrottle: 250,
    // The server filters; a client-side text score would drop matches on other fields.
    score: () => (option) => (current.has(String(option.id)) ? 1 : 0),
    shouldLoad: () => true,
    firstUrl: (query) => firstUrl(el, parent, query),
    load(query, callback) {
      const href = this.getUrl(query)
      const first = new URL(href).searchParams.get("page") === "1"
      // A slower response for an earlier query (the focus preload, say) must
      // not replace the results of the one typed after it.
      this.aatToken = (this.aatToken || 0) + (first ? 1 : 0)
      const token = this.aatToken
      fetch(href, { headers: { Accept: "application/json" }, credentials: "same-origin" })
        .then((response) => (response.ok ? response.json() : Promise.reject(response)))
        .then((data) => {
          // rebuild() destroyed this instance while the request was in flight.
          if (el.tomselect !== this) return
          if (token !== this.aatToken) return callback()
          if (data.has_more) this.setNextUrl(query, nextUrl(href))
          if (first) current = new Set()
          data.results.forEach((result) => current.add(String(result.id)))
          // A late response must not reopen a dropdown the user already closed
          // by picking an option.
          const wasOpen = this.isOpen
          callback(data.results)
          if (!wasOpen && this.isOpen) this.close()
        })
        .catch(() => callback())
    }
  }
  if (waiting) settings.placeholder = el.dataset.searchableSelectParentPlaceholder || "Select the parent first"
  return settings
}

// Picking an option in a single select hands focus back to the control, and
// Tom Select then reopens the dropdown on its own. Ignore opens that follow a
// pick until the user presses the control again.
const closeAfterPick = (select) => {
  let picked = false
  const open = select.open.bind(select)
  select.open = () => { if (!picked) open() }
  select.on("item_add", () => { picked = true })
  select.control.addEventListener("mousedown", () => { picked = false }, true)
  select.wrapper.addEventListener("keydown", () => { picked = false }, true)
}

const build = (el, parent) => {
  if (parent) el.dataset.searchableSelectParentValue = parent.value
  const select = new TomSelect(el, settingsFor(el, parent))
  if (!el.multiple) closeAfterPick(select)
  if (parent && !parent.value) select.disable()
}

const rebuild = (el, parent) => {
  if (el.tomselect) el.tomselect.destroy()
  Array.from(el.options).forEach((option) => { if (option.value !== "") option.remove() })
  el.disabled = false
  // Lets selects that depend on this one reset too.
  el.dispatchEvent(new Event("change", { bubbles: true }))
  build(el, parent)
}

const upgrade = (el) => {
  if (el.tomselect || el.closest("template")) return
  const parent = parentOf(el)
  build(el, parent)
  if (parent && !listening.has(el)) {
    listening.add(el)
    parent.addEventListener("change", () => {
      if (el.dataset.searchableSelectParentValue !== parent.value) rebuild(el, parent)
    })
  }
}

const upgradeAll = (root) => {
  if (root.matches && root.matches(SELECTOR)) upgrade(root)
  if (root.querySelectorAll) root.querySelectorAll(SELECTOR).forEach(upgrade)
}

const start = () => {
  upgradeAll(document)
  // Selects added later, such as has_many rows.
  new MutationObserver((records) => {
    records.forEach((record) => {
      record.addedNodes.forEach((node) => { if (node.nodeType === 1) upgradeAll(node) })
    })
  }).observe(document.body, { childList: true, subtree: true })
}

if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start)
else start()
document.addEventListener("turbo:load", () => upgradeAll(document))
