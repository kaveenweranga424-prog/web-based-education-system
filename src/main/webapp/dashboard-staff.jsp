<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.*" %>
<%!
    private String h(Object value){ if(value==null)return ""; return String.valueOf(value).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;"); }
    private double num(Object value){ return value instanceof Number ? ((Number)value).doubleValue() : 0d; }
    private int integer(Object value){ return value instanceof Number ? ((Number)value).intValue() : 0; }
    private String money(Object value){ return "Rs. "+String.format(Locale.US,"%,.2f",num(value)); }
    private String badge(Object value){ String s=value==null?"":String.valueOf(value).toUpperCase(Locale.ROOT); if(s.equals("PAID")||s.equals("ACTIVE"))return "badge-paid"; if(s.equals("UNPAID")||s.equals("PARTIAL"))return "badge-pending"; if(s.equals("CANCELLED"))return "badge-absent"; return "badge-neutral"; }
    private String getInitials(String name) {
        if (name == null || name.trim().isEmpty()) return "SF";
        String[] parts = name.trim().split("\\s+");
        if (parts.length == 1) {
            return parts[0].substring(0, Math.min(2, parts[0].length())).toUpperCase();
        }
        return ("" + parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
    }
    private String notifIcon(Object typeObj) {
        String type = typeObj != null ? String.valueOf(typeObj).toUpperCase() : "";
        switch (type) {
            case "PAYMENT":
            case "FEE": return "fa-solid fa-wallet";
            case "ATTENDANCE": return "fa-solid fa-user-check";
            case "RESULT":
            case "EXAM": return "fa-solid fa-award";
            case "ENROLLMENT": return "fa-solid fa-user-plus";
            case "ANNOUNCEMENT": return "fa-solid fa-bullhorn";
            default: return "fa-regular fa-bell";
        }
    }
    private String notifColorClass(Object typeObj) {
        String type = typeObj != null ? String.valueOf(typeObj).toUpperCase() : "";
        switch (type) {
            case "PAYMENT":
            case "FEE": return "icon-amber";
            case "ATTENDANCE": return "icon-blue";
            case "RESULT":
            case "EXAM": return "icon-emerald";
            case "ENROLLMENT": return "icon-violet";
            case "ANNOUNCEMENT": return "icon-cyan";
            default: return "icon-blue";
        }
    }
    private boolean isUnread(Object val) {
        if (val == null) return false;
        if (val instanceof Boolean) return !((Boolean) val);
        if (val instanceof Number) return ((Number) val).intValue() == 0;
        return "false".equalsIgnoreCase(String.valueOf(val)) || "0".equals(String.valueOf(val));
    }
%>
<%
    String contextPath=request.getContextPath();
    Map<String,Object> dashboardData=(Map<String,Object>)request.getAttribute("dashboardData"); if(dashboardData==null)dashboardData=new LinkedHashMap<>();
    Map<String,Object> summary=(Map<String,Object>)dashboardData.getOrDefault("summary",new LinkedHashMap<String,Object>());
    List<Map<String,Object>> invoices=(List<Map<String,Object>>)dashboardData.getOrDefault("invoices",Collections.emptyList());
    List<Map<String,Object>> payments=(List<Map<String,Object>>)dashboardData.getOrDefault("payments",Collections.emptyList());
    List<Map<String,Object>> notifications=(List<Map<String,Object>>)dashboardData.getOrDefault("notifications",Collections.emptyList());
    int unreadNotifCount = 0;
    for (Map<String,Object> n : notifications) {
        if (isUnread(n.get("isRead"))) unreadNotifCount++;
    }
    if (unreadNotifCount == 0 && summary.get("unreadNotifications") != null) {
        unreadNotifCount = integer(summary.get("unreadNotifications"));
    }
    String userName=String.valueOf(session.getAttribute("userName")==null?"Staff":session.getAttribute("userName"));
    String dashboardError=(String)request.getAttribute("dashboardError");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1.0">
    <title>Staff Dashboard — Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%=contextPath%>/css/dashboard.css">
    <link rel="stylesheet" href="<%=contextPath%>/css/dashboard-staff.css">
    <link rel="stylesheet" href="<%=contextPath%>/css/dashboard-tutor.css">
</head>
<body class="dash-body">
<aside class="sidebar" id="sidebar">
    <div class="sidebar-top">
        <div class="auth-logo sidebar-logo">
            <div class="logo-mark">C</div>
            <div class="logo-text">
                <span class="logo-title">Classora</span>
                <span class="logo-sub">Staff Portal</span>
            </div>
        </div>
        <button class="sidebar-close" id="sidebarClose"><i class="fa-solid fa-xmark"></i></button>
    </div>
    <nav class="sidebar-nav">
        <span class="sidebar-label">Finance</span>
        <button class="nav-item is-active" data-view="overview"><i class="fa-solid fa-gauge"></i><span>Overview</span></button>
        <button class="nav-item" data-view="invoices"><i class="fa-solid fa-file-invoice-dollar"></i><span>Invoices</span></button>
        <button class="nav-item" data-view="payments"><i class="fa-solid fa-money-bill-wave"></i><span>Payments</span></button>
        <button type="button" class="nav-item" onclick="location.href='<%=contextPath%>/staff/payments'"><i class="fa-solid fa-receipt"></i><span>Record Payment</span></button>
        <button type="button" class="nav-item" onclick="location.href='<%=contextPath%>/staff/invoices'"><i class="fa-solid fa-gear"></i><span>Manage Invoices</span></button>
        <button type="button" class="nav-item" onclick="location.href='<%=contextPath%>/staff/payment-approvals'"><i class="fa-solid fa-credit-card"></i><span>Payment Approvals</span><% if(integer(summary.get("pendingApprovals"))>0){%><span class="nav-badge" style="background:#ea580c;"><%=integer(summary.get("pendingApprovals"))%></span><%}%></button>
        <button class="nav-item" data-view="notices">
            <i class="fa-regular fa-bell"></i>
            <span>Notifications</span>
            <% if(unreadNotifCount > 0){ %>
                <span class="nav-badge"><%=unreadNotifCount%></span>
            <% } %>
        </button>
    </nav>
    <div class="sidebar-footer">
        <div class="sidebar-user">
            <div class="avatar"><%=getInitials(userName)%></div>
            <div class="sidebar-user-info">
                <span class="sidebar-user-name"><%=h(userName)%></span>
                <span class="sidebar-user-role">Staff</span>
            </div>
        </div>
        <a href="<%=contextPath%>/logout" class="sidebar-logout"><i class="fa-solid fa-arrow-right-from-bracket"></i> Log out</a>
    </div>
</aside>
<div class="sidebar-overlay" id="sidebarOverlay"></div>

<main class="dash-main">
    <header class="topbar">
        <button class="icon-btn menu-btn" id="menuBtn"><i class="fa-solid fa-bars"></i></button>
        <div class="topbar-title">
            <h1 id="pageTitle">Overview</h1>
            <p id="pageSub">Live invoice and payment data from SQL Server.</p>
        </div>
        <div class="topbar-actions">
            <button type="button" class="icon-btn" data-goto="notices" title="Notifications" style="position:relative;">
                <i class="fa-regular fa-bell"></i>
                <% if(unreadNotifCount > 0){ %>
                    <span class="topbar-notif-dot" style="position:absolute;top:4px;right:4px;width:8px;height:8px;background:#ef4444;border-radius:50%;border:2px solid #fff;"></span>
                <% } %>
            </button>
            <div class="avatar avatar-sm"><%=getInitials(userName)%></div>
        </div>
    </header>

    <div class="dash-content">
        <% if(dashboardError!=null){ %>
            <div class="card"><span class="badge badge-absent"><%=h(dashboardError)%></span></div>
        <% } %>

        <!-- VIEW: OVERVIEW -->
        <section class="view is-active" data-view="overview">
            <div class="stat-grid">
                <div class="stat-card">
                    <div class="stat-icon icon-violet"><i class="fa-solid fa-file-invoice"></i></div>
                    <span class="stat-label">Invoices Today</span>
                    <span class="stat-value"><%=integer(summary.get("invoicesToday"))%></span>
                    <span class="stat-meta">Created today</span>
                </div>
                <div class="stat-card">
                    <div class="stat-icon icon-blue"><i class="fa-solid fa-receipt"></i></div>
                    <span class="stat-label">Payments Today</span>
                    <span class="stat-value"><%=integer(summary.get("paymentsToday"))%></span>
                    <span class="stat-meta">Payment records</span>
                </div>
                <div class="stat-card">
                    <div class="stat-icon icon-cyan"><i class="fa-solid fa-sack-dollar"></i></div>
                    <span class="stat-label">Collected Today</span>
                    <span class="stat-value"><%=money(summary.get("amountToday"))%></span>
                </div>
                <div class="stat-card">
                    <div class="stat-icon icon-amber"><i class="fa-solid fa-clock"></i></div>
                    <span class="stat-label">Outstanding</span>
                    <span class="stat-value"><%=money(summary.get("outstandingBalance"))%></span>
                    <span class="stat-meta warn"><%=integer(summary.get("overdueInvoices"))%> overdue invoices</span>
                </div>
                <div class="stat-card">
                    <div class="stat-icon icon-violet"><i class="fa-solid fa-bell"></i></div>
                    <span class="stat-label">Pending Approvals</span>
                    <span class="stat-value"><%=integer(summary.get("pendingApprovals"))%></span>
                    <span class="stat-meta"><a href="<%=contextPath%>/staff/payment-approvals" style="color:#7c3aed;text-decoration:none;font-weight:600;">Review now &rarr;</a></span>
                </div>
            </div>

            <div class="grid-2">
                <div class="card">
                    <div class="card-head">
                        <h2>Recent Invoices</h2>
                        <button class="link-btn" data-goto="invoices">View all</button>
                    </div>
                    <ul class="class-list">
                        <% if(invoices.isEmpty()){ %>
                            <li>No invoices found.</li>
                        <% } else for(int i=0;i<Math.min(6,invoices.size());i++){ Map<String,Object> r=invoices.get(i); %>
                            <li>
                                <div>
                                    <span class="class-name">#<%=h(r.get("invoiceId"))%> · <%=h(r.get("studentName"))%></span>
                                    <span class="class-meta"><%=h(r.get("subject"))%> — <%=h(r.get("batch"))%></span>
                                </div>
                                <span class="amount"><%=money(r.get("balance"))%></span>
                            </li>
                        <% } %>
                    </ul>
                </div>

                <div class="card">
                    <div class="card-head">
                        <h2>Recent Payments</h2>
                        <button class="link-btn" data-goto="payments">View all</button>
                    </div>
                    <ul class="class-list">
                        <% if(payments.isEmpty()){ %>
                            <li>No payments found.</li>
                        <% } else for(int i=0;i<Math.min(6,payments.size());i++){ Map<String,Object> r=payments.get(i); %>
                            <li>
                                <div>
                                    <span class="class-name"><%=h(r.get("studentName"))%></span>
                                    <span class="class-meta"><%=h(r.get("subject"))%> · <%=h(r.get("paymentMethod"))%></span>
                                </div>
                                <span class="amount"><%=money(r.get("amountPaid"))%></span>
                            </li>
                        <% } %>
                    </ul>
                </div>
            </div>

            <div class="card" style="margin-top:20px;">
                <div class="card-head">
                    <h2><i class="fa-regular fa-bell" style="color:var(--secondary);font-size:15px;"></i> Recent Notifications</h2>
                    <button type="button" class="link-btn" data-goto="notices">View all <i class="fa-solid fa-chevron-right" style="font-size:11px;"></i></button>
                </div>
                <ul class="notice-list">
                    <% if(notifications.isEmpty()){ %>
                        <li>No notifications found.</li>
                    <% } else for(int i=0; i<Math.min(5, notifications.size()); i++){ Map<String,Object> r=notifications.get(i); 
                        boolean isUnread = isUnread(r.get("isRead"));
                    %>
                        <li class="<%=isUnread ? "unread" : ""%>"
                            data-id="<%=r.get("notificationId")%>"
                            data-title="<%=h(r.get("title"))%>"
                            data-message="<%=h(r.get("message"))%>"
                            data-type="<%=h(r.get("type"))%>"
                            data-time="<%=h(r.get("createdAt"))%>"
                            data-sender="<%=h(r.get("createdByName"))%>"
                            data-unread="<%=isUnread ? "true" : "false"%>"
                            onclick="openNotificationReader(this)">
                            <div class="notice-icon <%=notifColorClass(r.get("type"))%>"><i class="<%=notifIcon(r.get("type"))%>"></i></div>
                            <div style="flex:1;min-width:0;">
                                <div style="display:flex;align-items:center;justify-content:space-between;gap:8px;">
                                    <span class="notice-title">
                                        <% if (isUnread) { %><span class="unread-dot" title="Unread"></span><% } %>
                                        <%=h(r.get("title"))%>
                                    </span>
                                    <% if (isUnread) { %><span class="badge-unread-tag">New</span><% } %>
                                </div>
                                <span class="notice-text"><%=h(r.get("message"))%></span>
                                <span class="notice-time"><i class="fa-regular fa-clock" style="font-size:10px;"></i> <%=h(r.get("createdAt"))%></span>
                            </div>
                            <% if (isUnread) { %>
                                <button type="button" class="notif-quick-read-btn" title="Mark as read" onclick="markNotificationRead(event, <%=r.get("notificationId")%>, this.closest('li'))">
                                    <i class="fa-solid fa-check"></i>
                                </button>
                            <% } %>
                        </li>
                    <% } %>
                </ul>
            </div>
        </section>

        <!-- VIEW: INVOICES -->
        <section class="view" data-view="invoices">
            <div class="card">
                <div class="card-head">
                    <h2>Invoices</h2>
                    <a class="btn-solid sm" href="<%=contextPath%>/staff/invoices">Manage Invoices</a>
                </div>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Student</th>
                                <th>Class</th>
                                <th>Amount</th>
                                <th>Paid</th>
                                <th>Balance</th>
                                <th>Due</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if(invoices.isEmpty()){ %>
                                <tr><td colspan="8" class="muted">No invoices found.</td></tr>
                            <% } else for(Map<String,Object> r:invoices){ %>
                                <tr>
                                    <td class="mono">#<%=h(r.get("invoiceId"))%></td>
                                    <td><%=h(r.get("studentName"))%></td>
                                    <td><%=h(r.get("subject"))%> — <%=h(r.get("batch"))%></td>
                                    <td><%=money(r.get("amount"))%></td>
                                    <td><%=money(r.get("amountPaid"))%></td>
                                    <td><%=money(r.get("balance"))%></td>
                                    <td><%=h(r.get("dueDate"))%></td>
                                    <td><span class="badge <%=badge(r.get("status"))%>"><%=h(r.get("status"))%></span></td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </section>

        <!-- VIEW: PAYMENTS -->
        <section class="view" data-view="payments">
            <div class="card">
                <div class="card-head">
                    <h2>Payments</h2>
                    <span class="card-date"><%=payments.size()%> records</span>
                </div>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Payment</th>
                                <th>Invoice</th>
                                <th>Student</th>
                                <th>Class</th>
                                <th>Amount</th>
                                <th>Method</th>
                                <th>Date</th>
                                <th>Received By</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if(payments.isEmpty()){ %>
                                <tr><td colspan="8" class="muted">No payment records found.</td></tr>
                            <% } else for(Map<String,Object> r:payments){ %>
                                <tr>
                                    <td class="mono">#<%=h(r.get("paymentId"))%></td>
                                    <td class="mono">#<%=h(r.get("invoiceId"))%></td>
                                    <td><%=h(r.get("studentName"))%></td>
                                    <td><%=h(r.get("subject"))%> — <%=h(r.get("batch"))%></td>
                                    <td><%=money(r.get("amountPaid"))%></td>
                                    <td><%=h(r.get("paymentMethod"))%></td>
                                    <td><%=h(r.get("paymentDate"))%></td>
                                    <td><%=h(r.get("receivedByName"))%></td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </section>

        <!-- VIEW: NOTIFICATIONS -->
        <section class="view" data-view="notices">
            <div class="card">
                <div class="card-head" style="flex-wrap:wrap;gap:12px;">
                    <div>
                        <h2><i class="fa-regular fa-bell" style="color:var(--primary);font-size:16px;"></i> Staff Notifications</h2>
                        <span class="card-date"><%=notifications.size()%> records</span>
                    </div>
                    <div style="display:flex;align-items:center;gap:10px;">
                        <button type="button" class="btn-outline sm" onclick="markAllNotificationsRead()" title="Mark all notifications as read">
                            <i class="fa-solid fa-check-double"></i> Mark all as read
                        </button>
                        <a href="<%=contextPath%>/notifications" class="link-btn" title="Open full Notification Center">
                            Notification Center <i class="fa-solid fa-arrow-up-right-from-square" style="font-size:11px;"></i>
                        </a>
                    </div>
                </div>
                <ul class="notice-list">
                    <% if(notifications.isEmpty()){ %>
                        <li>No notifications found.</li>
                    <% } else for(Map<String,Object> r:notifications){ 
                        boolean isUnread = isUnread(r.get("isRead"));
                    %>
                        <li class="<%=isUnread ? "unread" : ""%>"
                            data-id="<%=r.get("notificationId")%>"
                            data-title="<%=h(r.get("title"))%>"
                            data-message="<%=h(r.get("message"))%>"
                            data-type="<%=h(r.get("type"))%>"
                            data-time="<%=h(r.get("createdAt"))%>"
                            data-sender="<%=h(r.get("createdByName"))%>"
                            data-unread="<%=isUnread ? "true" : "false"%>"
                            onclick="openNotificationReader(this)">
                            <div class="notice-icon <%=notifColorClass(r.get("type"))%>"><i class="<%=notifIcon(r.get("type"))%>"></i></div>
                            <div style="flex:1;min-width:0;">
                                <div style="display:flex;align-items:center;justify-content:space-between;gap:8px;">
                                    <span class="notice-title">
                                        <% if (isUnread) { %><span class="unread-dot" title="Unread"></span><% } %>
                                        <%=h(r.get("title"))%>
                                    </span>
                                    <% if (isUnread) { %><span class="badge-unread-tag">New</span><% } %>
                                </div>
                                <span class="notice-text"><%=h(r.get("message"))%></span>
                                <span class="notice-time"><i class="fa-regular fa-clock" style="font-size:10px;"></i> <%=h(r.get("type"))%> &bull; <%=h(r.get("createdAt"))%></span>
                            </div>
                            <% if (isUnread) { %>
                                <button type="button" class="notif-quick-read-btn" title="Mark as read" onclick="markNotificationRead(event, <%=r.get("notificationId")%>, this.closest('li'))">
                                    <i class="fa-solid fa-check"></i>
                                </button>
                            <% } %>
                        </li>
                    <% } %>
                </ul>
            </div>
        </section>
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
<script src="<%=contextPath%>/js/dashboard-staff.js?v=2.2"></script>
</body>
</html>
