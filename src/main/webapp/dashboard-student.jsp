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
        if (name == null || name.trim().isEmpty()) return "ST";
        String[] parts = name.trim().split("\\s+");
        if (parts.length == 1) {
            return parts[0].substring(0, Math.min(2, parts[0].length())).toUpperCase();
        }
        return ("" + parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
    }
    private String getCourseImage(Object imagePathObj, Object subjectObj, String contextPath) {
        if (imagePathObj != null && !String.valueOf(imagePathObj).isBlank()) {
            return contextPath + "/" + String.valueOf(imagePathObj).trim();
        }
        if (subjectObj == null) return contextPath + "/images/courses/default.jpg";
        String s = String.valueOf(subjectObj).toLowerCase().trim();
        if (s.contains("math") || s.contains("ganithaya")) return contextPath + "/images/courses/maths.jpg";
        if (s.contains("sci") || s.contains("vidyawa") || s.contains("physics") || s.contains("chem") || s.contains("bio")) return contextPath + "/images/courses/science.jpg";
        if (s.contains("it") || s.contains("comp") || s.contains("tech") || s.contains("ai") || s.contains("prog") || s.contains("soft")) return contextPath + "/images/courses/it.jpg";
        if (s.contains("eng") || s.contains("lit") || s.contains("lang")) return contextPath + "/images/courses/english.jpg";
        return contextPath + "/images/courses/default.jpg";
    }
    private String getCourseImage(Object subjectObj, String contextPath) {
        return getCourseImage(null, subjectObj, contextPath);
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
    private boolean isWeekendClass(Map<String, Object> c) {
        if (c == null) return false;
        String type = String.valueOf(c.get("classType"));
        if ("WEEKEND".equalsIgnoreCase(type)) return true;
        if ("WEEKDAY".equalsIgnoreCase(type)) return false;
        String batch = String.valueOf(c.get("batch")).toLowerCase();
        if (batch.contains("weekend")) return true;
        String sched = String.valueOf(c.get("classSchedule")).toUpperCase();
        if (sched.contains("SAT") || sched.contains("SUN")) return true;
        return false;
    }
    private String cleanBatchName(Object batchObj) {
        if (batchObj == null) return "";
        String b = String.valueOf(batchObj).trim();
        return b.replaceAll("(?i)\\s*\\((weekend|weekday)\\)", "").trim();
    }
    private String cleanMeetingUrl(Object linkObj) {
        if (linkObj == null) return null;
        return service.ClassService.extractAndNormalizeMeetingLink(String.valueOf(linkObj));
    }
%>
<%
    String contextPath=request.getContextPath();
    User currentUser = (User) request.getAttribute("currentUser");
    Map<String,Object> dashboardData=(Map<String,Object>)request.getAttribute("dashboardData"); if(dashboardData==null)dashboardData=new LinkedHashMap<>();
    Map<String,Object> summary=(Map<String,Object>)dashboardData.getOrDefault("summary",new LinkedHashMap<String,Object>());
    Map<String,Object> student=(Map<String,Object>)dashboardData.getOrDefault("student",new LinkedHashMap<String,Object>());
    List<Map<String,Object>> classes=(List<Map<String,Object>>)dashboardData.getOrDefault("classes",Collections.emptyList());
    List<Map<String,Object>> weekdayClasses = new ArrayList<>();
    List<Map<String,Object>> weekendClasses = new ArrayList<>();
    for (Map<String,Object> c : classes) {
        if (isWeekendClass(c)) {
            weekendClasses.add(c);
        } else {
            weekdayClasses.add(c);
        }
    }
    List<Map<String,Object>> materials=(List<Map<String,Object>>)dashboardData.getOrDefault("materials",Collections.emptyList());
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
    String userName=String.valueOf(session.getAttribute("userName")==null?"Student":session.getAttribute("userName"));
    String dashboardError=(String)request.getAttribute("dashboardError");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1.0">
    <title>Student Dashboard — Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%=contextPath%>/css/dashboard.css?v=2.2">
    <link rel="stylesheet" href="<%=contextPath%>/css/dashboard-student.css?v=3.0">
    <style>
        /* Force high contrast and prevent browser visited link overrides on action buttons */
        a.quiz-btn, a.quiz-btn:link, a.quiz-btn:visited, a.quiz-btn:hover, a.quiz-btn:active,
        a.btn-solid, a.btn-solid:link, a.btn-solid:visited, a.btn-solid:hover, a.btn-solid:active {
            color: #ffffff !important;
            text-decoration: none !important;
        }
        a.quiz-btn *, a.btn-solid * {
            color: #ffffff !important;
            text-decoration: none !important;
        }
        .data-table td a.quiz-btn {
            color: #ffffff !important;
            text-decoration: none !important;
        }

        /* Schedule Tabs Bar */
        .lms-tabs-bar {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 22px;
            flex-wrap: wrap;
        }
        .lms-tab-btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 9px 18px;
            border-radius: 12px;
            font-size: 13.5px;
            font-weight: 600;
            color: #64748b;
            background: #ffffff;
            border: 1px solid #e2e8f0;
            cursor: pointer;
            transition: all 0.2s ease;
            box-shadow: 0 1px 2px rgba(0,0,0,0.03);
            font-family: inherit;
        }
        .lms-tab-btn:hover {
            background: #f8fafc;
            color: #1e293b;
            border-color: #cbd5e1;
        }
        .lms-tab-btn.active {
            background: #7c3aed !important;
            color: #ffffff !important;
            border-color: #7c3aed !important;
            box-shadow: 0 4px 12px rgba(124, 58, 237, 0.25) !important;
        }
        .lms-tab-btn .tab-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 20px;
            height: 20px;
            padding: 0 6px;
            border-radius: 10px;
            font-size: 11.5px;
            font-weight: 700;
            background: #f1f5f9;
            color: #475569;
        }
        .lms-tab-btn.active .tab-badge {
            background: rgba(255, 255, 255, 0.25) !important;
            color: #ffffff !important;
        }

        /* Schedule Badge on Thumbnail */
        .course-badge-schedule {
            position: absolute;
            top: 12px;
            right: 12px;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 4px 10px;
            border-radius: 8px;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.02em;
            backdrop-filter: blur(8px);
            z-index: 2;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2);
        }
        .course-badge-schedule.weekday {
            background: rgba(67, 56, 202, 0.92);
            color: #ffffff;
        }
        .course-badge-schedule.weekend {
            background: rgba(217, 119, 6, 0.92);
            color: #ffffff;
        }

        /* Table Schedule Badges */
        .badge-schedule {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 3px 9px;
            border-radius: 6px;
            font-size: 11.5px;
            font-weight: 700;
            letter-spacing: 0.02em;
            white-space: nowrap;
        }
        .badge-weekday {
            background: #eef2ff;
            color: #4338ca;
            border: 1px solid #c7d2fe;
        }
        .badge-weekend {
            background: #fffbeb;
            color: #b45309;
            border: 1px solid #fde68a;
        }
    </style>
