<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.*" %>
<%@ page import="model.User" %>
<%!
    private String h(Object value){ if(value==null)return ""; return String.valueOf(value).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;"); }
    private double num(Object value){ return value instanceof Number ? ((Number)value).doubleValue() : 0d; }
    private int integer(Object value){ return value instanceof Number ? ((Number)value).intValue() : 0; }
    private String money(Object value){ return "Rs. "+String.format(Locale.US,"%,.2f",num(value)); }
    private String pct(Object value){ return String.format(Locale.US,"%.1f%%",num(value)); }
    private String badge(Object value){ String s=value==null?"":String.valueOf(value).toUpperCase(Locale.ROOT); if(s.equals("ACTIVE")||s.equals("COMPLETED")||s.equals("PRESENT"))return "badge-paid"; if(s.equals("SCHEDULED")||s.equals("LATE"))return "badge-pending"; if(s.equals("CANCELLED")||s.equals("INACTIVE")||s.equals("ABSENT"))return "badge-absent"; return "badge-neutral"; }
    private String getInitials(String name) {
        if (name == null || name.trim().isEmpty()) return "TU";
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
    Map<String,Object> dashboardData=(Map<String,Object>)request.getAttribute("dashboardData");
    if(dashboardData==null)dashboardData=new LinkedHashMap<>();
    Map<String,Object> summary=(Map<String,Object>)dashboardData.getOrDefault("summary",new LinkedHashMap<String,Object>());
    List<Map<String,Object>> classes=(List<Map<String,Object>>)dashboardData.getOrDefault("classes",Collections.emptyList());
    List<Map<String,Object>> students=(List<Map<String,Object>>)dashboardData.getOrDefault("students",Collections.emptyList());
    List<Map<String,Object>> timetable=(List<Map<String,Object>>)dashboardData.getOrDefault("timetable",Collections.emptyList());
    List<Map<String,Object>> attendance=(List<Map<String,Object>>)dashboardData.getOrDefault("attendance",Collections.emptyList());
    List<Map<String,Object>> exams=(List<Map<String,Object>>)dashboardData.getOrDefault("exams",Collections.emptyList());
    List<Map<String,Object>> notifications=(List<Map<String,Object>>)dashboardData.getOrDefault("notifications",Collections.emptyList());
    List<Map<String,Object>> pendingSubmissions=(List<Map<String,Object>>)dashboardData.getOrDefault("pendingSubmissions",Collections.emptyList());
    int pendingReviewCount = integer(summary.get("pendingReviewCount"));
    int unreadNotifCount = 0;
    for (Map<String,Object> n : notifications) {
        if (isUnread(n.get("isRead"))) unreadNotifCount++;
    }
    String userName=String.valueOf(session.getAttribute("userName")==null?"Tutor":session.getAttribute("userName"));
    String dashboardError=(String)request.getAttribute("dashboardError");
    String flashError = (String) session.getAttribute("flashError");
    if (flashError != null) { session.removeAttribute("flashError"); }
    String flashSuccess = (String) session.getAttribute("flashSuccess");
    if (flashSuccess != null) { session.removeAttribute("flashSuccess"); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1.0">
    <title>Tutor Dashboard — Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%=contextPath%>/css/dashboard.css?v=2.2">
    <link rel="stylesheet" href="<%=contextPath%>/css/dashboard-tutor.css?v=2.2">
</head>
<body class="dash-body">

<aside class="sidebar" id="sidebar">
    <div class="sidebar-top">
        <div class="auth-logo sidebar-logo">
            <div class="logo-mark">C</div>
            <div class="logo-text">
                <span class="logo-title">Classora</span>
                <span class="logo-sub">Tutor Portal</span>
            </div>
        </div>
        <button class="sidebar-close" id="sidebarClose"><i class="fa-solid fa-xmark"></i></button>
    </div>
    
    <nav class="sidebar-nav">
        <span class="sidebar-label">Teaching</span>
        <button class="nav-item is-active" data-view="overview"><i class="fa-solid fa-gauge-high"></i><span>Overview</span></button>
        <button class="nav-item" data-view="classes"><i class="fa-solid fa-book-open"></i><span>My Classes</span></button>
        <button class="nav-item" data-view="students"><i class="fa-solid fa-users"></i><span>My Students</span></button>
        <button type="button" class="nav-item" onclick="location.href='<%=contextPath%>/tutor/materials'"><i class="fa-solid fa-folder-open"></i><span>Manage Materials</span></button>
        <button class="nav-item" data-view="timetable"><i class="fa-regular fa-calendar-days"></i><span>Timetable</span></button>
        <button class="nav-item" data-view="attendance"><i class="fa-solid fa-user-check"></i><span>Attendance</span></button>
        <button class="nav-item" data-view="exams">
            <i class="fa-solid fa-award"></i>
            <span>Exams &amp; Marks</span>
            <% if(pendingReviewCount > 0){ %>
                <span class="nav-badge" style="background:#f59e0b;"><%=pendingReviewCount%></span>
            <% } %>
        </button>
        <button type="button" class="nav-item" onclick="location.href='<%=contextPath%>/announcements'"><i class="fa-solid fa-bullhorn"></i><span>Announcements</span></button>
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
            <div class="avatar"><%=getInitials(userName)%></div>
            <div class="sidebar-user-info">
                <span class="sidebar-user-name"><%=h(userName)%></span>
                <span class="sidebar-user-role">Faculty Tutor</span>
            </div>
        </div>
        <a href="<%=contextPath%>/logout" class="sidebar-logout" style="margin-top:10px;">
            <i class="fa-solid fa-arrow-right-from-bracket"></i> Logout
        </a>
    </div>
</aside>

<div class="sidebar-overlay" id="sidebarOverlay"></div>

<main class="dash-main">
    <header class="topbar">
        <button class="icon-btn menu-btn" id="menuBtn"><i class="fa-solid fa-bars"></i></button>
        <div class="topbar-title">
            <h1 id="pageTitle">Overview</h1>
            <p id="pageSub">Academic teaching streams and student performance dashboard.</p>
        </div>
        <div class="topbar-actions">
            <button type="button" class="icon-btn" data-goto="notices" title="Notifications" style="position:relative;">
                <i class="fa-regular fa-bell"></i>
                <% if(unreadNotifCount > 0){ %>
                    <span class="topbar-notif-dot" style="position:absolute;top:4px;right:4px;width:8px;height:8px;background:#ef4444;border-radius:50%;border:2px solid #fff;"></span>
                <% } %>
            </button>
            <div class="avatar avatar-sm" onclick="openProfileModal()" style="cursor:pointer;" title="Click to view & edit profile"><%=getInitials(userName)%></div>
        </div>
    </header>

    <div class="dash-content">
        <% if(dashboardError!=null){ %>
            <div class="card" style="margin-bottom:20px;border-color:#fecaca;background:#fef2f2;">
                <span class="badge badge-absent"><i class="fa-solid fa-circle-exclamation"></i> <%=h(dashboardError)%></span>
            </div>
        <% } %>
        <% if(flashError!=null){ %>
            <div class="card" style="margin-bottom:20px;background:#fef2f2;border:1px solid #fecaca;color:#991b1b;padding:14px 18px;border-radius:14px;font-size:14px;font-weight:600;display:flex;align-items:center;gap:10px;">
                <i class="fa-solid fa-circle-exclamation"></i> <%=h(flashError)%>
            </div>
        <% } %>
        <% if(flashSuccess!=null){ %>
            <div class="card" style="margin-bottom:20px;background:#f0fdf4;border:1px solid #bbf7d0;color:#166534;padding:14px 18px;border-radius:14px;font-size:14px;font-weight:600;display:flex;align-items:center;gap:10px;">
                <i class="fa-solid fa-circle-check"></i> <%=h(flashSuccess)%>
            </div>
        <% } %>

        <!-- VIEW: OVERVIEW -->
        <section class="view is-active" data-view="overview">
            <div class="stat-grid">
                <div class="stat-card">
                    <div class="stat-icon icon-violet"><i class="fa-solid fa-book-open"></i></div>
                    <span class="stat-label">Active Classes</span>
                    <span class="stat-value"><%=integer(summary.get("classCount"))%></span>
                    <span class="stat-meta up"><i class="fa-solid fa-check"></i> Assigned teaching streams</span>
                </div>
                <div class="stat-card">
                    <div class="stat-icon icon-blue"><i class="fa-solid fa-users"></i></div>
                    <span class="stat-label">Total Students</span>
                    <span class="stat-value"><%=integer(summary.get("studentCount"))%></span>
                    <span class="stat-meta"><i class="fa-solid fa-graduation-cap"></i> Distinct active learners</span>
                </div>
                <div class="stat-card">
                    <div class="stat-icon icon-cyan"><i class="fa-solid fa-user-check"></i></div>
                    <span class="stat-label">Attendance Rate</span>
                    <span class="stat-value"><%=pct(summary.get("attendanceRate"))%></span>
                    <span class="stat-meta up"><i class="fa-solid fa-arrow-trend-up"></i> Present + late sessions</span>
                </div>
                <div class="stat-card">
                    <div class="stat-icon icon-amber"><i class="fa-solid fa-folder-open"></i></div>
                    <span class="stat-label">Class Materials</span>
                    <span class="stat-value"><%=integer(summary.get("materialCount"))%></span>
                    <span class="stat-meta"><%=integer(summary.get("upcomingExamCount"))%> scheduled exams</span>
                </div>
            </div>

            <% if(!pendingSubmissions.isEmpty()){ %>
            <div class="card" style="margin-bottom:24px;border:1.5px solid #fed7aa;background:#fffaf0;">
                <div class="card-head" style="margin-bottom:14px;">
                    <div style="display:flex;align-items:center;gap:10px;">
                        <div class="notice-icon icon-amber" style="width:36px;height:36px;font-size:15px;"><i class="fa-solid fa-clipboard-check"></i></div>
                        <div>
                            <h2 style="font-size:16px;color:#9a3412;margin:0;">Pending Quiz Submissions to Review</h2>
                            <div style="font-size:12.5px;color:#c2410c;margin-top:2px;">
                                <%=pendingSubmissions.size()%> student submission<%=pendingSubmissions.size() > 1 ? "s" : ""%> awaiting your review and mark publishing.
                            </div>
                        </div>
                    </div>
                    <button type="button" class="link-btn" data-goto="exams" style="color:#c2410c;font-weight:700;">View all exams <i class="fa-solid fa-chevron-right" style="font-size:11px;"></i></button>
                </div>
                <div class="table-wrap">
                    <table class="data-table" style="background:#fff;border-radius:10px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
                        <thead>
                            <tr style="background:#fef3c7;">
                                <th>Student</th>
                                <th>Exam Name</th>
                                <th>Class</th>
                                <th>Submitted Score</th>
                                <th>Submitted At</th>
                                <th style="text-align:right;">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for(Map<String,Object> ps : pendingSubmissions){ %>
                            <tr>
                                <td><strong><%=h(ps.get("studentName"))%></strong></td>
                                <td><%=h(ps.get("examName"))%></td>
                                <td><%=h(ps.get("subject"))%> &mdash; <%=h(ps.get("batch"))%></td>
                                <td><span style="font-weight:700;color:#047857;"><%=ps.get("correctAnswers")%>/<%=ps.get("totalQuestions")%> correct</span></td>
                                <td><i class="fa-regular fa-clock" style="font-size:11px;color:#9ca3af;margin-right:4px;"></i><%=h(ps.get("submittedAt"))%></td>
                                <td style="text-align:right;">
                                    <a href="<%=contextPath%>/tutor/marks?examId=<%=ps.get("examId")%>" class="btn-solid sm" style="background:#7c3aed;text-decoration:none;display:inline-flex;align-items:center;gap:5px;">
                                        <i class="fa-solid fa-pen-to-square"></i> Review &amp; Enter Marks
                                    </a>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            <% } %>

            <div class="grid-2">
                <div class="card">
                    <div class="card-head">
                        <h2><i class="fa-solid fa-book-open" style="color:var(--primary);font-size:15px;"></i> My Academic Classes</h2>
                        <button type="button" class="link-btn" data-goto="classes">View all <i class="fa-solid fa-chevron-right" style="font-size:11px;"></i></button>
                    </div>
                    <ul class="class-list">
                        <% if(classes.isEmpty()){ %>
                            <li class="muted">No assigned classes found.</li>
                        <% } else for(int i=0; i<Math.min(6, classes.size()); i++){ Map<String,Object> r=classes.get(i); %>
                            <li>
                                <div class="subject-icon icon-violet"><i class="fa-solid fa-book-open"></i></div>
                                <div class="class-info">
                                    <span class="class-name"><%=h(r.get("subject"))%> &mdash; <%=h(r.get("batch"))%></span>
                                    <span class="class-meta"><i class="fa-solid fa-folder-open"></i> <%=integer(r.get("materialCount"))%> uploaded materials</span>
                                </div>
                                <span class="amount" style="background:#f1f5f9;padding:4px 10px;border-radius:8px;font-size:12.5px;"><%=integer(r.get("studentCount"))%> students</span>
                            </li>
                        <% } %>
                    </ul>
                </div>

                <div class="card">
                    <div class="card-head">
                        <h2><i class="fa-regular fa-bell" style="color:var(--secondary);font-size:15px;"></i> Teaching Notifications</h2>
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

            <div class="card">
                <div class="card-head">
                    <h2><i class="fa-solid fa-hand-holding-dollar" style="color:var(--primary);font-size:15px;"></i> Monthly Collected Fees for My Classes</h2>
                    <span class="card-date">Current Billing Cycle</span>
                </div>
                <span class="stat-value" style="color:#16a34a;"><%=money(summary.get("monthlyCollected"))%></span>
            </div>
        </section>

        <!-- VIEW: CLASSES -->
        <section class="view" data-view="classes">
            <div class="card">
                <div class="card-head">
                    <h2><i class="fa-solid fa-book-open" style="color:var(--primary);font-size:16px;"></i> My Assigned Classes</h2>
                    <span class="card-date"><%=classes.size()%> records</span>
                </div>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Class</th>
                                <th>Schedule</th>
                                <th>Fee</th>
                                <th>Students</th>
                                <th>Materials</th>
                                <th>Live Class Link</th>
                                <th>Status</th>
                                <th style="text-align:right;">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if(classes.isEmpty()){ %>
                                <tr><td colspan="8" class="muted">No assigned classes found.</td></tr>
                            <% } else for(Map<String,Object> r:classes){ 
                                String rawLink = r.get("meetingLink") != null ? String.valueOf(r.get("meetingLink")).trim() : "";
                                String mLink = service.ClassService.extractAndNormalizeMeetingLink(rawLink);
                                if (mLink == null) mLink = "";
                                boolean hasLink = !mLink.isEmpty();
                                String cType = "WEEKEND".equalsIgnoreCase(String.valueOf(r.get("classType"))) ? "Weekend" : "Weekday";
                            %>
                                <tr>
                                    <td><strong><%=h(r.get("subject"))%></strong> &mdash; <%=h(r.get("batch"))%></td>
                                    <td><span class="badge <%= "Weekend".equals(cType) ? "badge-pending" : "badge-neutral" %>"><%=cType%></span></td>
                                    <td class="mono"><%=money(r.get("fee"))%></td>
                                    <td><span style="font-weight:700;"><%=integer(r.get("studentCount"))%></span></td>
                                    <td><span style="font-weight:700;"><%=integer(r.get("materialCount"))%></span></td>
                                    <td>
                                        <% if(hasLink){ %>
                                            <a href="<%=h(mLink)%>" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:6px;color:#2563eb;font-weight:700;font-size:12.5px;text-decoration:none;">
                                                <i class="fa-solid fa-video"></i> Active Link <i class="fa-solid fa-arrow-up-right-from-square" style="font-size:10px;"></i>
                                            </a>
                                        <% } else { %>
                                            <span class="muted" style="font-size:12.5px;"><i class="fa-solid fa-video-slash"></i> Not set</span>
                                        <% } %>
                                    </td>
                                    <td><span class="badge <%=badge(r.get("status"))%>"><%=h(r.get("status"))%></span></td>
                                    <td style="text-align:right;">
                                        <button type="button" class="btn-outline sm" onclick="openMeetingModal(<%=r.get("classId")%>, '<%=h(r.get("subject"))%> &mdash; <%=h(r.get("batch"))%>', '<%=h(mLink)%>')">
                                            <i class="fa-solid fa-link"></i> <%=hasLink ? "Update Link" : "Add Link"%>
                                        </button>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </section>

        <!-- VIEW: STUDENTS -->
        <section class="view" data-view="students">
            <div class="card">
                <div class="card-head">
                    <h2><i class="fa-solid fa-users" style="color:var(--secondary);font-size:16px;"></i> Enrolled Students</h2>
                    <span class="card-date"><%=students.size()%> records</span>
                </div>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Student</th>
                                <th>Email</th>
                                <th>Phone</th>
                                <th>Enrolled Classes</th>
                                <th>Attendance Rate</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if(students.isEmpty()){ %>
                                <tr><td colspan="5" class="muted">No enrolled students found.</td></tr>
                            <% } else for(Map<String,Object> r:students){ %>
                                <tr>
                                    <td><strong><%=h(r.get("studentName"))%></strong></td>
                                    <td><%=h(r.get("email"))%></td>
                                    <td><%=h(r.get("phone"))%></td>
                                    <td><span style="font-weight:700;"><%=integer(r.get("classCount"))%></span></td>
                                    <td><span style="font-weight:700;color:var(--primary);"><%=pct(r.get("attendanceRate"))%></span></td>
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
                    <h2><i class="fa-regular fa-calendar-days" style="color:var(--primary);font-size:16px;"></i> My Timetable &amp; Schedule</h2>
                    <span class="card-date"><%=timetable.size()%> assigned slots</span>
                </div>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Day &amp; Time</th>
                                <th>Class</th>
                                <th>Room</th>
                                <th>Clash Status</th>
                                <th>Confirmation</th>
                                <th style="text-align:right;">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if(timetable.isEmpty()){ %>
                                <tr><td colspan="6" class="muted">No timetable slots found.</td></tr>
                            <% } else {
                                for(int i=0; i<timetable.size(); i++){
                                    Map<String,Object> r = timetable.get(i);
                                    String day = String.valueOf(r.get("dayOfWeek"));
                                    String start = String.valueOf(r.get("startTime"));
                                    String end = String.valueOf(r.get("endTime"));
                                    String confStatus = r.get("confirmationStatus") != null ? String.valueOf(r.get("confirmationStatus")) : "CONFIRMED";
                                    int sId = integer(r.get("slotId"));

                                    boolean isClash = false;
                                    String clashWith = "";
                                    for(int j=0; j<timetable.size(); j++){
                                        if(i != j){
                                            Map<String,Object> o = timetable.get(j);
                                            if(day.equalsIgnoreCase(String.valueOf(o.get("dayOfWeek")))){
                                                String oStart = String.valueOf(o.get("startTime"));
                                                String oEnd = String.valueOf(o.get("endTime"));
                                                if(start.compareTo(oEnd) < 0 && end.compareTo(oStart) > 0){
                                                    isClash = true;
                                                    clashWith = String.valueOf(o.get("subject")) + " (" + oStart + "–" + oEnd + ")";
                                                    break;
                                                }
                                            }
                                        }
                                    }
                            %>
                                <tr>
                                    <td>
                                        <strong><%=h(day)%></strong>
                                        <div style="font-size:12px;color:var(--text-secondary);margin-top:2px;">
                                            <i class="fa-regular fa-clock"></i> <%=h(start)%> &ndash; <%=h(end)%>
                                        </div>
                                    </td>
                                    <td>
                                        <strong><%=h(r.get("subject"))%></strong>
                                        <div style="font-size:12px;color:var(--text-secondary);"><%=h(r.get("batch"))%></div>
                                    </td>
                                    <td>
                                        <% if(r.get("room")!=null && !String.valueOf(r.get("room")).isBlank()){ %>
                                            <span style="display:inline-flex;align-items:center;gap:4px;font-size:12.5px;color:var(--dark);">
                                                <i class="fa-solid fa-location-dot" style="color:var(--primary);"></i> <%=h(r.get("room"))%>
                                            </span>
                                        <% } else { %>
                                            <span class="muted" style="font-size:12px;">Not assigned</span>
                                        <% } %>
                                    </td>
                                    <td>
                                        <% if(isClash){ %>
                                            <span class="badge badge-absent" title="Clashes with <%=h(clashWith)%>">
                                                <i class="fa-solid fa-triangle-exclamation"></i> Clash (<%=h(clashWith)%>)
                                            </span>
                                        <% } else { %>
                                            <span class="badge badge-paid">
                                                <i class="fa-solid fa-circle-check"></i> Free Slot
                                            </span>
                                        <% } %>
                                    </td>
                                    <td>
                                        <% if("CONFIRMED".equalsIgnoreCase(confStatus)){ %>
                                            <span class="badge badge-paid"><i class="fa-solid fa-circle-check"></i> Confirmed</span>
                                        <% } else if("CHANGE_SUGGESTED".equalsIgnoreCase(confStatus)){ %>
                                            <div style="display:flex;flex-direction:column;gap:3px;">
                                                <span class="badge badge-live"><i class="fa-solid fa-arrows-rotate"></i> Suggestion Sent</span>
                                                <span style="font-size:11px;color:#6b21a8;line-height:1.2;">Proposed: <%=h(r.get("suggestedDay"))%> <%=h(r.get("suggestedStartTime"))%>–<%=h(r.get("suggestedEndTime"))%></span>
                                            </div>
                                        <% } else { %>
                                            <span class="badge badge-pending"><i class="fa-regular fa-clock"></i> Pending Review</span>
                                        <% } %>
                                    </td>
                                    <td style="text-align:right;">
                                        <div style="display:inline-flex;align-items:center;gap:6px;">
                                            <% if("PENDING".equalsIgnoreCase(confStatus)){ %>
                                                <form action="<%=contextPath%>/tutor/timetable-action" method="post" style="display:inline;margin:0;">
                                                    <input type="hidden" name="action" value="confirm">
                                                    <input type="hidden" name="slotId" value="<%=sId%>">
                                                    <button type="submit" class="btn-solid sm" style="background:#16a34a;">
                                                        <i class="fa-solid fa-check"></i> Confirm
                                                    </button>
                                                </form>
                                                <button type="button" class="btn-outline sm" onclick="openSuggestModal(<%=sId%>, '<%=h(r.get("subject"))%> — <%=h(r.get("batch"))%>', '<%=h(day)%>', '<%=h(start)%>', '<%=h(end)%>', '')">
                                                    <i class="fa-regular fa-clock"></i> Suggest Time
                                                </button>
                                            <% } else if("CHANGE_SUGGESTED".equalsIgnoreCase(confStatus)){ %>
                                                <button type="button" class="btn-outline sm" onclick="openSuggestModal(<%=sId%>, '<%=h(r.get("subject"))%> — <%=h(r.get("batch"))%>', '<%=h(r.get("suggestedDay"))%>', '<%=h(r.get("suggestedStartTime"))%>', '<%=h(r.get("suggestedEndTime"))%>', '<%=h(r.get("tutorNote"))%>')">
                                                    <i class="fa-solid fa-pen"></i> Edit Suggestion
                                                </button>
                                            <% } else { %>
                                                <button type="button" class="btn-outline sm" onclick="openSuggestModal(<%=sId%>, '<%=h(r.get("subject"))%> — <%=h(r.get("batch"))%>', '<%=h(day)%>', '<%=h(start)%>', '<%=h(end)%>', '')">
                                                    <i class="fa-solid fa-repeat"></i> Suggest Change
                                                </button>
                                            <% } %>
                                        </div>
                                    </td>
                                </tr>
                            <% } } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </section>

        <!-- VIEW: ATTENDANCE -->
        <section class="view" data-view="attendance">
            <div class="card">
                <div class="card-head">
                    <h2><i class="fa-solid fa-user-check" style="color:var(--secondary);font-size:16px;"></i> Class Attendance Log</h2>
                    <a class="btn-solid sm" href="<%=contextPath%>/attendance"><i class="fa-solid fa-clipboard-user"></i> Open Attendance Module</a>
                </div>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Date</th>
                                <th>Class</th>
                                <th>Student</th>
                                <th>Status</th>
                                <th>Remarks</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if(attendance.isEmpty()){ %>
                                <tr><td colspan="5" class="muted">No attendance records found.</td></tr>
                            <% } else for(Map<String,Object> r:attendance){ %>
                                <tr>
                                    <td><%=h(r.get("sessionDate"))%></td>
                                    <td><%=h(r.get("subject"))%> &mdash; <%=h(r.get("batch"))%></td>
                                    <td><strong><%=h(r.get("studentName"))%></strong></td>
                                    <td><span class="badge <%=badge(r.get("status"))%>"><%=h(r.get("status"))%></span></td>
                                    <td><%=h(r.get("remarks"))%></td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </section>

        <!-- VIEW: EXAMS -->
        <section class="view" data-view="exams">
            <div class="card">
                <div class="card-head">
                    <h2><i class="fa-solid fa-award" style="color:var(--primary);font-size:16px;"></i> My Examinations &amp; Marks Entry</h2>
                    <a class="btn-solid sm" href="<%=contextPath%>/tutor/exams"><i class="fa-solid fa-calendar-plus"></i> Schedule New Exam</a>
                </div>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Exam</th>
                                <th>Class</th>
                                <th>Date</th>
                                <th>Max Marks</th>
                                <th>Submissions &amp; Results</th>
                                <th>Status</th>
                                <th style="text-align:right;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if(exams.isEmpty()){ %>
                                <tr><td colspan="7" class="muted">No exams found.</td></tr>
                            <% } else for(Map<String,Object> r:exams){ 
                                int rCount = integer(r.get("resultCount"));
                                int sCount = integer(r.get("submissionCount"));
                                int pCount = integer(r.get("pendingReviewCount"));
                                String st = String.valueOf(r.get("status"));
                                boolean isCompleted = "COMPLETED".equalsIgnoreCase(st);
                            %>
                                <tr>
                                    <td><strong><%=h(r.get("examName"))%></strong></td>
                                    <td><%=h(r.get("subject"))%> &mdash; <%=h(r.get("batch"))%></td>
                                    <td><%=h(r.get("examDate"))%></td>
                                    <td class="mono"><%=h(r.get("maxMarks"))%></td>
                                    <td>
                                        <span style="font-weight:700;"><%=sCount%> Submissions</span>
                                        <span style="color:#64748b;font-size:12px;">(<%=rCount%> graded)</span>
                                        <% if (pCount > 0) { %>
                                            <span class="badge" style="background:#fef3c7;color:#b45309;font-size:11px;margin-left:4px;">
                                                <i class="fa-solid fa-clock"></i> <%=pCount%> pending
                                            </span>
                                        <% } %>
                                    </td>
                                    <td><span class="badge <%=badge(r.get("status"))%>"><%=h(r.get("status"))%></span></td>
                                    <td style="text-align:right;">
                                        <div style="display:inline-flex;align-items:center;gap:6px;">
                                            <% if (sCount > 0 || isCompleted) { %>
                                                <a href="<%=contextPath%>/tutor/marks?examId=<%=r.get("examId")%>" class="btn-solid sm" style="background:#7c3aed;text-decoration:none;">
                                                    <i class="fa-solid fa-pen-to-square"></i> Review &amp; Enter Marks
                                                </a>
                                            <% } else { %>
                                                <span class="badge badge-neutral" style="font-size:11px;"><i class="fa-regular fa-clock"></i> Awaiting Submissions</span>
                                            <% } %>
                                            <% if (!isCompleted) { %>
                                                <a href="<%=contextPath%>/tutor/mcq?examId=<%=r.get("examId")%>" class="btn-outline sm" style="text-decoration:none;">
                                                    <i class="fa-solid fa-list-check"></i> Manage Quiz
                                                </a>
                                            <% } %>
                                        </div>
                                    </td>
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
                        <h2><i class="fa-regular fa-bell" style="color:var(--primary);font-size:16px;"></i> Faculty Notifications</h2>
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

<!-- LIVE CLASS MEETING MODAL -->
<div class="modal-overlay" id="meetingModal" style="display:none;position:fixed;inset:0;background:rgba(15,23,42,0.6);backdrop-filter:blur(4px);z-index:9999;align-items:center;justify-content:center;">
  <div class="modal-card" style="background:#fff;border-radius:18px;width:100%;max-width:480px;padding:26px;box-shadow:var(--shadow-lg);margin:20px;position:relative;">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">
      <h3 style="margin:0;font-size:18px;font-weight:700;display:flex;align-items:center;gap:8px;color:#0f172a;">
        <i class="fa-solid fa-video" style="color:#2563eb;"></i> Live Class Link (Zoom / Meet)
      </h3>
      <button type="button" onclick="closeMeetingModal()" style="border:none;background:none;font-size:22px;cursor:pointer;color:#64748b;line-height:1;">&times;</button>
    </div>
    <p id="modalClassName" style="font-size:13.5px;color:#64748b;margin:0 0 16px 0;font-weight:600;"></p>
    <form action="<%=contextPath%>/tutor/class-link" method="post">
      <input type="hidden" name="classId" id="modalClassId">
      <div style="margin-bottom:16px;">
        <label style="display:block;font-size:13px;font-weight:600;color:#334155;margin-bottom:6px;">
          Meeting URL (Zoom / Google Meet)
        </label>
        <textarea name="meetingLink" id="modalMeetingLink" rows="3" placeholder="Paste link or full Zoom invitation here (e.g. https://zoom.us/j/...)" style="width:100%;padding:10px 14px;border:1.5px solid var(--border-color);border-radius:10px;font-size:13.5px;box-sizing:border-box;resize:vertical;font-family:inherit;"></textarea>
        <div id="modalLinkDetected" style="display:none;margin-top:8px;padding:8px 12px;background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;font-size:12px;color:#15803d;">
          <div style="font-weight:700;display:flex;align-items:center;gap:6px;margin-bottom:2px;">
            <i class="fa-solid fa-circle-check"></i> Clean URL Detected:
          </div>
          <span id="modalDetectedUrl" style="word-break:break-all;font-family:monospace;color:#166534;"></span>
        </div>
        <span style="display:block;font-size:12px;color:#94a3b8;margin-top:6px;">You can paste the entire Zoom invitation text or direct URL. The system automatically extracts the clean link. Leave blank and save to remove.</span>
      </div>
      <div style="display:flex;justify-content:flex-end;gap:10px;margin-top:20px;">
        <button type="button" onclick="closeMeetingModal()" class="btn-outline sm">Cancel</button>
        <button type="submit" class="btn-solid sm" style="background:#2563eb;"><i class="fa-solid fa-floppy-disk"></i> Save Link</button>
      </div>
    </form>
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
                    <span style="font-size:12px;color:#64748b;font-weight:600;"><%=currentUser != null && currentUser.getRole() != null ? currentUser.getRole() : "Tutor"%> Profile</span>
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

<!-- SUGGEST TIMETABLE CHANGE MODAL -->
<div class="modal-overlay" id="suggestModal" style="display:none;position:fixed;inset:0;background:rgba(15,23,42,0.6);backdrop-filter:blur(4px);z-index:9999;align-items:center;justify-content:center;">
  <div class="modal-card" style="background:#fff;border-radius:18px;width:100%;max-width:480px;padding:26px;box-shadow:var(--shadow-lg);margin:20px;position:relative;">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">
      <h3 style="margin:0;font-size:18px;font-weight:700;display:flex;align-items:center;gap:8px;color:#0f172a;">
        <i class="fa-regular fa-calendar-days" style="color:#2563eb;"></i> Suggest Alternative Time
      </h3>
      <button type="button" onclick="closeSuggestModal()" style="border:none;background:none;font-size:22px;cursor:pointer;color:#64748b;line-height:1;">&times;</button>
    </div>
    <div style="background:#f8fafc;border:1px solid #e2e8f0;padding:10px 14px;border-radius:10px;margin-bottom:16px;">
      <span style="font-size:12px;color:#64748b;font-weight:600;display:block;">Assigned Class</span>
      <span id="suggestClassName" style="font-size:14px;font-weight:700;color:#0f172a;"></span>
    </div>
    <form action="<%=contextPath%>/tutor/timetable-action" method="post">
      <input type="hidden" name="action" value="suggest">
      <input type="hidden" name="slotId" id="suggestSlotId">
      <div style="margin-bottom:14px;">
        <label style="display:block;font-size:13px;font-weight:600;color:#334155;margin-bottom:6px;">Preferred Day of Week</label>
        <select name="suggestedDay" id="suggestDay" required style="width:100%;padding:10px 14px;border:1.5px solid var(--border-color);border-radius:10px;font-size:13.5px;box-sizing:border-box;background:#fff;">
          <option value="MON">Monday</option>
          <option value="TUE">Tuesday</option>
          <option value="WED">Wednesday</option>
          <option value="THU">Thursday</option>
          <option value="FRI">Friday</option>
          <option value="SAT">Saturday</option>
          <option value="SUN">Sunday</option>
        </select>
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:14px;">
        <div>
          <label style="display:block;font-size:13px;font-weight:600;color:#334155;margin-bottom:6px;">Start Time</label>
          <input type="time" name="suggestedStartTime" id="suggestStartTime" required style="width:100%;padding:10px 14px;border:1.5px solid var(--border-color);border-radius:10px;font-size:13.5px;box-sizing:border-box;">
        </div>
        <div>
          <label style="display:block;font-size:13px;font-weight:600;color:#334155;margin-bottom:6px;">End Time</label>
          <input type="time" name="suggestedEndTime" id="suggestEndTime" required style="width:100%;padding:10px 14px;border:1.5px solid var(--border-color);border-radius:10px;font-size:13.5px;box-sizing:border-box;">
        </div>
      </div>
      <div style="margin-bottom:18px;">
        <label style="display:block;font-size:13px;font-weight:600;color:#334155;margin-bottom:6px;">Reason / Note for Administrator</label>
        <textarea name="tutorNote" id="suggestNote" rows="3" placeholder="e.g. I have another lecture at this hour, could we do Tuesday after 2 PM?" style="width:100%;padding:10px 14px;border:1.5px solid var(--border-color);border-radius:10px;font-size:13.5px;box-sizing:border-box;resize:vertical;"></textarea>
      </div>
      <div style="display:flex;justify-content:flex-end;gap:10px;">
        <button type="button" onclick="closeSuggestModal()" class="btn-outline sm">Cancel</button>
        <button type="submit" class="btn-solid sm" style="background:#2563eb;"><i class="fa-solid fa-paper-plane"></i> Send Suggestion</button>
      </div>
    </form>
  </div>
</div>

<script>
function checkMeetingInput(el) {
  if (!el) return;
  const text = el.value.trim();
  const box = document.getElementById('modalLinkDetected');
  const span = document.getElementById('modalDetectedUrl');
  if (!text) {
    if (box) box.style.display = 'none';
    return;
  }
  const matches = text.match(/https?:\/\/[^\s"'>]+/gi);
  let best = null;
  if (matches && matches.length > 0) {
    best = matches.find(u => u.includes('zoom.us/j/') || u.includes('zoom.us/my/') || u.includes('zoom.us/w/'))
        || matches.find(u => u.includes('meet.google.com/'))
        || matches.find(u => u.includes('teams.microsoft.com/'))
        || matches.find(u => u.includes('zoom.us'))
        || matches[0];
    best = best.replace(/[.,;)>]+$/, '');
  } else {
    const noSchemeMatch = text.match(/(?:[a-zA-Z0-9_-]+\.)+(?:zoom\.us|google\.com|microsoft\.com|webex\.com)(?:\/[^\s"'>]*)?/i);
    if (noSchemeMatch) {
      best = 'https://' + noSchemeMatch[0].replace(/[.,;)>]+$/, '');
    } else if (!text.includes(' ') && text.includes('.') && text.indexOf('.') < text.length - 2) {
      best = text.startsWith('http://') || text.startsWith('https://') ? text : ('https://' + text);
    }
  }

  if (best) {
    if (span) span.textContent = best;
    if (box) box.style.display = 'block';
  } else {
    if (box) box.style.display = 'none';
  }
}

function openMeetingModal(classId, className, currentLink) {
  document.getElementById('modalClassId').value = classId;
  document.getElementById('modalClassName').textContent = className;
  const input = document.getElementById('modalMeetingLink');
  input.value = currentLink || '';
  checkMeetingInput(input);
  document.getElementById('meetingModal').style.display = 'flex';
}
function closeMeetingModal() {
  document.getElementById('meetingModal').style.display = 'none';
}

document.addEventListener('DOMContentLoaded', function() {
  const mInput = document.getElementById('modalMeetingLink');
  if (mInput) {
    mInput.addEventListener('input', function() { checkMeetingInput(this); });
    mInput.addEventListener('paste', function() { setTimeout(() => checkMeetingInput(this), 10); });
  }
});
function openSuggestModal(slotId, className, day, start, end, note) {
  document.getElementById('suggestSlotId').value = slotId;
  document.getElementById('suggestClassName').textContent = className;
  if (day) document.getElementById('suggestDay').value = day.toUpperCase();
  if (start) document.getElementById('suggestStartTime').value = start;
  if (end) document.getElementById('suggestEndTime').value = end;
  if (note) document.getElementById('suggestNote').value = note;
  document.getElementById('suggestModal').style.display = 'flex';
}
function closeSuggestModal() {
  document.getElementById('suggestModal').style.display = 'none';
}
</script>
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
<script src="<%=contextPath%>/js/dashboard-tutor.js?v=2.2"></script>
<script src="<%=contextPath%>/js/profile.js?v=2.2"></script>
</body>
</html>
