<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.*" %>
<%@ page import="model.User" %>
<%!
    private String h(Object value){ if(value==null)return ""; return String.valueOf(value).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;"); }
    private double num(Object value){ return value instanceof Number ? ((Number)value).doubleValue() : 0d; }
    private int integer(Object value){ return value instanceof Number ? ((Number)value).intValue() : 0; }
    private String money(Object value){ return "Rs. "+String.format(Locale.US,"%,.2f",num(value)); }
    private String pct(Object value){ return String.format(Locale.US,"%.1f%%",num(value)); }
    private String badge(Object value){ String s=value==null?"":String.valueOf(value).toUpperCase(Locale.ROOT); if(s.equals("PAID")||s.equals("ACTIVE")||s.equals("COMPLETED")||s.equals("PRESENT"))return "badge-paid"; if(s.equals("UNPAID")||s.equals("PARTIAL")||s.equals("SCHEDULED")||s.equals("LATE"))return "badge-pending"; if(s.equals("CANCELLED")||s.equals("INACTIVE")||s.equals("ABSENT"))return "badge-absent"; return "badge-neutral"; }
    private String getInitials(String name) {
        if (name == null || name.trim().isEmpty()) return "PA";
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
    User currentUser = (User) request.getAttribute("currentUser");
    Map<String,Object> dashboardData=(Map<String,Object>)request.getAttribute("dashboardData"); if(dashboardData==null)dashboardData=new LinkedHashMap<>();
    Map<String,Object> summary=(Map<String,Object>)dashboardData.getOrDefault("summary",new LinkedHashMap<String,Object>());
    Map<String,Object> student=(Map<String,Object>)dashboardData.getOrDefault("student",new LinkedHashMap<String,Object>());
    List<Map<String,Object>> children=(List<Map<String,Object>>)dashboardData.getOrDefault("children",Collections.emptyList());
    Integer selectedStudentId=(Integer)dashboardData.get("selectedStudentId");
    List<Map<String,Object>> classes=(List<Map<String,Object>>)dashboardData.getOrDefault("classes",Collections.emptyList());
    List<Map<String,Object>> timetable=(List<Map<String,Object>>)dashboardData.getOrDefault("timetable",Collections.emptyList());
    List<Map<String,Object>> attendance=(List<Map<String,Object>>)dashboardData.getOrDefault("attendance",Collections.emptyList());
    List<Map<String,Object>> invoices=(List<Map<String,Object>>)dashboardData.getOrDefault("invoices",Collections.emptyList());
    List<Map<String,Object>> payments=(List<Map<String,Object>>)dashboardData.getOrDefault("payments",Collections.emptyList());
    List<Map<String,Object>> results=(List<Map<String,Object>>)dashboardData.getOrDefault("results",Collections.emptyList());
    List<Map<String,Object>> exams=(List<Map<String,Object>>)dashboardData.getOrDefault("exams",Collections.emptyList());
    List<Map<String,Object>> notifications=(List<Map<String,Object>>)dashboardData.getOrDefault("notifications",Collections.emptyList());
    int unreadNotifCount = 0;
    for (Map<String,Object> n : notifications) {
        if (isUnread(n.get("isRead"))) unreadNotifCount++;
    }
    if (unreadNotifCount == 0 && summary.get("unreadNotifications") != null) {
        unreadNotifCount = integer(summary.get("unreadNotifications"));
    }
    String parentName=String.valueOf(session.getAttribute("userName")==null?"Parent":session.getAttribute("userName"));
    String userName = parentName;
    String studentName=String.valueOf(student.getOrDefault("studentName", "No linked student"));
    String studentEmail=String.valueOf(student.getOrDefault("email", ""));
    String dashboardError=(String)request.getAttribute("dashboardError");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1.0">
    <title>Parent Dashboard — Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%=contextPath%>/css/dashboard.css?v=2.2">
    <link rel="stylesheet" href="<%=contextPath%>/css/dashboard-parent.css?v=2.2">
</head>
<body class="dash-body">

<aside class="sidebar" id="sidebar">
    <div class="sidebar-top">
        <div class="auth-logo sidebar-logo">
            <div class="logo-mark">C</div>
            <div class="logo-text">
                <span class="logo-title">Classora</span>
                <span class="logo-sub">Parent Portal</span>
            </div>
        </div>
        <button class="sidebar-close" id="sidebarClose"><i class="fa-solid fa-xmark"></i></button>
    </div>
    
    <% if(!children.isEmpty()){ %>
        <div class="child-switcher">
            <span class="switcher-label">Selected Child</span>
            <form method="get" action="<%=contextPath%>/dashboard" style="margin:0;">
                <div class="select-wrap">
                    <select name="studentId" onchange="this.form.submit()">
                        <% for(Map<String,Object> c:children){ int id=integer(c.get("studentId")); %>
                            <option value="<%=id%>" <%=selectedStudentId!=null&&selectedStudentId==id?"selected":""%>><%=h(c.get("studentName"))%></option>
                        <% } %>
                    </select>
                    <i class="fa-solid fa-chevron-down select-icon"></i>
                </div>
            </form>
        </div>
    <% } %>

    <nav class="sidebar-nav">
        <span class="sidebar-label">Monitoring</span>
        <button class="nav-item is-active" data-view="overview"><i class="fa-solid fa-gauge-high"></i><span>Overview</span></button>
        <button class="nav-item" data-view="attendance"><i class="fa-solid fa-user-check"></i><span>Attendance</span></button>
        <button class="nav-item" data-view="fees">
            <i class="fa-solid fa-wallet"></i>
            <span>Fees &amp; Payments</span>
            <% if(num(summary.get("outstandingBalance")) > 0){ %>
                <span class="nav-badge amber">Due</span>
            <% } %>
        </button>
        <button class="nav-item" data-view="results"><i class="fa-solid fa-award"></i><span>Exam Results</span></button>
        <button class="nav-item" data-view="classes"><i class="fa-solid fa-book-open"></i><span>Classes &amp; Tutors</span></button>
        <button class="nav-item" data-view="timetable"><i class="fa-regular fa-calendar-days"></i><span>Timetable</span></button>
        <button type="button" class="nav-item" onclick="location.href='<%=contextPath%>/fees'"><i class="fa-solid fa-receipt"></i><span>Payment History</span></button>
        <button class="nav-item" data-view="notices">
            <i class="fa-regular fa-bell"></i>
            <span>Notifications</span>
            <% if(unreadNotifCount > 0){ %>
                <span class="nav-badge"><%=unreadNotifCount%></span>
            <% } %>
        </button>
    </nav>
    
    <div class="sidebar-footer">
        <div class="sidebar-user" onclick="openProfileModal()" style="cursor:pointer;" title="Click to view & edit profile">
            <div class="avatar"><%=getInitials(parentName)%></div>
            <div class="sidebar-user-info">
                <span class="sidebar-user-name"><%=h(parentName)%></span>
                <span class="sidebar-user-role">Parent Guardian</span>
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
            <p id="pageSub">Academic tracking and fee status for your registered student.</p>
        </div>
        <div class="topbar-actions">
            <% if(!children.isEmpty()){ %>
                <form method="get" action="<%=contextPath%>/dashboard" style="display:flex;align-items:center;">
                    <div class="select-wrap" style="min-width:180px;">
                        <select name="studentId" id="childSelect" onchange="this.form.submit()" style="padding:8px 32px 8px 12px;font-size:13px;border-radius:10px;">
                            <% for(Map<String,Object> c:children){ int id=integer(c.get("studentId")); %>
                                <option value="<%=id%>" <%=selectedStudentId!=null&&selectedStudentId==id?"selected":""%>><%=h(c.get("studentName"))%></option>
                            <% } %>
                        </select>
                        <i class="fa-solid fa-chevron-down select-icon"></i>
                    </div>
                </form>
            <% } %>
            <button type="button" class="icon-btn" data-goto="notices" title="Notifications" style="position:relative;">
                <i class="fa-regular fa-bell"></i>
                <% if(unreadNotifCount > 0){ %>
                    <span class="topbar-notif-dot" style="position:absolute;top:4px;right:4px;width:8px;height:8px;background:#ef4444;border-radius:50%;border:2px solid #fff;"></span>
                <% } %>
            </button>
            <div class="avatar avatar-sm" onclick="openProfileModal()" style="cursor:pointer;" title="Click to view & edit profile"><%=getInitials(parentName)%></div>
        </div>
    </header>

    <div class="dash-content">
        <% if(dashboardError!=null){ %>
            <div class="card" style="margin-bottom:20px;border-color:#fecaca;background:#fef2f2;">
                <span class="badge badge-absent"><i class="fa-solid fa-circle-exclamation"></i> <%=h(dashboardError)%></span>
            </div>
        <% } %>

        <% if(children.isEmpty()){ %>
            <section class="view is-active" data-view="overview">
                <div class="card" style="text-align:center;padding:48px 20px;">
                    <i class="fa-solid fa-user-group" style="font-size:38px;color:var(--text-muted);margin-bottom:14px;display:block;"></i>
                    <h3 style="font-size:17px;font-weight:700;color:var(--dark);margin-bottom:8px;">No Linked Student Account</h3>
                    <p style="font-size:13.5px;color:var(--text-secondary);max-width:440px;margin:0 auto 20px;">No ACTIVE parent-student link was found for this account. If you just registered, please await administrator approval or contact institute administration.</p>
                </div>
            </section>
        <% } else { %>

            <div class="card" style="margin-bottom: 20px;">
                <div class="card-head" style="margin-bottom: 0;">
                    <div>
                        <h2><i class="fa-solid fa-graduation-cap" style="color:var(--primary);font-size:16px;"></i> <%=h(studentName)%></h2>
                        <span class="card-date"><%=h(studentEmail)%> &bull; <%=integer(summary.get("classCount"))%> enrolled classes</span>
                    </div>
                    <div>
                        <% if(num(summary.get("outstandingBalance")) > 0){ %>
                            <span class="badge badge-pending"><i class="fa-solid fa-circle-exclamation"></i> <%=money(summary.get("outstandingBalance"))%> Due</span>
                        <% } else { %>
                            <span class="badge badge-paid"><i class="fa-solid fa-circle-check"></i> Fees Settled</span>
                        <% } %>
                    </div>
                </div>
            </div>

            <!-- VIEW: OVERVIEW -->
            <section class="view is-active" data-view="overview">
                <div class="stat-grid">
                    <div class="stat-card">
                        <div class="stat-icon icon-violet"><i class="fa-solid fa-book-open"></i></div>
                        <span class="stat-label">Active Classes</span>
                        <span class="stat-value"><%=integer(summary.get("classCount"))%></span>
                        <span class="stat-meta up"><i class="fa-solid fa-check"></i> Enrolled courses</span>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon icon-blue"><i class="fa-solid fa-user-check"></i></div>
                        <span class="stat-label">Attendance Rate</span>
                        <span class="stat-value"><%=pct(summary.get("attendanceRate"))%></span>
                        <span class="stat-meta"><i class="fa-solid fa-clock"></i> Session participation</span>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon icon-amber"><i class="fa-solid fa-wallet"></i></div>
                        <span class="stat-label">Outstanding Fees</span>
                        <span class="stat-value"><%=money(summary.get("outstandingBalance"))%></span>
                        <span class="stat-meta warn"><i class="fa-solid fa-circle-info"></i> Balance to pay</span>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon icon-cyan"><i class="fa-solid fa-award"></i></div>
                        <span class="stat-label">Result Average</span>
                        <span class="stat-value"><%=pct(summary.get("resultAverage"))%></span>
                        <span class="stat-meta up"><i class="fa-solid fa-arrow-trend-up"></i> Academic score</span>
                    </div>
                </div>

                <div class="grid-2">
                    <div class="card">
                        <div class="card-head">
                            <h2><i class="fa-solid fa-book-open" style="color:var(--primary);font-size:15px;"></i> Classes &amp; Tutors</h2>
                            <button type="button" class="link-btn" data-goto="classes">View all <i class="fa-solid fa-chevron-right" style="font-size:11px;"></i></button>
                        </div>
                        <ul class="class-list">
                            <% if(classes.isEmpty()){ %>
                                <li class="muted">No active classes found.</li>
                            <% } else for(int i=0; i<Math.min(6, classes.size()); i++){ Map<String,Object> r=classes.get(i); %>
                                <li>
                                    <div class="subject-icon icon-violet"><i class="fa-solid fa-book-open"></i></div>
                                    <div class="class-info">
                                        <span class="class-name"><%=h(r.get("subject"))%> &mdash; <%=h(r.get("batch"))%></span>
                                        <span class="class-meta"><i class="fa-solid fa-chalkboard-user"></i> <%=h(r.get("tutorName"))%></span>
                                    </div>
                                    <span class="amount mono" style="color:#16a34a;"><%=money(r.get("fee"))%></span>
                                </li>
                            <% } %>
                        </ul>
                    </div>

                    <div class="card">
                        <div class="card-head">
                            <h2><i class="fa-regular fa-bell" style="color:var(--secondary);font-size:15px;"></i> Recent Notifications</h2>
                            <button type="button" class="link-btn" data-goto="notices">View all <i class="fa-solid fa-chevron-right" style="font-size:11px;"></i></button>
                        </div>
                        <ul class="notice-list">
                            <% if(notifications.isEmpty()){ %>
                                <li>No notifications found.</li>
                            <% } else for(int i=0; i<Math.min(6, notifications.size()); i++){ Map<String,Object> r=notifications.get(i); 
                                boolean isUnread = Boolean.FALSE.equals(r.get("isRead"));
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
                </div>
            </section>

            <!-- VIEW: ATTENDANCE -->
            <section class="view" data-view="attendance">
                <div class="card">
                    <div class="card-head">
                        <h2><i class="fa-solid fa-user-check" style="color:var(--secondary);font-size:16px;"></i> Attendance Record &mdash; <%=h(studentName)%></h2>
                        <span class="card-date">Overall <%=pct(summary.get("attendanceRate"))%></span>
                    </div>
                    <div class="table-wrap">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Date</th>
                                    <th>Class</th>
                                    <th>Status</th>
                                    <th>Remarks</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if(attendance.isEmpty()){ %>
                                    <tr><td colspan="4" class="muted">No attendance records found.</td></tr>
                                <% } else for(Map<String,Object> r:attendance){ %>
                                    <tr>
                                        <td><%=h(r.get("sessionDate"))%></td>
                                        <td><%=h(r.get("subject"))%> &mdash; <%=h(r.get("batch"))%></td>
                                        <td><span class="badge <%=badge(r.get("status"))%>"><%=h(r.get("status"))%></span></td>
                                        <td><%=h(r.get("remarks"))%></td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- VIEW: FEES -->
            <section class="view" data-view="fees">
                <div class="stat-grid">
                    <div class="stat-card">
                        <div class="stat-icon icon-amber"><i class="fa-solid fa-wallet"></i></div>
                        <span class="stat-label">Outstanding Balance</span>
                        <span class="stat-value"><%=money(summary.get("outstandingBalance"))%></span>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon icon-blue"><i class="fa-solid fa-file-invoice"></i></div>
                        <span class="stat-label">Issued Invoices</span>
                        <span class="stat-value"><%=invoices.size()%></span>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon icon-cyan"><i class="fa-solid fa-receipt"></i></div>
                        <span class="stat-label">Settled Payments</span>
                        <span class="stat-value"><%=payments.size()%></span>
                    </div>
                </div>
                <div class="card">
                    <div class="card-head">
                        <h2><i class="fa-solid fa-file-invoice-dollar" style="color:var(--primary);font-size:16px;"></i> Invoices</h2>
                        <a class="btn-solid sm" href="<%=contextPath%>/fees"><i class="fa-solid fa-receipt"></i> Pay Fees</a>
                    </div>
                    <div class="table-wrap">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Invoice #</th>
                                    <th>Class</th>
                                    <th>Amount</th>
                                    <th>Paid</th>
                                    <th>Balance</th>
                                    <th>Due Date</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if(invoices.isEmpty()){ %>
                                    <tr><td colspan="7" class="muted">No invoices found.</td></tr>
                                <% } else for(Map<String,Object> r:invoices){ %>
                                    <tr>
                                        <td class="mono" style="color:var(--primary);font-weight:700;">#<%=h(r.get("invoiceId"))%></td>
                                        <td><strong><%=h(r.get("subject"))%> &mdash; <%=h(r.get("batch"))%></strong></td>
                                        <td class="mono"><%=money(r.get("amount"))%></td>
                                        <td class="mono" style="color:#16a34a;"><%=money(r.get("amountPaid"))%></td>
                                        <td class="mono" style="color:#dc2626;"><%=money(r.get("balance"))%></td>
                                        <td><%=h(r.get("dueDate"))%></td>
                                        <td><span class="badge <%=badge(r.get("status"))%>"><%=h(r.get("status"))%></span></td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="card">
                    <div class="card-head">
                        <h2><i class="fa-solid fa-clock-rotate-left" style="color:var(--secondary);font-size:16px;"></i> Payment Receipts</h2>
                    </div>
                    <div class="table-wrap">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Receipt #</th>
                                    <th>Class</th>
                                    <th>Amount</th>
                                    <th>Payment Method</th>
                                    <th>Date</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if(payments.isEmpty()){ %>
                                    <tr><td colspan="5" class="muted">No payments found.</td></tr>
                                <% } else for(Map<String,Object> r:payments){ %>
                                    <tr>
                                        <td class="mono" style="font-weight:700;">#<%=h(r.get("paymentId"))%></td>
                                        <td><%=h(r.get("subject"))%> &mdash; <%=h(r.get("batch"))%></td>
                                        <td class="mono" style="color:#16a34a;"><%=money(r.get("amountPaid"))%></td>
                                        <td><span style="background:#f1f5f9;padding:3px 9px;border-radius:6px;font-size:12px;font-weight:600;"><%=h(r.get("paymentMethod"))%></span></td>
                                        <td><%=h(r.get("paymentDate"))%></td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- VIEW: RESULTS -->
            <section class="view" data-view="results">
                <div class="stat-grid">
                    <div class="stat-card">
                        <div class="stat-icon icon-violet"><i class="fa-solid fa-award"></i></div>
                        <span class="stat-label">Average Score</span>
                        <span class="stat-value"><%=pct(summary.get("resultAverage"))%></span>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon icon-blue"><i class="fa-solid fa-calendar-check"></i></div>
                        <span class="stat-label">Upcoming Exams</span>
                        <span class="stat-value"><%=integer(summary.get("upcomingExams"))%></span>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon icon-cyan"><i class="fa-solid fa-file-lines"></i></div>
                        <span class="stat-label">Published Results</span>
                        <span class="stat-value"><%=results.size()%></span>
                    </div>
                </div>
                <div class="card">
                    <div class="card-head">
                        <h2><i class="fa-solid fa-award" style="color:var(--primary);font-size:16px;"></i> Published Exam Results</h2>
                    </div>
                    <div class="table-wrap">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Exam</th>
                                    <th>Class</th>
                                    <th>Date</th>
                                    <th>Marks</th>
                                    <th>Grade</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if(results.isEmpty()){ %>
                                    <tr><td colspan="5" class="muted">No results found.</td></tr>
                                <% } else for(Map<String,Object> r:results){ %>
                                    <tr>
                                        <td><strong><%=h(r.get("examName"))%></strong></td>
                                        <td><%=h(r.get("subject"))%> &mdash; <%=h(r.get("batch"))%></td>
                                        <td><%=h(r.get("examDate"))%></td>
                                        <td class="mono" style="font-weight:700;"><%=h(r.get("marksObtained"))%> / <%=h(r.get("maxMarks"))%></td>
                                        <td><span class="badge badge-live" style="font-size:12px;font-weight:800;"><%=h(r.get("grade"))%></span></td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="card">
                    <div class="card-head">
                        <h2><i class="fa-solid fa-calendar-days" style="color:var(--secondary);font-size:16px;"></i> Exam Schedule</h2>
                    </div>
                    <div class="table-wrap">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Exam</th>
                                    <th>Class</th>
                                    <th>Date</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if(exams.isEmpty()){ %>
                                    <tr><td colspan="4" class="muted">No exams scheduled.</td></tr>
                                <% } else for(Map<String,Object> r:exams){ %>
                                    <tr>
                                        <td><strong><%=h(r.get("examName"))%></strong></td>
                                        <td><%=h(r.get("subject"))%> &mdash; <%=h(r.get("batch"))%></td>
                                        <td><%=h(r.get("examDate"))%></td>
                                        <td><span class="badge <%=badge(r.get("status"))%>"><%=h(r.get("status"))%></span></td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- VIEW: CLASSES -->
            <section class="view" data-view="classes">
                <div class="card">
                    <div class="card-head">
                        <h2><i class="fa-solid fa-book-open" style="color:var(--primary);font-size:16px;"></i> Enrolled Classes &amp; Tutors &mdash; <%=h(studentName)%></h2>
                        <span class="card-date"><%=classes.size()%> classes</span>
                    </div>
                    <div class="table-wrap">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Class</th>
                                    <th>Tutor</th>
                                    <th>Monthly Fee</th>
                                    <th>Enrolled Date</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if(classes.isEmpty()){ %>
                                    <tr><td colspan="4" class="muted">No active classes found.</td></tr>
                                <% } else for(Map<String,Object> r:classes){ %>
                                    <tr>
                                        <td><strong><%=h(r.get("subject"))%></strong> &mdash; <%=h(r.get("batch"))%></td>
                                        <td><%=h(r.get("tutorName"))%></td>
                                        <td class="mono"><%=money(r.get("fee"))%></td>
                                        <td><%=h(r.get("enrolledAt"))%></td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- VIEW: TIMETABLE -->
            <section class="view" data-view="timetable">
                <div class="card">
                    <div class="card-head">
                        <h2><i class="fa-regular fa-calendar-days" style="color:var(--primary);font-size:16px;"></i> Weekly Timetable &mdash; <%=h(studentName)%></h2>
                        <span class="card-date"><%=timetable.size()%> slots</span>
                    </div>
                    <div class="table-wrap">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Day</th>
                                    <th>Time</th>
                                    <th>Class</th>
                                    <th>Tutor</th>
                                    <th>Room</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if(timetable.isEmpty()){ %>
                                    <tr><td colspan="5" class="muted">No timetable slots found.</td></tr>
                                <% } else for(Map<String,Object> r:timetable){ %>
                                    <tr>
                                        <td><strong><%=h(r.get("dayOfWeek"))%></strong></td>
                                        <td class="mono"><i class="fa-regular fa-clock" style="font-size:11px;color:var(--text-muted);"></i> <%=h(r.get("startTime"))%> &ndash; <%=h(r.get("endTime"))%></td>
                                        <td><strong><%=h(r.get("subject"))%></strong> &mdash; <%=h(r.get("batch"))%></td>
                                        <td><%=h(r.get("tutorName"))%></td>
                                        <td><span style="background:#f1f5f9;padding:3px 9px;border-radius:6px;font-size:12px;font-weight:600;"><i class="fa-solid fa-location-dot" style="font-size:10px;color:var(--primary);"></i> <%=h(r.get("room"))%></span></td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- VIEW: NOTICES -->
            <section class="view" data-view="notices">
                <div class="card">
                    <div class="card-head" style="flex-wrap:wrap;gap:12px;">
                        <div>
                            <h2><i class="fa-regular fa-bell" style="color:var(--secondary);font-size:16px;"></i> Parent Notifications &mdash; <%=h(studentName)%></h2>
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

<!-- PROFILE & ACCOUNT SETTINGS MODAL -->
<div class="profile-modal-overlay" id="profileModal" onclick="if(event.target===this)closeProfileModal()">
    <div class="profile-modal-card">
        <div class="profile-modal-header">
            <div class="profile-user-badge">
                <div class="profile-user-avatar" id="profileModalAvatar"><%=getInitials(userName)%></div>
                <div>
                    <h3 style="margin:0;font-size:17px;font-weight:700;color:#0f172a;" id="profileModalName"><%=h(userName)%></h3>
                    <span style="font-size:12px;color:#64748b;font-weight:600;"><%=currentUser != null && currentUser.getRole() != null ? currentUser.getRole() : "Parent"%> Profile</span>
                </div>
            </div>
            <button type="button" onclick="closeProfileModal()" style="border:none;background:none;font-size:22px;cursor:pointer;color:#64748b;line-height:1;padding:4px;">&times;</button>
        </div>

        <div class="profile-tabs">
            <button type="button" class="profile-tab-btn active" id="tabBtnInfo" onclick="switchProfileTab('info')">
                <i class="fa-solid fa-user"></i> Personal Details
            </button>
            <button type="button" class="profile-tab-btn" id="tabBtnSecurity" onclick="switchProfileTab('security')">
                <i class="fa-solid fa-lock"></i> Security &amp; Password
            </button>
        </div>

        <div id="profileModalAlert" class="profile-modal-alert"></div>

        <!-- TAB 1: PERSONAL DETAILS -->
        <div id="profileTabInfo">
            <form onsubmit="handleProfileUpdate(event)">
                <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;">
                    <div class="profile-form-group">
                        <label>First Name</label>
                        <input type="text" name="firstName" value="<%=currentUser != null && currentUser.getFirstName() != null ? h(currentUser.getFirstName()) : ""%>" required>
                    </div>
                    <div class="profile-form-group">
                        <label>Last Name</label>
                        <input type="text" name="lastName" value="<%=currentUser != null && currentUser.getLastName() != null ? h(currentUser.getLastName()) : ""%>" required>
                    </div>
                </div>
                <div class="profile-form-group">
                    <label>Email Address</label>
                    <input type="email" name="email" value="<%=currentUser != null && currentUser.getEmail() != null ? h(currentUser.getEmail()) : ""%>" required>
                </div>
                <div class="profile-form-group">
                    <label>Phone Number</label>
                    <input type="text" name="phone" value="<%=currentUser != null && currentUser.getPhone() != null ? h(currentUser.getPhone()) : ""%>" placeholder="e.g. +94 77 123 4567">
                </div>
                <div style="display:flex;justify-content:flex-end;gap:10px;margin-top:20px;">
                    <button type="button" onclick="closeProfileModal()" class="btn-outline sm">Cancel</button>
                    <button type="submit" class="btn-solid sm"><i class="fa-solid fa-floppy-disk"></i> Save Profile</button>
                </div>
            </form>
        </div>

        <!-- TAB 2: SECURITY & PASSWORD -->
        <div id="profileTabSecurity" style="display:none;">
            <form onsubmit="handlePasswordUpdate(event)">
                <div class="profile-form-group">
                    <label>Current Password</label>
                    <div class="profile-pass-wrap">
                        <input type="password" name="currentPassword" id="modalCurrentPass" required placeholder="Enter current password">
                        <button type="button" class="profile-pass-toggle" onclick="toggleProfilePass('modalCurrentPass', 'eyeCurrent')">
                            <i class="fa-solid fa-eye" id="eyeCurrent"></i>
                        </button>
                    </div>
                </div>
                <div class="profile-form-group">
                    <label>New Password</label>
                    <div class="profile-pass-wrap">
                        <input type="password" name="newPassword" id="modalNewPass" minlength="8" required placeholder="At least 8 characters">
                        <button type="button" class="profile-pass-toggle" onclick="toggleProfilePass('modalNewPass', 'eyeNew')">
                            <i class="fa-solid fa-eye" id="eyeNew"></i>
                        </button>
                    </div>
                </div>
                <div class="profile-form-group">
                    <label>Confirm New Password</label>
                    <div class="profile-pass-wrap">
                        <input type="password" name="confirmPassword" id="modalConfirmPass" minlength="8" required placeholder="Re-type new password">
                        <button type="button" class="profile-pass-toggle" onclick="toggleProfilePass('modalConfirmPass', 'eyeConfirm')">
                            <i class="fa-solid fa-eye" id="eyeConfirm"></i>
                        </button>
                    </div>
                </div>
                <div style="display:flex;justify-content:flex-end;gap:10px;margin-top:20px;">
                    <button type="button" onclick="closeProfileModal()" class="btn-outline sm">Cancel</button>
                    <button type="submit" class="btn-solid sm"><i class="fa-solid fa-lock"></i> Update Password</button>
                </div>
            </form>
        </div>
    </div>
</div>

<div class="toast" id="toast"></div>
<script>window.appContextPath = '<%=contextPath%>';</script>
<script src="<%=contextPath%>/js/notifications.js?v=2.2"></script>
<script src="<%=contextPath%>/js/dashboard-parent.js?v=2.2"></script>
<script src="<%=contextPath%>/js/profile.js?v=2.2"></script>
</body>
</html>
