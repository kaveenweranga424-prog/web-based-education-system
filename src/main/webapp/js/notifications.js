/**
 * Classora Notification System
 * Interactive Reader Modal, Mark as Read, and Mark All Read via AJAX
 */

function getContextPath() {
    return window.appContextPath || (window.location.pathname.substring(0, window.location.pathname.indexOf('/', 1)) || '');
}

function showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    if (!toast) return;
    toast.textContent = message;
    toast.className = 'toast show ' + type;
    setTimeout(() => {
        toast.className = 'toast';
    }, 3200);
}

function openNotificationReader(el) {
    if (!el) return;
    const modal = document.getElementById('notifReaderModal');
    if (!modal) return;

    const id = el.dataset.id;
    const title = el.dataset.title || 'Notification';
    const message = el.dataset.message || '';
    const type = (el.dataset.type || 'GENERAL').toUpperCase();
    const time = el.dataset.time || '';
    const sender = el.dataset.sender ? `By ${el.dataset.sender}` : 'Classora Notification';
    const isUnread = el.dataset.unread === 'true';

    const titleEl = document.getElementById('modalNotifTitle');
    const msgEl = document.getElementById('modalNotifMessage');
    const typeEl = document.getElementById('modalNotifType');
    const senderEl = document.getElementById('modalNotifSender');
    const timeEl = document.getElementById('modalNotifTimeText');
    const iconBox = document.getElementById('modalNotifIcon');

    if (titleEl) titleEl.textContent = title;
    if (msgEl) msgEl.textContent = message;
    if (typeEl) {
        typeEl.textContent = type;
        typeEl.className = 'badge ' + getBadgeClassForType(type);
    }
    if (senderEl) senderEl.textContent = sender;
    if (timeEl) timeEl.textContent = time;

    if (iconBox) {
        iconBox.className = getIconBoxClassForType(type);
        iconBox.style.width = '42px';
        iconBox.style.height = '42px';
        iconBox.style.fontSize = '16px';
        iconBox.innerHTML = getIconForType(type);
    }

    modal.classList.add('show');

    // If notification was unread, automatically mark it as read upon opening
    if (isUnread && id) {
        markNotificationRead(null, id, el, false);
    }
}

function closeNotificationReader() {
    const modal = document.getElementById('notifReaderModal');
    if (modal) modal.classList.remove('show');
}

function getBadgeClassForType(type) {
    switch (type) {
        case 'PAYMENT':
        case 'FEE': return 'badge-pending';
        case 'ATTENDANCE': return 'badge-neutral';
        case 'RESULT':
        case 'EXAM': return 'badge-paid';
        case 'ENROLLMENT': return 'badge-violet';
        case 'ANNOUNCEMENT': return 'badge-live';
        default: return 'badge-neutral';
    }
}

function getIconBoxClassForType(type) {
    switch (type) {
        case 'PAYMENT':
        case 'FEE': return 'notice-icon icon-amber';
        case 'ATTENDANCE': return 'notice-icon icon-blue';
        case 'RESULT':
        case 'EXAM': return 'notice-icon icon-emerald';
        case 'ENROLLMENT': return 'notice-icon icon-violet';
        case 'ANNOUNCEMENT': return 'notice-icon icon-cyan';
        default: return 'notice-icon icon-blue';
    }
}

function getIconForType(type) {
    switch (type) {
        case 'PAYMENT':
        case 'FEE': return '<i class="fa-solid fa-wallet"></i>';
        case 'ATTENDANCE': return '<i class="fa-solid fa-user-check"></i>';
        case 'RESULT':
        case 'EXAM': return '<i class="fa-solid fa-award"></i>';
        case 'ENROLLMENT': return '<i class="fa-solid fa-user-plus"></i>';
        case 'ANNOUNCEMENT': return '<i class="fa-solid fa-bullhorn"></i>';
        default: return '<i class="fa-regular fa-bell"></i>';
    }
}

function markNotificationRead(event, id, el, showNotificationToast = true) {
    if (event) {
        event.stopPropagation();
    }
    if (!id) return;

    // Immediately update UI for instant feel
    if (el) {
        el.classList.remove('unread');
        el.dataset.unread = 'false';
        const dot = el.querySelector('.unread-dot');
        if (dot) dot.remove();
        const tag = el.querySelector('.badge-unread-tag');
        if (tag) tag.remove();
        const btn = el.querySelector('.notif-quick-read-btn');
        if (btn) {
            const parentForm = btn.closest('form');
            if (parentForm) parentForm.remove();
            else btn.remove();
        }
    }

    const cp = getContextPath();
    const url = cp + '/notifications';

    fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-Requested-With': 'XMLHttpRequest'
        },
        body: 'action=markRead&notificationId=' + encodeURIComponent(id) + '&ajax=true'
    })
    .then(res => res.json())
    .then(data => {
        if (data && typeof data.unreadCount !== 'undefined') {
            updateSidebarBadge(data.unreadCount);
        } else {
            decrementSidebarBadge();
        }
        if (showNotificationToast) {
            showToast('Notification marked as read', 'success');
        }
    })
    .catch(err => {
        console.error('Error marking notification as read:', err);
    });
}

function markAllNotificationsRead() {
    const cp = getContextPath();
    const url = cp + '/notifications';

    // Optimistically update all unread items on the page
    document.querySelectorAll('.notice-list li.unread, .notif-list li.unread').forEach(el => {
        el.classList.remove('unread');
        el.dataset.unread = 'false';
        const dot = el.querySelector('.unread-dot');
        if (dot) dot.remove();
        const tag = el.querySelector('.badge-unread-tag');
        if (tag) tag.remove();
        const btn = el.querySelector('.notif-quick-read-btn');
        if (btn) {
            const parentForm = btn.closest('form');
            if (parentForm) parentForm.remove();
            else btn.remove();
        }
    });

    updateSidebarBadge(0);

    fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-Requested-With': 'XMLHttpRequest'
        },
        body: 'action=markAllRead&ajax=true'
    })
    .then(res => res.json())
    .then(data => {
        showToast('All notifications marked as read', 'success');
    })
    .catch(err => {
        console.error('Error marking all notifications as read:', err);
        showToast('All notifications marked as read', 'success');
    });
}

function updateSidebarBadge(count) {
    document.querySelectorAll('.nav-badge').forEach(badge => {
        if (count <= 0) {
            badge.style.display = 'none';
        } else {
            badge.textContent = count;
            badge.style.display = 'inline-block';
        }
    });
    document.querySelectorAll('.topbar-notif-dot').forEach(dot => {
        dot.style.display = count <= 0 ? 'none' : 'block';
    });
}

function decrementSidebarBadge() {
    let anyRemaining = false;
    document.querySelectorAll('.nav-badge').forEach(badge => {
        let current = parseInt(badge.textContent, 10);
        if (isNaN(current) || current <= 1) {
            badge.style.display = 'none';
        } else {
            badge.textContent = current - 1;
            badge.style.display = 'inline-block';
            anyRemaining = true;
        }
    });
    if (!anyRemaining) {
        document.querySelectorAll('.topbar-notif-dot').forEach(dot => {
            dot.style.display = 'none';
        });
    }
}

// Close modal on Escape key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeNotificationReader();
    }
});
