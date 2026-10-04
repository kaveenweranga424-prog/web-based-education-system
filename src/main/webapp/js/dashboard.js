document.addEventListener('DOMContentLoaded', () => {
    const navItems = document.querySelectorAll('.nav-item[data-view]');
    const views = document.querySelectorAll('.view[data-view]');
    const pageTitle = document.getElementById('pageTitle');
    const pageSub = document.getElementById('pageSub');
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebarOverlay');

    function titleFor(name) {
        return name.split('-').map(part => part.charAt(0).toUpperCase() + part.slice(1)).join(' ');
    }

    function runAnimations(view) {
        if (!view) return;
        view.querySelectorAll('.progress-fill').forEach((bar, index) => {
            const width = bar.dataset.width || '0';
            bar.style.width = '0%';
            setTimeout(() => { bar.style.width = width + '%'; }, 60 + index * 70);
        });
    }

    function closeSidebar() {
        if (sidebar) sidebar.classList.remove('open');
        if (overlay) overlay.classList.remove('show');
    }

    function switchView(name) {
        let target = null;
        views.forEach(view => {
            const active = view.dataset.view === name;
            view.classList.toggle('is-active', active);
            if (active) target = view;
        });
        if (!target) return;
        navItems.forEach(item => item.classList.toggle('is-active', item.dataset.view === name));
        if (pageTitle) pageTitle.textContent = titleFor(name);
        if (pageSub) pageSub.textContent = 'Live information loaded from the Classora database.';
        runAnimations(target);
        closeSidebar();
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }

    navItems.forEach(item => item.addEventListener('click', () => switchView(item.dataset.view)));
    document.querySelectorAll('[data-goto]').forEach(item => item.addEventListener('click', () => switchView(item.dataset.goto)));

    const menuBtn = document.getElementById('menuBtn');
    const closeBtn = document.getElementById('sidebarClose');
    if (menuBtn) menuBtn.addEventListener('click', () => {
        if (sidebar) sidebar.classList.add('open');
        if (overlay) overlay.classList.add('show');
    });
    if (closeBtn) closeBtn.addEventListener('click', closeSidebar);
    if (overlay) overlay.addEventListener('click', closeSidebar);

    runAnimations(document.querySelector('.view.is-active'));
});
