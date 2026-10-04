/**
 * Classora Universal Profile & Account Settings Module
 * Handles Profile modal popup, tabs, AJAX profile update, and password update for all users.
 */

function openProfileModal() {
    const modal = document.getElementById('profileModal');
    if (!modal) return;

    switchProfileTab('info');
    clearProfileAlert();
    modal.classList.add('show');
}

function closeProfileModal() {
    const modal = document.getElementById('profileModal');
    if (modal) modal.classList.remove('show');
    clearProfileAlert();
}

function switchProfileTab(tab) {
    const btnInfo = document.getElementById('tabBtnInfo');
    const btnSecurity = document.getElementById('tabBtnSecurity');
    const contentInfo = document.getElementById('profileTabInfo');
    const contentSecurity = document.getElementById('profileTabSecurity');

    clearProfileAlert();

    if (tab === 'info') {
        if (btnInfo) btnInfo.classList.add('active');
        if (btnSecurity) btnSecurity.classList.remove('active');
        if (contentInfo) contentInfo.style.display = 'block';
        if (contentSecurity) contentSecurity.style.display = 'none';
    } else {
        if (btnInfo) btnInfo.classList.remove('active');
        if (btnSecurity) btnSecurity.classList.add('active');
        if (contentInfo) contentInfo.style.display = 'none';
        if (contentSecurity) contentSecurity.style.display = 'block';
    }
}

function toggleProfilePass(inputId, iconId) {
    const input = document.getElementById(inputId);
    const icon = document.getElementById(iconId);
    if (!input) return;
    if (input.type === 'password') {
        input.type = 'text';
        if (icon) { icon.classList.remove('fa-eye'); icon.classList.add('fa-eye-slash'); }
    } else {
        input.type = 'password';
        if (icon) { icon.classList.remove('fa-eye-slash'); icon.classList.add('fa-eye'); }
    }
}

function showProfileAlert(message, type = 'error') {
    const alertEl = document.getElementById('profileModalAlert');
    if (!alertEl) return;
    alertEl.textContent = message;
    alertEl.className = 'profile-modal-alert ' + type;
}

function clearProfileAlert() {
    const alertEl = document.getElementById('profileModalAlert');
    if (alertEl) {
        alertEl.style.display = 'none';
        alertEl.textContent = '';
        alertEl.className = 'profile-modal-alert';
    }
}

function handleProfileUpdate(e) {
    e.preventDefault();
    clearProfileAlert();

    const form = e.target;
    const btn = form.querySelector('button[type="submit"]');
    const originalText = btn ? btn.innerHTML : 'Save Profile';
    if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Saving...'; }

    const cp = (window.appContextPath || (window.location.pathname.substring(0, window.location.pathname.indexOf('/', 1)) || ''));
    const formData = new URLSearchParams(new FormData(form));
    formData.append('action', 'updateProfile');
    formData.append('ajax', 'true');

    fetch(cp + '/profile', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-Requested-With': 'XMLHttpRequest'
        },
        body: formData.toString()
    })
    .then(res => res.json())
    .then(data => {
        if (btn) { btn.disabled = false; btn.innerHTML = originalText; }
        if (data.success) {
            showProfileAlert(data.message || 'Profile updated successfully!', 'success');
            if (data.userName) {
                document.querySelectorAll('.sidebar-user-name, #profileModalName').forEach(el => {
                    el.textContent = data.userName;
                });
                const parts = data.userName.trim().split(/\s+/);
                const initials = (parts.length === 1 ? parts[0].substring(0, 2) : (parts[0][0] + parts[parts.length - 1][0])).toUpperCase();
                document.querySelectorAll('.avatar:not(.avatar-icon), #profileModalAvatar').forEach(el => {
                    el.textContent = initials;
                });
            }
            if (typeof showToast === 'function') {
                showToast('Profile updated successfully!', 'success');
            }
            setTimeout(() => {
                closeProfileModal();
            }, 1200);
        } else {
            showProfileAlert(data.error || 'Failed to update profile.', 'error');
        }
    })
    .catch(err => {
        if (btn) { btn.disabled = false; btn.innerHTML = originalText; }
        showProfileAlert('An unexpected error occurred. Please try again.', 'error');
    });
}

function handlePasswordUpdate(e) {
    e.preventDefault();
    clearProfileAlert();

    const form = e.target;
    const newPass = document.getElementById('modalNewPass').value;
    const confirmPass = document.getElementById('modalConfirmPass').value;

    if (newPass !== confirmPass) {
        showProfileAlert('New passwords do not match.', 'error');
        return;
    }
    if (newPass.length < 8) {
        showProfileAlert('New password must be at least 8 characters long.', 'error');
        return;
    }

    const btn = form.querySelector('button[type="submit"]');
    const originalText = btn ? btn.innerHTML : 'Update Password';
    if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Updating...'; }

    const cp = (window.appContextPath || (window.location.pathname.substring(0, window.location.pathname.indexOf('/', 1)) || ''));
    const formData = new URLSearchParams(new FormData(form));
    formData.append('action', 'changePassword');
    formData.append('ajax', 'true');

    fetch(cp + '/profile', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-Requested-With': 'XMLHttpRequest'
        },
        body: formData.toString()
    })
    .then(res => res.json())
    .then(data => {
        if (btn) { btn.disabled = false; btn.innerHTML = originalText; }
        if (data.success) {
            form.reset();
            showProfileAlert(data.message || 'Password changed successfully!', 'success');
            if (typeof showToast === 'function') {
                showToast('Password changed successfully!', 'success');
            }
            setTimeout(() => {
                closeProfileModal();
            }, 1200);
        } else {
            showProfileAlert(data.error || 'Failed to change password.', 'error');
        }
    })
    .catch(err => {
        if (btn) { btn.disabled = false; btn.innerHTML = originalText; }
        showProfileAlert('An unexpected error occurred. Please try again.', 'error');
    });
}

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeProfileModal();
    }
});
