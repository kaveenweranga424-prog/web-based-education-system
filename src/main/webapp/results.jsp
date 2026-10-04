<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.ExamResult" %>
<%@ page import="model.User" %>
<%@ page import="java.util.List" %>
<%@ page import="java.math.BigDecimal" %>
<%!
    private String h(Object val) {
        if (val == null) return "";
        return String.valueOf(val).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
    private String gradeBadge(String grade) {
        if (grade == null) return "badge-neutral";
        grade = grade.trim().toUpperCase();
        if (grade.startsWith("A")) return "badge-paid";
        if (grade.startsWith("B")) return "badge-blue";
        if (grade.startsWith("C")) return "badge-cyan";
        if (grade.startsWith("S") || grade.startsWith("D")) return "badge-pending";
        return "badge-absent";
    }
%>
<%
    String contextPath = request.getContextPath();
    List<ExamResult> results = (List<ExamResult>) request.getAttribute("results");
    List<User> linkedChildren = (List<User>) request.getAttribute("linkedChildren");
    Integer selectedStudentId = (Integer) request.getAttribute("selectedStudentId");
    String role = session.getAttribute("userRole") != null ? String.valueOf(session.getAttribute("userRole")) : "";

    int count = results != null ? results.size() : 0;
    double totalObtained = 0, totalMax = 0;
    if (results != null) {
        for (ExamResult r : results) {
            if (r.getMarksObtained() != null && r.getMaxMarks() != null && r.getMaxMarks().signum() > 0) {
                totalObtained += r.getMarksObtained().doubleValue();
                totalMax += r.getMaxMarks().doubleValue();
            }
        }
    }
    double overallAvg = totalMax > 0 ? (totalObtained * 100.0 / totalMax) : 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Examination Results | Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/class-pages.css">
    <style>
        .res-shell { max-width: 1000px; margin: 32px auto; padding: 0 20px; }
        .res-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .child-switcher { display: inline-flex; align-items: center; gap: 8px; font-size: 13.5px; font-weight: 600; }
        .child-select { padding: 8px 14px; border: 1px solid #d4d4d4; border-radius: 8px; font-size: 13.5px; font-weight: 600; }
        .stat-bar { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin-bottom: 24px; }
        .stat-box { background: #fff; border: 1px solid #e8e8e8; border-radius: 14px; padding: 16px 20px; box-shadow: 0 2px 6px rgba(0,0,0,.03); }
        .stat-box-label { font-size: 12px; color: #737373; font-weight: 600; text-transform: uppercase; }
        .stat-box-value { font-size: 24px; font-weight: 700; color: #171717; margin-top: 4px; }
        .res-card { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,.04); }
        .table-wrap { overflow-x: auto; }
        .data-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13.5px; }
        .data-table th { background: #f9fafb; padding: 14px 16px; border-bottom: 1px solid #e5e7eb; color: #4b5563; font-weight: 600; }
        .data-table td { padding: 14px 16px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
        .empty-res { padding: 48px 24px; text-align: center; color: #737373; }
        .empty-res i { font-size: 40px; color: #d4d4d4; margin-bottom: 12px; }
    </style>
</head>
<body class="dash-body">

<header class="class-page-header">
    <a class="class-brand" href="<%= contextPath %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle">Academic Performance</span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= contextPath %>/dashboard"><i class="fa-solid fa-arrow-left"></i> Dashboard</a>
    </div>
</header>

<main class="res-shell">
    <div class="res-header">
        <div>
            <h1 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:24px;font-weight:700;">Examination Results</h1>
            <p style="font-size:14px;color:#737373;margin-top:4px;">Official marks, grades, and tutor feedback for class assessments.</p>
        </div>
        <div>
            <% if ("PARENT".equalsIgnoreCase(role) && linkedChildren != null && !linkedChildren.isEmpty()) { %>
            <div class="child-switcher">
                <i class="fa-solid fa-user-graduate"></i>
                <label for="childSelect">Student:</label>
                <select id="childSelect" class="child-select" onchange="location.href='<%= contextPath %>/results?studentId=' + this.value">
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
            <span class="stat-box-label">Overall Average</span>
            <div class="stat-box-value" style="color:#7c3aed;"><%= String.format("%.1f", overallAvg) %>%</div>
        </div>
        <div class="stat-box">
            <span class="stat-box-label">Published Results</span>
            <div class="stat-box-value"><%= count %></div>
        </div>
        <div class="stat-box">
            <span class="stat-box-label">Marks Scored</span>
            <div class="stat-box-value" style="color:#16a34a;"><%= String.format("%.1f", totalObtained) %> / <%= String.format("%.0f", totalMax) %></div>
        </div>
    </div>

    <div class="res-card">
        <% if (results == null || results.isEmpty()) { %>
            <div class="empty-res">
                <i class="fa-solid fa-award"></i>
                <h3 style="font-size:16px;color:#171717;margin-bottom:6px;">No examination results published yet</h3>
                <p style="font-size:13.5px;">Results entered by your tutors will appear here once released.</p>
            </div>
        <% } else { %>
            <div class="table-wrap">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Exam Name</th>
                            <th>Class / Batch</th>
                            <th>Score</th>
                            <th>Percentage</th>
                            <th>Grade</th>
                            <th>Tutor Remarks</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% for (ExamResult r : results) { 
                        double pct = 0;
                        if (r.getMarksObtained() != null && r.getMaxMarks() != null && r.getMaxMarks().signum() > 0) {
                            pct = r.getMarksObtained().doubleValue() * 100.0 / r.getMaxMarks().doubleValue();
                        }
                    %>
                        <tr>
                            <td style="font-weight:600;color:#171717;">
                                <%= h(r.getExamName()) %>
                                <% 
                                    boolean isQuiz = false;
                                    try {
                                        java.lang.reflect.Method m = r.getClass().getMethod("isMcqQuiz");
                                        isQuiz = Boolean.TRUE.equals(m.invoke(r));
                                    } catch (Throwable ignored) {}
                                    if (!isQuiz && r.getRemarks() != null && r.getRemarks().contains("Auto-graded")) {
                                        isQuiz = true;
                                    }
                                    if (!isQuiz) {
                                        try {
                                            isQuiz = new dao.ExamMcqDAO().hasStudentAttempted(r.getExamId(), r.getStudentId());
                                        } catch (Throwable ignored) {}
                                    }
                                %>
                                <% if (isQuiz) { %>
                                    <br><span style="font-size:11px;font-weight:600;color:#047857;background:#ecfdf5;display:inline-flex;align-items:center;gap:4px;padding:2px 6px;border-radius:4px;margin-top:3px;"><i class="fa-solid fa-robot"></i> Online MCQ</span>
                                    <% if ("STUDENT".equalsIgnoreCase(role)) { %>
                                        <a href="<%= contextPath %>/student/quiz?examId=<%= r.getExamId() %>" style="color:#7c3aed;font-size:11.5px;font-weight:600;text-decoration:none;margin-left:6px;"><i class="fa-solid fa-eye"></i> Review</a>
                                    <% } %>
                                <% } %>
                            </td>
                            <td><%= h(r.getSubject()) %> — <span class="badge badge-neutral"><%= h(r.getBatch()) %></span></td>
                            <td><strong><%= r.getMarksObtained() %></strong> / <%= r.getMaxMarks() %></td>
                            <td><%= String.format("%.1f", pct) %>%</td>
                            <td><span class="badge <%= gradeBadge(r.getGrade()) %>"><%= h(r.getGrade()) %></span></td>
                            <td style="color:#525252;"><%= r.getRemarks() != null && !r.getRemarks().isBlank() ? h(r.getRemarks()) : "—" %></td>
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