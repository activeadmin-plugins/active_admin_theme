// Crisscross highlighting for index tables. Clicking a cell marks its row and
// column with data-selected, so a value in a wide table is easy to trace to its
// headers. The clicked cell gets data-selected-cell.
//
// ActiveAdmin ticks a row's checkbox when any cell is clicked; the handler
// clicks it again to undo that, so highlighting never leaves rows selected for
// batch actions.
const MARK = "data-selected"
const CENTER = "data-selected-cell"

const clear = (table) => {
  table.querySelectorAll(`[${MARK}]`).forEach((cell) => cell.removeAttribute(MARK))
  table.querySelectorAll(`[${CENTER}]`).forEach((cell) => cell.removeAttribute(CENTER))
}

document.addEventListener("click", (event) => {
  const cell = event.target.closest("table.data-table tbody td")
  if (!cell || event.target.closest("a, button, input, select, textarea, label")) return
  const table = cell.closest("table")
  const row = cell.closest("tr")

  // ActiveAdmin's row toggler has already handled this click; revert it.
  const checkbox = row.querySelector("input[type=checkbox]")
  if (checkbox) checkbox.click()

  clear(table)
  const index = cell.cellIndex
  table.querySelectorAll("tr").forEach((tr) => {
    const column = tr.cells[index]
    if (column && column.tagName === "TD") column.setAttribute(MARK, "")
  })
  row.querySelectorAll("td").forEach((td) => td.setAttribute(MARK, ""))
  cell.setAttribute(CENTER, "")
})

document.addEventListener("change", (event) => {
  const toggleAll = event.target.closest(".batch-actions-toggle-all")
  if (toggleAll) clear(toggleAll.closest("table"))
})
