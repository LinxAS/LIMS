/* ═══════════════════════════════════════════════════════════
   LIMS Shared Utilities
   ═══════════════════════════════════════════════════════════ */

/* Excel icon SVG used by initExportButtons */
const _EXCEL_SVG = `<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 15 15" style="vertical-align:middle;flex-shrink:0">
  <rect width="15" height="15" rx="2" fill="#217346"/>
  <rect x="2" y="3" width="7" height="1.2" rx="0.5" fill="rgba(255,255,255,0.75)"/>
  <rect x="2" y="6" width="7" height="1.2" rx="0.5" fill="rgba(255,255,255,0.75)"/>
  <rect x="2" y="9" width="5" height="1.2" rx="0.5" fill="rgba(255,255,255,0.75)"/>
  <text x="12.5" y="13.5" font-family="Arial,sans-serif" font-size="6" font-weight="900" fill="white" text-anchor="middle">X</text>
</svg>`;

/**
 * Export a table's visible rows to a CSV file and trigger a browser download.
 * Skips header cells with no text (checkbox / indicator columns).
 * Prepends UTF-8 BOM so Excel opens the file with correct encoding.
 */
function exportTableToCSV(tableId, filename) {
  const table = document.getElementById(tableId);
  if (!table) return;

  const csvRows = [];

  // Determine which column indices to include (skip empty-header cols)
  const headerCells = [...table.querySelectorAll('thead th')];
  const includedCols = [];
  const headers = [];
  headerCells.forEach((th, idx) => {
    const text = th.textContent.trim().replace(/[↕↑↓]/g, '').trim();
    if (text) {
      includedCols.push(idx);
      headers.push(`"${text.replace(/"/g, '""')}"`);
    }
  });
  csvRows.push(headers.join(','));

  // Data rows — skip the "no records" placeholder row
  [...table.querySelectorAll('tbody tr')].forEach(tr => {
    if (tr.querySelector('td.table-empty')) return;
    const cells = [...tr.querySelectorAll('td')];
    const row = includedCols.map(idx => {
      const text = (cells[idx]?.textContent || '').trim().replace(/\s+/g, ' ');
      return `"${text.replace(/"/g, '""')}"`;
    });
    csvRows.push(row.join(','));
  });

  const csv  = '\uFEFF' + csvRows.join('\r\n'); // BOM → Excel UTF-8
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);

  // Show toast if the page has one
  if (typeof showToast === 'function') {
    showToast(`Data exported to "${filename}" successfully`, 'success');
  }
}

/**
 * Replace content of all .export-btn elements with the Excel icon and wire up
 * the CSV export using data-table and data-filename attributes on the button.
 */
function initExportButtons() {
  document.querySelectorAll('.export-btn').forEach(btn => {
    btn.innerHTML = _EXCEL_SVG;
    const tableId  = btn.dataset.table    || 'main-table';
    const filename = btn.dataset.filename || 'export.csv';
    btn.addEventListener('click', () => exportTableToCSV(tableId, filename));
  });
}
document.addEventListener('DOMContentLoaded', initExportButtons);

/**
 * Attach drag-to-resize handles to all header cells of a fixed-layout table.
 * Works by updating the matching <col> element in the <colgroup>.
 */
function makeResizable(tableId) {
  const table = document.getElementById(tableId);
  if (!table) return;

  const ths  = [...table.querySelectorAll('thead th')];
  const cols = [...(table.querySelector('colgroup')?.querySelectorAll('col') || [])];

  ths.forEach((th, idx) => {
    // Skip checkbox / dot columns (very narrow fixed cols)
    if (th.offsetWidth < 30) return;

    const handle = document.createElement('div');
    handle.className = 'col-resizer';
    th.appendChild(handle);

    let startX, startW;

    handle.addEventListener('mousedown', e => {
      startX = e.clientX;
      startW = th.offsetWidth;
      document.body.style.cursor = 'col-resize';
      document.body.style.userSelect = 'none';
      document.addEventListener('mousemove', onMove);
      document.addEventListener('mouseup', onUp);
      e.preventDefault();
      e.stopPropagation();
    });

    function onMove(e) {
      const newW = Math.max(48, startW + (e.clientX - startX));
      if (cols[idx]) {
        cols[idx].style.width = newW + 'px';
      }
    }

    function onUp() {
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseup', onUp);
    }
  });
}
