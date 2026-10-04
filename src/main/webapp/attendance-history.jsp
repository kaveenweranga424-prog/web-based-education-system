<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Attendance" %>
<%@ page import="model.User" %>
<%@ page import="java.util.List" %>
<%!
    private String h(Object val) {
        if (val == null) return "";
        return String.valueOf(val).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
    private String badge(String s) {
        if (s == null) return "badge-neutral";
        if ("PRESENT".equalsIgnoreCase(s)) return "badge-paid";
        if ("LATE".equalsIgnoreCase(s)) return "badge-pending";
        if ("ABSENT".equalsIgnoreCase(s)) return "badge-absent";
        return "badge-neutral";
    }
%>
<%
    String contextPath = request.getContextPath();
    List<Attendance> history = (List<Attendance>) request.getAttribute("history");
    List<User> linkedChildren = (List<User>) request.getAttribute("linkedChildren");
    Integer selectedStudentId = (Integer) request.getAttribute("selectedStudentId");
    String role = session.getAttribute("userRole") != null ? String.valueOf(session.getAttribute("userRole")) : "";

    int total = history != null ? history.size() : 0;
    int present = 0, late = 0, absent = 0;
    if (history != null) {
        for (Attendance a : history) {
            if ("PRESENT".equalsIgnoreCase(a.getStatus())) present++;
            else if ("LATE".equalsIgnoreCase(a.getStatus())) late++;
            else if ("ABSENT".equalsIgnoreCase(a.getStatus())) absent++;
        }
    }
    double attendanceRate = total > 0 ? ((present + late) * 100.0 / total) : 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Attendance History | Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/class-pages.css">
    <style>
        .att-shell { max-width: 1000px; margin: 32px auto; padding: 0 20px; }
        .att-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .child-switcher { display: inline-flex; align-items: center; gap: 8px; font-size: 13.5px; font-weight: 600; }
        .child-select { padding: 8px 14px; border: 1px solid #d4d4d4; border-radius: 8px; font-size: 13.5px; font-weight: 600; }
        .stat-bar { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin-bottom: 24px; }
        .stat-box { background: #fff; border: 1px solid #e8e8e8; border-radius: 14px; padding: 16px 20px; box-shadow: 0 2px 6px rgba(0,0,0,.03); }
        .stat-box-label { font-size: 12px; color: #737373; font-weight: 600; text-transform: uppercase; }
        .stat-box-value { font-size: 24px; font-weight: 700; color: #171717; margin-top: 4px; }
        .att-card { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,.04); }
        .table-wrap { overflow-x: auto; }
        .data-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13.5px; }
        .data-table th { background: #f9fafb; padding: 14px 16px; border-bottom: 1px solid #e5e7eb; color: #4b5563; font-weight: 600; }
        .data-table td { padding: 14px 16px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
        .empty-att { padding: 48px 24px; text-align: center; color: #737373; }
        .empty-att i { font-size: 40px; color: #d4d4d4; margin-bottom: 12px; }
    </style>
</head>
<body class="dash-body">

<header class="class-page-header">
    <a class="class-brand" href="<%= contextPath %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle">Attendance Records</span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= contextPath %>/dashboard"><i class="fa-solid fa-arrow-left"></i> Dashboard</a>
    </div>
</header>

<main class="att-shell">
    <div class="att-header">
        <div>
            <h1 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:24px;font-weight:700;">Attendance History</h1>
            <p style="font-size:14px;color:#737373;margin-top:4px;">Detailed class attendance logs and session performance.</p>
        </div>
        <div>
            <% if ("PARENT".equalsIgnoreCase(role) && linkedChildren != null && !linkedChildren.isEmpty()) { %>
            <div class="child-switcher">
                <i class="fa-solid fa-user-graduate"></i>
                <label for="childSelect">Student:</label>
                <select id="childSelect" class="child-select" onchange="location.href='<%= contextPath %>/attendance?studentId=' + this.value">
                    <% for (User c : linkedChildren) { %>
                        <option value="<%= c.getUserId() %>" <%= selectedStudentId != null && selectedStudentId == c.getUserId() ? "selected" : "" %>>
                            <%= h(c.getFirstName()) %> <%= h(c.getLastName()) %>
                        </option>
                    <% } %>
                </select>
            </div>
            <% } %>
        </div>
    </div>

    <div class="stat-bar">
        <div class="stat-box">
            <span class="stat-box-label">Attendance Rate</span>
            <div class="stat-box-value" style="color:#2563eb;"><%= String.format("%.1f", attendanceRate) %>%</div>
        </div>
        <div class="stat-box">
            <span class="stat-box-label">Total Sessions</span>
            <div class="stat-box-value"><%= total %></div>
        </div>
        <div class="stat-box">
            <span class="stat-box-label">Present</span>
            <div class="stat-box-value" style="color:#16a34a;"><%= present %></div>
        </div>
        <div class="stat-box">
            <span class="stat-box-label">Late / Absent</span>
            <div class="stat-box-value" style="color:#ef4444;"><%= late + absent %></div>
        </div>
    </div>

    <div class="att-card">
        <% if (history == null || history.isEmpty()) { %>
            <div class="empty-att">
                <i class="fa-solid fa-user-check"></i>
                <h3 style="font-size:16px;color:#171717;margin-bottom:6px;">No attendance records found</h3>
                <p style="font-size:13.5px;">Attendance marked by your tutors will appear here automatically.</p>
            </div>
        <% } else { %>
            <div class="table-wrap">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Date</th>
                            <th>Class / Subject</th>
                            <th>Batch</th>
                            <th>Status</th>
                            <th>Remarks</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% for (Attendance a : history) { %>
                        <tr>
                            <td style="font-weight:600;"><%= a.getSessionDate() %></td>
                            <td><%= h(a.getSubject()) %></td>
                            <td><span class="badge badge-neutral"><%= h(a.getBatch()) %></span></td>
                            <td><span class="badge <%= badge(a.getStatus()) %>"><%= h(a.getStatus()) %></span></td>
                            <td style="color:#525252;"><%= a.getRemarks() != null ? h(a.getRemarks()) : "—" %></td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        <% } %>
    </div>
</main>

</body>
</html>