</head>
<body class="dash-body">

<aside class="sidebar" id="sidebar">
    <div class="sidebar-top">
        <div class="auth-logo sidebar-logo">
            <div class="logo-mark">C</div>
            <div class="logo-text">
                <span class="logo-title">Classora</span>
                <span class="logo-sub">Student Portal</span>
            </div>
        </div>
        <button class="sidebar-close" id="sidebarClose"><i class="fa-solid fa-xmark"></i></button>
    </div>
    
    <nav class="sidebar-nav">
        <span class="sidebar-label">Learning</span>
        <button class="nav-item is-active" data-view="overview"><i class="fa-solid fa-gauge-high"></i><span>Overview</span></button>
        <button class="nav-item" data-view="classes"><i class="fa-solid fa-book-open"></i><span>My Classes</span></button>
        <button class="nav-item" data-view="timetable"><i class="fa-regular fa-calendar-days"></i><span>Timetable</span></button>
        <button class="nav-item" data-view="attendance"><i class="fa-solid fa-user-check"></i><span>Attendance</span></button>
        <button class="nav-item" data-view="fees"><i class="fa-solid fa-wallet"></i><span>Fees &amp; Payments</span></button>
        <button class="nav-item" data-view="results"><i class="fa-solid fa-award"></i><span>Exams &amp; Results</span></button>
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
                <span class="sidebar-user-role">Student</span>
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
            <p id="pageSub">Your personalized learning hub and course telemetry.</p>
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
        <% 
            Object flashSuccess = session.getAttribute("flashSuccess");
            if (flashSuccess != null) {
                session.removeAttribute("flashSuccess");
        %>
            <div class="card" style="background:#f0fdf4;border:1px solid #bbf7d0;padding:14px 18px;border-radius:14px;margin-bottom:20px;display:flex;align-items:center;gap:12px;">
                <i class="fa-solid fa-circle-check" style="color:#16a34a;font-size:20px;"></i>
                <div style="color:#15803d;font-weight:600;font-size:14px;"><%=h(flashSuccess)%></div>
            </div>
        <% } %>
        <% if(dashboardError!=null){ %>
            <div class="card" style="margin-bottom:20px;border-color:#fecaca;background:#fef2f2;">
                <span class="badge badge-absent"><i class="fa-solid fa-circle-exclamation"></i> <%=h(dashboardError)%></span>
            </div>
        <% } %>

        <!-- VIEW: OVERVIEW -->
        <section class="view is-active" data-view="overview">
            <div class="stat-grid">
                <div class="stat-card">
                    <div class="stat-icon icon-violet"><i class="fa-solid fa-book-open"></i></div>
                    <span class="stat-label">Enrolled Classes</span>
                    <span class="stat-value"><%=integer(summary.get("classCount"))%></span>
                    <span class="stat-meta up"><i class="fa-solid fa-circle-check"></i> Active academic streams</span>
                </div>
                <div class="stat-card">
                    <div class="stat-icon icon-blue"><i class="fa-solid fa-user-check"></i></div>
                    <span class="stat-label">Attendance Rate</span>
                    <span class="stat-value"><%=pct(summary.get("attendanceRate"))%></span>
                    <span class="stat-meta"><i class="fa-solid fa-clock"></i> Present &amp; on-time record</span>
                </div>
                <div class="stat-card">
                    <div class="stat-icon icon-amber"><i class="fa-solid fa-wallet"></i></div>
                    <span class="stat-label">Outstanding Fees</span>
                    <span class="stat-value"><%=money(summary.get("outstandingBalance"))%></span>
                    <span class="stat-meta warn"><i class="fa-solid fa-circle-info"></i> Active invoice balance</span>
                </div>
                <div class="stat-card">
                    <div class="stat-icon icon-cyan"><i class="fa-solid fa-award"></i></div>
                    <span class="stat-label">Exam Average</span>
                    <span class="stat-value"><%=pct(summary.get("resultAverage"))%></span>
                    <span class="stat-meta up"><i class="fa-solid fa-arrow-trend-up"></i> <%=integer(summary.get("upcomingExams"))%> upcoming exams</span>
                </div>
            </div>

            <div class="grid-2">
                <div class="card">
                    <div class="card-head">
                        <h2><i class="fa-solid fa-book-open" style="color:var(--primary);font-size:15px;"></i> My Enrolled Classes</h2>
                        <button type="button" class="link-btn" data-goto="classes">View all <i class="fa-solid fa-chevron-right" style="font-size:11px;"></i></button>
                    </div>
                    <ul class="class-list">
                        <% if(classes.isEmpty()){ %>
                            <li class="muted">No active class enrollments found.</li>
                        <% } else for(int i=0; i<Math.min(6, classes.size()); i++){ Map<String,Object> r=classes.get(i); %>
                            <li style="display:flex; justify-content:space-between; align-items:center;">
                                <div style="display:flex; align-items:center; gap:14px; min-width:0;">
                                    <img src="<%=getCourseImage(r.get("imagePath"), r.get("subject"), contextPath)%>" style="width:54px; height:38px; object-fit:cover; border-radius:8px; box-shadow:0 2px 4px rgba(0,0,0,.08); flex-shrink:0;" alt="">
                                    <div style="min-width:0;">
                                        <a href="<%=contextPath%>/classes/view?id=<%=r.get("classId")%>" style="text-decoration:none;">
                                            <span class="class-name" style="display:flex; align-items:center; gap:8px;">
                                                <%=h(r.get("subject"))%> &mdash; <%=h(cleanBatchName(r.get("batch")))%>
                                                <% if(isWeekendClass(r)) { %>
                                                    <span class="badge-schedule badge-weekend" style="font-size:10.5px;padding:2px 7px;"><i class="fa-solid fa-mug-hot"></i> Weekend</span>
                                                <% } else { %>
                                                    <span class="badge-schedule badge-weekday" style="font-size:10.5px;padding:2px 7px;"><i class="fa-solid fa-calendar-day"></i> Weekday</span>
                                                <% } %>
                                                <% 
                                                    String mLiveLink = cleanMeetingUrl(r.get("meetingLink"));
                                                    if(mLiveLink != null && !mLiveLink.isBlank()){ 
                                                %>
                                                    <span style="background:#dcfce7;color:#15803d;font-size:10px;font-weight:700;padding:2px 7px;border-radius:10px;"><i class="fa-solid fa-video" style="font-size:9px;"></i> Live</span>
                                                <% } %>
                                            </span>
                                        </a>
                                        <div style="display:flex;align-items:center;gap:10px;margin-top:3px;flex-wrap:wrap;">
                                            <span class="class-meta"><i class="fa-solid fa-chalkboard-user" style="color:var(--primary);"></i> <%=h(r.get("tutorName"))%></span>
                                            <% if(r.get("classSchedule") != null && !String.valueOf(r.get("classSchedule")).isBlank()){ %>
                                                <span class="class-meta" style="color:#0f172a;font-weight:600;"><i class="fa-regular fa-clock" style="color:#2563eb;"></i> <%=h(r.get("classSchedule"))%></span>
                                            <% } %>
                                        </div>
                                    </div>
                                </div>
                                <div style="display:flex; align-items:center; gap:8px; flex-shrink:0;">
                                    <% if(mLiveLink != null && !mLiveLink.isBlank()){ %>
                                        <a href="<%=h(mLiveLink)%>" target="_blank" rel="noopener noreferrer" class="course-join-btn">
                                            <i class="fa-solid fa-video"></i> Join
                                        </a>
                                    <% } %>
                                    <a href="<%=contextPath%>/classes/view?id=<%=r.get("classId")%>" class="course-enter-btn">
                                        <i class="fa-solid fa-folder-open"></i> Enter
                                    </a>
                                </div>
                            </li>
                        <% } %>
                    </ul>
                </div>

                <div class="card">
                    <div class="card-head">
                        <h2><i class="fa-regular fa-bell" style="color:var(--secondary);font-size:15px;"></i> Student Notifications</h2>
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

        <!-- VIEW: MY CLASSES (CourseWeb / LMS Cards View) -->
        <section class="view" data-view="classes">
            <div class="lms-controls-bar">
                <div class="lms-filter-group">
                    <div class="lms-dropdown-wrap">
                        <button type="button" class="lms-filter-btn" id="lmsFilterBtn" onclick="toggleLmsFilterMenu(event)">
                            <span id="lmsFilterText">All Schedules</span> <i class="fa-solid fa-chevron-down" style="font-size:11px;"></i>
                        </button>
                        <div class="lms-dropdown-menu" id="lmsDropdownMenu">
                            <button type="button" class="lms-dropdown-item active" data-filter="all" onclick="selectLmsFilter('all', 'All Schedules', event)">All Schedules</button>
                            <button type="button" class="lms-dropdown-item" data-filter="weekday" onclick="selectLmsFilter('weekday', 'Weekday Batches', event)">📅 Weekday Batches</button>
                            <button type="button" class="lms-dropdown-item" data-filter="weekend" onclick="selectLmsFilter('weekend', 'Weekend Batches', event)">☕ Weekend Batches</button>
                        </div>
                    </div>
                    <div class="lms-search-box">
                        <i class="fa-solid fa-magnifying-glass"></i>
                        <input type="text" id="courseSearchInput" placeholder="Search my courses..." onkeyup="applyCourseFilters()" autocomplete="off">
                    </div>
                </div>
                <div style="display: flex; align-items: center; gap: 12px;">
                    <div class="lms-view-toggle">
                        <button type="button" class="lms-toggle-btn active" id="toggleGridBtn" title="Card View" onclick="switchCourseView('grid')"><i class="fa-solid fa-grip"></i></button>
                        <button type="button" class="lms-toggle-btn" id="toggleListBtn" title="List View" onclick="switchCourseView('list')"><i class="fa-solid fa-list"></i></button>
                    </div>
                    <a class="btn-solid sm" href="<%=contextPath%>/classes"><i class="fa-solid fa-compass"></i> Explore All</a>
                </div>
            </div>

            <!-- QUICK SCHEDULE TABS -->
            <% if(!classes.isEmpty()){ %>
            <div class="lms-tabs-bar">
                <button type="button" class="lms-tab-btn active" data-schedule-tab="all" onclick="setScheduleTab('all')">
                    <i class="fa-solid fa-layer-group"></i> All Classes <span class="tab-badge"><%=classes.size()%></span>
                </button>
                <button type="button" class="lms-tab-btn" data-schedule-tab="weekday" onclick="setScheduleTab('weekday')">
                    <i class="fa-solid fa-calendar-day"></i> Weekday Batches <span class="tab-badge"><%=weekdayClasses.size()%></span>
                </button>
                <button type="button" class="lms-tab-btn" data-schedule-tab="weekend" onclick="setScheduleTab('weekend')">
                    <i class="fa-solid fa-mug-hot"></i> Weekend Batches <span class="tab-badge"><%=weekendClasses.size()%></span>
                </button>
            </div>
            <% } %>

            <!-- CARDS GRID VIEW -->
            <div id="courseCardsGrid" class="course-grid">
                <% if(classes.isEmpty()){ %>
                    <div class="card" style="grid-column: 1/-1; text-align: center; padding: 48px 20px;">
                        <i class="fa-regular fa-folder-open" style="font-size: 38px; color: var(--text-muted); margin-bottom: 12px; display: block;"></i>
                        <h3 style="font-size: 17px; font-weight:700; color: var(--dark); margin-bottom: 6px;">No enrolled classes found</h3>
                        <p style="font-size: 13.5px; color: var(--text-secondary); margin-bottom: 20px;">You are not enrolled in any classes yet. Browse our course catalogue to get started.</p>
                        <a href="<%=contextPath%>/classes" class="btn-solid sm">
                            <i class="fa-solid fa-compass"></i> Explore Class Catalogue
                        </a>
                    </div>
                <% } else for(Map<String,Object> r : classes){
                    Object cId = r.get("classId");
                    String cSub = String.valueOf(r.get("subject"));
                    String cBatch = String.valueOf(r.get("batch"));
                    String cCleanBatch = cleanBatchName(cBatch);
                    String cTutor = String.valueOf(r.get("tutorName"));
                    String cFee = money(r.get("fee"));
                    String imgSrc = getCourseImage(r.get("imagePath"), cSub, contextPath);
                    boolean isWk = isWeekendClass(r);
                %>
                    <div class="course-card" data-course-title="<%=h(cSub).toLowerCase()%>" data-course-batch="<%=h(cBatch).toLowerCase()%> <%=h(cCleanBatch).toLowerCase()%>" data-course-tutor="<%=h(cTutor).toLowerCase()%>" data-course-schedule="<%=isWk ? "weekend" : "weekday"%>">
                        <a href="<%=contextPath%>/classes/view?id=<%=cId%>" class="course-card-thumb" title="Enter <%=h(cSub)%>">
                            <img src="<%=imgSrc%>" alt="<%=h(cSub)%>" loading="lazy">
                            <span class="course-badge-overlay"><%=h(cCleanBatch)%></span>
                            <% if(isWk) { %>
                                <span class="course-badge-schedule weekend"><i class="fa-solid fa-mug-hot"></i> Weekend</span>
                            <% } else { %>
                                <span class="course-badge-schedule weekday"><i class="fa-solid fa-calendar-day"></i> Weekday</span>
                            <% } %>
                            <span class="course-fee-overlay"><%=cFee%></span>
                        </a>
                        <div class="course-card-body">
                            <a href="<%=contextPath%>/classes/view?id=<%=cId%>" class="course-card-title-link">
                                <h3 class="course-card-title" title="<%=h(cSub)%> — <%=h(cCleanBatch)%>">
                                    <%=h(cSub)%> &mdash; <%=h(cCleanBatch)%>
                                </h3>
                            </a>
                            <div class="course-card-meta">
                                <span><i class="fa-solid fa-chalkboard-user"></i> <%=h(cTutor)%></span>
                                <% if(r.get("classSchedule") != null && !String.valueOf(r.get("classSchedule")).isBlank()){ %>
                                    <span style="color:#1e40af;background:#eff6ff;font-size:11px;font-weight:700;padding:2px 8px;border-radius:6px;margin-left:auto;"><i class="fa-regular fa-clock" style="font-size:10px;color:#2563eb;"></i> <%=h(r.get("classSchedule"))%></span>
                                <% } %>
                                <% 
                                    String mLinkCard = cleanMeetingUrl(r.get("meetingLink"));
                                    boolean hasLinkCard = mLinkCard != null && !mLinkCard.isBlank();
                                %>
                                <% if(hasLinkCard){ %>
                                    <span style="color:#15803d;background:#dcfce7;font-size:11px;font-weight:700;padding:2px 8px;border-radius:10px;"><i class="fa-solid fa-video"></i> Live</span>
                                <% } %>
                            </div>
                            <div class="course-card-footer">
                                <a href="<%=contextPath%>/classes/view?id=<%=cId%>" class="course-enter-btn">
                                    <i class="fa-solid fa-folder-open"></i> Enter Class
                                </a>
                                <div class="course-card-menu-wrap">
                                    <button type="button" class="course-more-btn" title="Options" onclick="toggleCourseMenu(this, event)">
                                        <i class="fa-solid fa-ellipsis-vertical"></i>
                                    </button>
                                    <div class="course-more-menu">
                                        <% if(hasLinkCard){ %>
                                            <a href="<%=h(mLinkCard)%>" target="_blank" rel="noopener noreferrer" style="color:#2563eb;font-weight:700;"><i class="fa-solid fa-video"></i> Join Live Meeting</a>
                                        <% } %>
                                        <a href="<%=contextPath%>/classes/view?id=<%=cId%>"><i class="fa-solid fa-folder-open"></i> View Materials</a>
                                        <a href="<%=contextPath%>/fees"><i class="fa-solid fa-wallet"></i> Fees &amp; Payments</a>
                                        <a href="<%=contextPath%>/attendance"><i class="fa-solid fa-user-check"></i> Attendance</a>
                                        <a href="<%=contextPath%>/results"><i class="fa-solid fa-award"></i> Exams &amp; Results</a>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                <% } %>
            </div>

            <!-- TABLE VIEW (Hidden by default, toggleable) -->
            <div id="courseTableView" class="card" style="display: none; margin-top: 10px;">
                <div class="table-wrap">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Class</th>
                                <th>Schedule</th>
                                <th>Tutor</th>
                                <th>Fee</th>
                                <th>Enrolled Date</th>
                                <th style="text-align:right;">Classroom &amp; Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if(classes.isEmpty()){ %>
                                <tr><td colspan="6" class="muted">No enrolled classes found.</td></tr>
                            <% } else for(Map<String,Object> r:classes){ 
                                boolean isWk = isWeekendClass(r);
                                String cCleanBatch = cleanBatchName(r.get("batch"));
                            %>
                                <tr data-schedule="<%=isWk ? "weekend" : "weekday"%>">
                                    <td>
                                        <div style="display:flex;align-items:center;gap:12px;">
                                            <img src="<%=getCourseImage(r.get("imagePath"), r.get("subject"), contextPath)%>" style="width:48px;height:32px;object-fit:cover;border-radius:6px;" alt="">
                                            <a href="<%=contextPath%>/classes/view?id=<%=r.get("classId")%>" style="color:var(--primary);font-weight:700;text-decoration:none;">
                                                <%=h(r.get("subject"))%> &mdash; <%=h(cCleanBatch)%>
                                            </a>
                                        </div>
                                    </td>
                                    <td>
                                        <span class="badge-schedule <%=isWk ? "badge-weekend" : "badge-weekday"%>">
                                            <i class="fa-solid <%=isWk ? "fa-mug-hot" : "fa-calendar-day"%>"></i> <%=isWk ? "Weekend" : "Weekday"%>
                                        </span>
                                    </td>
                                    <td><%=h(r.get("tutorName"))%></td>
                                    <td class="mono"><%=money(r.get("fee"))%></td>
                                    <td><%=h(r.get("enrolledAt"))%></td>
                                    <td style="text-align:right;">
                                        <% if(r.get("classSchedule") != null && !String.valueOf(r.get("classSchedule")).isBlank()){ %>
                                            <span style="font-size:12px;color:#475569;font-weight:600;margin-right:10px;"><i class="fa-regular fa-clock" style="color:#2563eb;"></i> <%=h(r.get("classSchedule"))%></span>
                                        <% } %>
                                        <% 
                                            String mLinkRow = cleanMeetingUrl(r.get("meetingLink"));
                                            if(mLinkRow != null && !mLinkRow.isBlank()){ 
                                        %>
                                            <a class="course-join-btn" href="<%=h(mLinkRow)%>" target="_blank" rel="noopener noreferrer" style="margin-right:6px;">
                                                <i class="fa-solid fa-video"></i> Join Live
                                            </a>
                                        <% } %>
                                        <a class="course-enter-btn" href="<%=contextPath%>/classes/view?id=<%=r.get("classId")%>">
                                            <i class="fa-solid fa-folder-open"></i> Enter Class
                                        </a>
                                    </td>
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
                    <h2><i class="fa-regular fa-calendar-days" style="color:var(--primary);font-size:16px;"></i> My Timetable</h2>
                    <span class="card-date"><%=timetable.size()%> assigned slots</span>
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

        <!-- VIEW: ATTENDANCE -->
        <section class="view" data-view="attendance">
            <div class="card">
                <div class="card-head">
                    <h2><i class="fa-solid fa-user-check" style="color:var(--secondary);font-size:16px;"></i> Attendance History</h2>
                    <span class="card-date">Cumulative: <%=pct(summary.get("attendanceRate"))%></span>
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
                    <span class="stat-label">Invoices</span>
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
                    <a class="btn-solid sm" href="<%=contextPath%>/fees"><i class="fa-solid fa-receipt"></i> Fee Portal</a>
                </div>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>ID</th>
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
                    <h2><i class="fa-solid fa-clock-rotate-left" style="color:var(--secondary);font-size:16px;"></i> Payment History</h2>
                </div>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Payment</th>
                                <th>Class</th>
                                <th>Amount</th>
                                <th>Method</th>
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
                    <a class="btn-solid sm" href="<%=contextPath%>/results">Full Results Report</a>
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
                                <th style="text-align:right;">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if(results.isEmpty()){ %>
                                <tr><td colspan="6" class="muted">No results published yet.</td></tr>
                            <% } else for(Map<String,Object> r:results){ 
                                Object eId = r.get("examId");
                                Object hasQuizObj = r.get("hasQuiz");
                                boolean hasQuiz = hasQuizObj != null && ("1".equals(String.valueOf(hasQuizObj)) || Boolean.TRUE.equals(hasQuizObj));
                            %>
                                <tr>
                                    <td><strong><%=h(r.get("examName"))%></strong></td>
                                    <td><%=h(r.get("subject"))%> &mdash; <%=h(r.get("batch"))%></td>
                                    <td><%=h(r.get("examDate"))%></td>
                                    <td class="mono" style="font-weight:700;"><%=h(r.get("marksObtained"))%> / <%=h(r.get("maxMarks"))%></td>
                                    <td><span class="badge badge-live" style="font-size:12px;font-weight:800;"><%=h(r.get("grade"))%></span></td>
                                    <td style="text-align:right;">
                                        <% if (hasQuiz) { %>
                                            <a href="<%=contextPath%>/student/quiz?examId=<%=eId%>" class="quiz-btn" style="background:#f3f4f6 !important; color:#374151 !important; border:1px solid #d1d5db !important; text-decoration:none !important; display:inline-flex; align-items:center; gap:6px; padding:6px 14px; border-radius:8px; font-weight:700; font-size:12px;">
                                                <i class="fa-solid fa-award" style="color:#7c3aed !important;"></i> <span style="color:#374151 !important; font-weight:700;">Review Quiz</span>
                                            </a>
                                        <% } else { %>
                                            <span class="muted" style="font-size:12px;">&mdash;</span>
                                        <% } %>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            <div class="card">
                <div class="card-head">
                    <h2><i class="fa-solid fa-calendar-days" style="color:var(--secondary);font-size:16px;"></i> Upcoming Exams &amp; Quizzes</h2>
                </div>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Exam</th>
                                <th>Class</th>
                                <th>Date</th>
                                <th>Status</th>
                                <th style="text-align:right;">Assessment</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if(exams.isEmpty()){ %>
                                <tr><td colspan="5" class="muted">No upcoming exams scheduled.</td></tr>
                            <% } else for(Map<String,Object> r:exams){ 
                                Object eId = r.get("examId");
                                Object qCountObj = r.get("questionCount");
                                int qCount = qCountObj instanceof Number ? ((Number)qCountObj).intValue() : 0;
                                Object hasSubObj = r.get("hasSubmitted");
                                boolean hasSub = hasSubObj != null && ("1".equals(String.valueOf(hasSubObj)) || Boolean.TRUE.equals(hasSubObj));
                            %>
                                <tr>
                                    <td><strong><%=h(r.get("examName"))%></strong></td>
                                    <td><%=h(r.get("subject"))%> &mdash; <%=h(r.get("batch"))%></td>
                                    <td><%=h(r.get("examDate"))%></td>
                                    <td>
                                        <% if (hasSub) { %>
                                            <span class="badge badge-pending">Under Review</span>
                                        <% } else { %>
                                            <span class="badge <%=badge(r.get("status"))%>"><%=h(r.get("status"))%></span>
                                        <% } %>
                                    </td>
                                    <td style="text-align:right;">
                                        <% if (hasSub) { %>
                                            <a href="<%=contextPath%>/student/quiz?examId=<%=eId%>" class="quiz-btn" style="background:#fef3c7 !important; color:#92400e !important; border:1px solid #fde68a !important; text-decoration:none !important; display:inline-flex; align-items:center; gap:6px; padding:6px 14px; border-radius:8px; font-weight:700; font-size:12px;">
                                                <i class="fa-solid fa-clock" style="color:#d97706 !important;"></i> <span style="color:#92400e !important; font-weight:700;">Pending Review</span>
                                            </a>
                                        <% } else if (qCount > 0) { %>
                                            <a href="<%=contextPath%>/student/quiz?examId=<%=eId%>" class="quiz-btn" style="background:linear-gradient(135deg, #7c3aed, #4f46e5) !important; color:#ffffff !important; text-decoration:none !important; display:inline-flex; align-items:center; gap:7px; padding:7px 16px; border-radius:8px; font-weight:700; font-size:12.5px; box-shadow:0 2px 8px rgba(124,58,237,0.35);">
                                                <i class="fa-solid fa-pen-to-square" style="color:#ffffff !important; font-size:13px;"></i> <span style="color:#ffffff !important; font-weight:700; text-decoration:none !important;">Take Quiz</span>
                                            </a>
                                        <% } else { %>
                                            <span class="badge badge-neutral" style="font-size:12px;padding:5px 10px;"><i class="fa-solid fa-chalkboard"></i> Scheduled</span>
                                        <% } %>
                                    </td>
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
                        <h2><i class="fa-regular fa-bell" style="color:var(--primary);font-size:16px;"></i> Notifications &amp; Announcements</h2>
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

<!-- PROFILE & ACCOUNT SETTINGS MODAL -->
<div class="profile-modal-overlay" id="profileModal" onclick="if(event.target===this)closeProfileModal()">
    <div class="profile-modal-card">
        <div class="profile-modal-header">
            <div class="profile-user-badge">
                <div class="profile-user-avatar" id="profileModalAvatar"><%=getInitials(userName)%></div>
                <div>
                    <h3 style="margin:0;font-size:17px;font-weight:700;color:#0f172a;" id="profileModalName"><%=h(userName)%></h3>
                    <span style="font-size:12px;color:#64748b;font-weight:600;"><%=currentUser != null && currentUser.getRole() != null ? currentUser.getRole() : "Student"%> Profile</span>
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
<script src="<%=contextPath%>/js/dashboard-student.js?v=2.2"></script>
<script src="<%=contextPath%>/js/profile.js?v=2.2"></script>
<script>
function toggleLmsFilterMenu(e) {
    if (e) e.stopPropagation();
    const menu = document.getElementById('lmsDropdownMenu');
    if (menu) menu.classList.toggle('show');
}

let currentScheduleFilter = 'all';

function setScheduleTab(tab) {
    currentScheduleFilter = tab;
    document.querySelectorAll('.lms-tab-btn').forEach(btn => {
        btn.classList.toggle('active', btn.getAttribute('data-schedule-tab') === tab);
    });
    const textSpan = document.getElementById('lmsFilterText');
    if (textSpan) {
        if (tab === 'weekday') textSpan.textContent = 'Weekday Batches';
        else if (tab === 'weekend') textSpan.textContent = 'Weekend Batches';
        else textSpan.textContent = 'All Schedules';
    }
    document.querySelectorAll('.lms-dropdown-item').forEach(item => {
        item.classList.toggle('active', item.getAttribute('data-filter') === tab);
    });
    applyCourseFilters();
}

function selectLmsFilter(key, label, e) {
    if (e) e.stopPropagation();
    const menu = document.getElementById('lmsDropdownMenu');
    if (menu) menu.classList.remove('show');
    setScheduleTab(key);
}

function switchCourseView(mode) {
    const grid = document.getElementById('courseCardsGrid');
    const table = document.getElementById('courseTableView');
    const btnGrid = document.getElementById('toggleGridBtn');
    const btnList = document.getElementById('toggleListBtn');
    if (mode === 'list') {
        if (grid) grid.style.display = 'none';
        if (table) table.style.display = 'block';
        if (btnGrid) btnGrid.classList.remove('active');
        if (btnList) btnList.classList.add('active');
    } else {
        if (grid) grid.style.display = '';
        if (table) table.style.display = 'none';
        if (btnGrid) btnGrid.classList.add('active');
        if (btnList) btnList.classList.remove('active');
    }
}

function applyCourseFilters() {
    const input = document.getElementById('courseSearchInput');
    const q = input ? input.value.toLowerCase().trim() : '';
    const cards = document.querySelectorAll('.course-card');
    let visibleWeekdayCount = 0;
    let visibleWeekendCount = 0;

    cards.forEach(c => {
        const title = c.getAttribute('data-course-title') || '';
        const batch = c.getAttribute('data-course-batch') || '';
        const tutor = c.getAttribute('data-course-tutor') || '';
        const sched = c.getAttribute('data-course-schedule') || '';

        const matchesSearch = !q || title.includes(q) || batch.includes(q) || tutor.includes(q) || sched.includes(q);
        const matchesSchedule = (currentScheduleFilter === 'all') || (sched === currentScheduleFilter);

        c.style.display = (matchesSearch && matchesSchedule) ? '' : 'none';
    });

    const tableRows = document.querySelectorAll('#courseTableView tbody tr[data-schedule]');
    tableRows.forEach(row => {
        const text = row.textContent.toLowerCase();
        const sched = row.getAttribute('data-schedule') || '';
        const matchesSearch = !q || text.includes(q);
        const matchesSchedule = (currentScheduleFilter === 'all') || (sched === currentScheduleFilter);
        row.style.display = (matchesSearch && matchesSchedule) ? '' : 'none';
    });
}

function filterCourseCards() {
    applyCourseFilters();
}

function toggleCourseMenu(btn, e) {
    if (e) e.stopPropagation();
    const menu = btn.nextElementSibling;
    document.querySelectorAll('.course-more-menu.show').forEach(m => {
        if (m !== menu) m.classList.remove('show');
    });
    if (menu) menu.classList.toggle('show');
}

document.addEventListener('click', () => {
    const filterMenu = document.getElementById('lmsDropdownMenu');
    if (filterMenu) filterMenu.classList.remove('show');
    document.querySelectorAll('.course-more-menu.show').forEach(m => m.classList.remove('show'));
});
</script>
</body>
</html>
