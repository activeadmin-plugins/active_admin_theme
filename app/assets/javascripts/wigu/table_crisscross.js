// Crisscross highlighting for ActiveAdmin index tables. Clicking a cell marks
// its whole row and column with class "selected", which the stylesheet paints
// with var(--aa-selected) — so the clicked cell sits at the centre of a
// highlighted cross, making it easy to trace a value to its row and column in a
// wide table.
//
// Uses jQuery, which ActiveAdmin loads before this file (its own
// checkbox-toggler is jQuery too); the rest of the theme JS is dependency-free,
// but this behaviour lives entirely in AA's jQuery-driven index table.
//
// AA's table-checkbox-toggler selects the row when a cell is clicked; we undo
// that (re-click the checkbox) so crisscross highlighting never leaves rows
// ticked for batch actions.
$(document).ready(function () {
  var marker = 'selected';

  // "Select all" clears every row marker left by AA's toggler.
  $('table.index_table .toggle_all').click(function () {
    $(this).closest('table').find('tr.' + marker).removeClass(marker);
  });

  // Clicking the row checkbox itself must not bubble into the cell handler.
  $('table.index_table').find(':checkbox').click(function (e) {
    e.stopPropagation();
    $(this).closest('tr.' + marker).removeClass(marker);
  });

  $('table.index_table').on('click', 'td', function (e) {
    var tdIndex = e.currentTarget.cellIndex,
        $cell = $(e.currentTarget),
        $table = $cell.closest('table'),
        $row = $cell.closest('tr'),
        $columnTds = $table.find('td:nth-child(' + (tdIndex + 1) + ')'),
        $rowTds = $row.find('td');

    // AA ticks the row checkbox on a cell click; click it again to revert.
    $row.find(':checkbox').click();

    if (!$cell.hasClass('col-selectable')) {
      $table.find('td.' + marker).removeClass(marker);
      $table.find('td.selected-cell').removeClass('selected-cell');
      $columnTds.addClass(marker);
      $rowTds.addClass(marker);
      // Mark the clicked cell itself so the stylesheet can set it apart as the
      // centre of the cross.
      $cell.addClass('selected-cell');
    }
  });
});
