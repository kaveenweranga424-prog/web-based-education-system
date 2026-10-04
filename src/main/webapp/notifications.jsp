<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Notification" %>
<%@ page import="java.util.List" %>
<%!
    private String h(Object val) {
        if (val == null) return "";
        return String.valueOf(val).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
    private String badgeClass(String type) {
        if (type == null) return "badge-neutral";
        switch (type.toUpperCase()) {
            case "PAYMENT":
            case "FEE": return "badge-amber";
            case "ATTENDANCE": return "badge-blue";
            case "RESULT": return "badge-cyan";
            case "ENROLLMENT": return "badge-violet";
            case "ANNOUNCEMENT": return "badge-paid";
            default: return "badge-neutral";
        }
    }
    private String iconClass(String type) {
        if (type == null) return "fa-bell";
        switch (type.toUpperCase()) {
            case "PAYMENT":
            case "FEE": return "fa-wallet";
            case "ATTENDANCE": return "fa-user-check";
            case "RESULT": return "fa-award";
            case "ENROLLMENT": return "fa-user-plus";
            case "ANNOUNCEMENT": return "fa-bullhorn";
            default: return "fa-bell";
        }
    }
%>
<%
    String contextPath = request.getContextPath();
    List<Notification> notifications = (List<Notification>) request.getAttribute("notifications");
    int unreadCount = 0;
    if (notifications != null) {
        for (Notification n : notifications) {
            if (!n.isRead()) unreadCount++;
        }
    }
    String userName = session.getAttribute("userName") != null ? String.valueOf(session.getAttribute("userName")) : "User";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Notifications &amp; Alerts | Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/class-pages.css">
    <style>
        .notif-container { max-width: 900px; margin: 32px auto; padding: 0 20px; }
        .notif-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .notif-title-group h1 { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 24px; font-weight: 700; color: #171717; }
        .notif-title-group p { font-size: 14px; color: #737373; margin-top: 4px; }
        .notif-actions { display: flex; align-items: center; gap: 12px; }
        .btn-action { display: inline-flex; align-items: center; gap: 8px; padding: 9px 16px; border-radius: 10px; font-size: 13.5px; font-weight: 600; text-decoration: none; border: 1px solid #e5e5e5; background: #fff; color: #171717; cursor: pointer; transition: all .2s ease; }
        .btn-action:hover { background: #f5f5f5; border-color: #d4d4d4; }
        .btn-action.btn-primary { background: #7c3aed; color: #fff; border-color: #7c3aed; }
        .btn-action.btn-primary:hover { background: #6d28d9; }
        .notif-card { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,.04); }
        .notif-list { list-style: none; margin: 0; padding: 0; }
        .notif-item { display: flex; align-items: flex-start; gap: 16px; padding: 18px 22px; border-bottom: 1px solid #f0f0f0; transition: background .15s ease; position: relative; }
        .notif-item:last-child { border-bottom: none; }
        .notif-item.unread { background: #fdfcff; }
        .notif-item.unread::before { content: ''; position: absolute; left: 0; top: 0; bottom: 0; width: 4px; background: #7c3aed; }
        .notif-icon-box { width: 42px; height: 42px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; font-size: 16px; }
        .notif-icon-box.badge-amber { background: #fef3c7; color: #d97706; }
        .notif-icon-box.badge-blue { background: #dbeafe; color: #2563eb; }
        .notif-icon-box.badge-cyan { background: #cffafe; color: #0891b2; }
        .notif-icon-box.badge-violet { background: #ede9fe; color: #7c3aed; }
        .notif-icon-box.badge-paid { background: #dcfce7; color: #16a34a; }
        .notif-icon-box.badge-neutral { background: #f3f4f6; color: #4b5563; }
        .notif-content { flex: 1; min-width: 0; }
        .notif-content-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-bottom: 4px; }
        .notif-item-title { font-size: 15px; font-weight: 600; color: #171717; }
        .notif-time { font-size: 12px; color: #a3a3a3; white-space: nowrap; }
        .notif-message { font-size: 13.5px; color: #525252; line-height: 1.5; margin-bottom: 8px; word-break: break-word; }
        .notif-meta { display: flex; align-items: center; gap: 10px; font-size: 12px; color: #737373; flex-wrap: wrap; }
        .notif-type-tag { padding: 3px 8px; border-radius: 6px; font-size: 11px; font-weight: 700; text-transform: uppercase; }
        .badge-amber-tag { background: #fef3c7; color: #b45309; }
        .badge-blue-tag { background: #dbeafe; color: #1d4ed8; }
        .badge-cyan-tag { background: #cffafe; color: #0e7490; }
        .badge-violet-tag { background: #ede9fe; color: #6d28d9; }
        .badge-paid-tag { background: #dcfce7; color: #15803d; }
        .badge-neutral-tag { background: #f3f4f6; color: #374151; }
        .notif-btns { display: flex; align-items: center; gap: 6px; flex-shrink: 0; }
        .notif-btn-sm { background: none; border: none; padding: 6px 10px; border-radius: 8px; font-size: 12px; font-weight: 600; cursor: pointer; color: #737373; transition: all .2s; }
        .notif-btn-sm:hover { background: #f5f5f5; color: #171717; }
        .notif-btn-sm.delete-btn:hover { background: #fee2e2; color: #dc2626; }
        .empty-notifs { padding: 48px 24px; text-align: center; color: #737373; }
        .empty-notifs i { font-size: 40px; color: #d4d4d4; margin-bottom: 12px; }
    </style>
</head>
<body class="dash-body">

<header class="class-page-header">
    <a class="class-brand" href="<%= contextPath %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle">Notification Center</span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= contextPath %>/dashboard"><i class="fa-solid fa-arrow-left"></i> Dashboard</a>
    </div>
</header>

<main class="notif-container">
    <div class="notif-header">
        <div class="notif-title-group">
            <h1>Notifications &amp; Announcements</h1>
            <p>Stay updated on class schedules, fee alerts, exam results, and announcements.</p>
        </div>
        <div class="notif-actions">
            <% if (unreadCount > 0) { %>
            <form action="<%= contextPath %>/notifications" method="post" style="display:inline;" onsubmit="markAllNotificationsRead(); return false;">
                <input type="hidden" name="action" value="markAllRead">
                <button type="submit" class="btn-action">
                    <i class="fa-solid fa-check-double"></i> Mark all as read (<%= unreadCount %>)
                </button>
            </form>
            <% } %>
            <a href="<%= contextPath %>/dashboard" class="btn-action btn-primary">
                <i class="fa-solid fa-gauge"></i> My Dashboard
            </a>
        </div>
    </div>

    <div class="notif-card">
        <% if (notifications == null || notifications.isEmpty()) { %>
            <div class="empty-notifs">
                <i class="fa-regular fa-bell-slash"></i>
                <h3>No notifications yet</h3>
                <p>When you receive announcements, reminders, or updates, they will appear here.</p>
            </div>
        <% } else { %>
            <ul class="notif-list">
            <% for (Notification n : notifications) { 
                String bClass = badgeClass(n.getType());
                String iClass = iconClass(n.getType());
                String notifTime = n.getCreatedAt() != null ? n.getCreatedAt().toString().substring(0, 16) : "";
            %>
                <li class="notif-item <%= !n.isRead() ? "unread" : "" %>"
                    data-id="<%= n.getNotificationId() %>"
                    data-title="<%= h(n.getTitle()) %>"
                    data-message="<%= h(n.getMessage()) %>"
                    data-type="<%= h(n.getType()) %>"
                    data-time="<%= notifTime %>"
                    data-sender="<%= h(n.getCreatedByName()) %>"
                    data-unread="<%= !n.isRead() ? "true" : "false" %>"
                    onclick="openNotificationReader(this)"
                    style="cursor: pointer;">
                    <div class="notif-icon-box <%= bClass %>">
                        <i class="fa-solid <%= iClass %>"></i>
                    </div>
                    <div class="notif-content">
                        <div class="notif-content-head">
                            <span class="notif-item-title"><%= h(n.getTitle()) %></span>
                            <span class="notif-time"><%= notifTime %></span>
                        </div>
                        <p class="notif-message"><%= h(n.getMessage()) %></p>
                        <div class="notif-meta">
                            <span class="notif-type-tag <%= bClass %>-tag"><%= h(n.getType()) %></span>
                            <% if (n.getSubject() != null && !n.getSubject().isBlank()) { %>
                                <span><i class="fa-solid fa-book-open"></i> <%= h(n.getSubject()) %></span>
                            <% } %>
                            <% if (n.getCreatedByName() != null && !n.getCreatedByName().isBlank()) { %>
                                <span><i class="fa-solid fa-user-pen"></i> By <%= h(n.getCreatedByName()) %></span>
                            <% } %>
                        </div>
                    </div>
                    <div class="notif-btns" onclick="event.stopPropagation()">
                        <% if (!n.isRead()) { %>
                        <form action="<%= contextPath %>/notifications" method="post" style="display:inline;" onsubmit="markNotificationRead(event, <%= n.getNotificationId() %>, this.closest('li')); return false;">
                            <input type="hidden" name="action" value="markRead">
                            <input type="hidden" name="notificationId" value="<%= n.getNotificationId() %>">
                            <button type="submit" class="notif-btn-sm notif-quick-read-btn" title="Mark as read"
                                    onclick="markNotificationRead(event, <%= n.getNotificationId() %>, this.closest('li')); return false;">
                                <i class="fa-solid fa-check"></i>
                            </button>
                        </form>
                        <% } %>
                        <form action="<%= contextPath %>/notifications" method="post" style="display:inline;" onsubmit="return confirm('Delete this notification?');">
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="notificationId" value="<%= n.getNotificationId() %>">
                            <button type="submit" class="notif-btn-sm delete-btn" title="Delete">
                                <i class="fa-solid fa-trash-can"></i>
                            </button>
                        </form>
                    </div>
                </li>
            <% } %>
            </ul>
        <% } %>
    </div>
</main>

<!-- NOTIFICATION READER MODAL -->
<div class="notif-modal-overlay" id="notifReaderModal" onclick="if(event.target===this)closeNotificationReader()">
    <div class="notif-modal-card">
        <div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:16px;">
            <div style="display:flex; align-items:center; gap:12px;">
                <div class="notice-icon icon-blue" id="modalNotifIcon" style="width:42px;height:42px;font-size:16px;">
                    <i class="fa-regular fa-bell"></i>
                </div>
                <div>
                    <span class="badge badge-neutral" id="modalNotifType" style="font-size:11px;font-weight:700;">ANNOUNCEMENT</span>
                    <div id="modalNotifSender" style="font-size:12px;color:var(--text-muted);margin-top:2px;"></div>
                </div>
            </div>
            <button type="button" onclick="closeNotificationReader()" style="border:none;background:none;font-size:24px;cursor:pointer;color:#64748b;line-height:1;padding:4px;">&times;</button>
        </div>
        <h3 id="modalNotifTitle" style="font-size:18px;font-weight:700;color:var(--dark);margin-bottom:8px;line-height:1.4;"></h3>
        <div id="modalNotifTime" style="font-size:12px;color:var(--text-muted);margin-bottom:16px;display:flex;align-items:center;gap:6px;">
            <i class="fa-regular fa-clock"></i> <span id="modalNotifTimeText"></span>
        </div>
        <div id="modalNotifMessage" class="notif-modal-body"></div>
        <div style="display:flex; justify-content:flex-end; gap:10px;">
            <button type="button" class="btn-solid sm" onclick="closeNotificationReader()">Close</button>
        </div>
    </div>
</div>

<div class="toast" id="toast"></div>
<script>window.appContextPath = '<%=contextPath%>';</script>
<script src="<%=contextPath%>/js/notifications.js?v=2.2"></script>
</body>
</html>
