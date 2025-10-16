// wwwroot/js/site.js
// global helpers live here later (refresh popup, status pills, etc.)
document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('tr.row-link[data-href]').forEach(tr => {
        tr.addEventListener('click', () => location.href = tr.dataset.href);
        tr.addEventListener('keydown', e => {
            if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); tr.click(); }
        });
    });
});
