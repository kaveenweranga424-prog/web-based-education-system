<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Class" %>
<%@ page import="java.util.List" %>

<%!
    private String h(Object value) {
        if (value == null) return "";
        return String.valueOf(value)
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
%>
<%
    String contextPath = request.getContextPath();
    List<Class> classes = (List<Class>) request.getAttribute("classes");
    String subject = request.getAttribute("subject") != null ? request.getAttribute("subject").toString() : "";
    String tutorName = request.getAttribute("tutorName") != null ? request.getAttribute("tutorName").toString() : "";
    String batch = request.getAttribute("batch") != null ? request.getAttribute("batch").toString() : "";
    String classType = request.getAttribute("classType") != null ? request.getAttribute("classType").toString() : "";
    int classCount = classes == null ? 0 : classes.size();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Class Catalogue | Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/class-pages.css">
</head>
<body class="class-page-body">
<header class="class-page-header">
    <a class="class-brand" href="<%= contextPath %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle">Student Portal</span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= contextPath %>/dashboard">
            <i class="fa-solid fa-gauge"></i> Dashboard
        </a>
        <a class="class-nav-link" href="<%= contextPath %>/logout">
            <i class="fa-solid fa-arrow-right-from-bracket"></i> Log out
        </a>
    </div>
</header>

<main class="class-page-shell">
    <section class="class-page-intro">
        <div>
            <span class="class-page-kicker"><i class="fa-solid fa-compass"></i> Discover Classes</span>
            <h1 class="class-page-title">Class Catalogue</h1>
            <p class="class-page-description">Browse available classes, compare tutors and fees, then open a class to view its enrollment and payment status.</p>
        </div>
    </section>

    <section class="class-search-card">
        <form class="class-search-form" action="<%= contextPath %>/classes" method="get">
            <div class="class-field">
                <label for="subject">Subject</label>
                <input id="subject" type="text" name="subject" placeholder="e.g. Mathematics" value="<%= h(subject) %>">
            </div>
            <div class="class-field">
                <label for="tutorName">Tutor</label>
                <input id="tutorName" type="text" name="tutorName" placeholder="Tutor name" value="<%= h(tutorName) %>">
            </div>
            <div class="class-field">
                <label for="batch">Batch</label>
                <input id="batch" type="text" name="batch" placeholder="e.g. Grade 11" value="<%= h(batch) %>">
            </div>
            <div class="class-field">
                <label for="classType">Schedule</label>
                <select id="classType" name="classType" style="height: 42px; border: 1px solid #cbd5e1; border-radius: 8px; padding: 0 12px; font-family: inherit; font-size: 14px; background: #fff; color: #1e293b;">
                    <option value="">All Schedules</option>
                    <option value="WEEKDAY" <%= "WEEKDAY".equalsIgnoreCase(classType) ? "selected" : "" %>>Weekday</option>
                    <option value="WEEKEND" <%= "WEEKEND".equalsIgnoreCase(classType) ? "selected" : "" %>>Weekend</option>
                </select>
            </div>
            <button type="submit" class="class-primary-btn">
                <i class="fa-solid fa-magnifying-glass"></i> Search
            </button>
        </form>
    </section>

    <section class="class-content-card">
        <div class="class-card-heading">
            <h2>Available Classes</h2>
            <span class="class-result-count"><%= classCount %> class<%= classCount == 1 ? "" : "es" %> found</span>
        </div>

        <% if (classes != null && !classes.isEmpty()) { %>
        <div class="class-table-wrap">
            <table class="class-table">
                <thead>
                <tr>
                    <th>Banner</th>
                    <th>Subject</th>
                    <th>Batch</th>
                    <th>Schedule</th>
                    <th>Tutor</th>
                    <th>Fee</th>
                    <th>Action</th>
                </tr>
                </thead>
                <tbody>
                <% for (Class c : classes) { %>
                <tr>
                    <td>
                        <%
                            String bImg = c.getImagePath();
                            if (bImg == null || bImg.isBlank()) {
                                String sLow = c.getSubject() != null ? c.getSubject().toLowerCase() : "";
                                if (sLow.contains("math")) bImg = "images/courses/maths.jpg";
                                else if (sLow.contains("sci")) bImg = "images/courses/science.jpg";
                                else if (sLow.contains("it") || sLow.contains("ict") || sLow.contains("tech")) bImg = "images/courses/it.jpg";
                                else if (sLow.contains("eng")) bImg = "images/courses/english.jpg";
                                else bImg = "images/courses/default.jpg";
                            }
                        %>
                        <div style="width: 78px; height: 48px; border-radius: 8px; overflow: hidden; border: 1px solid #e2e8f0; box-shadow: 0 1px 3px rgba(0,0,0,0.05); background:#0f172a; flex-shrink: 0;">
                            <img src="<%= contextPath %>/<%= bImg %>" alt="<%= h(c.getSubject()) %>" style="width: 100%; height: 100%; object-fit: cover; object-position: center;">
                        </div>
                    </td>
                    <td>
                        <div class="class-subject-cell">
                            <span class="class-subject-icon"><i class="fa-solid fa-book-open"></i></span>
                            <span class="class-subject-name"><%= h(c.getSubject()) %></span>
                        </div>
                    </td>
                    <td><%= h(c.getBatch()) %></td>
                    <td>
                        <% if (c.isWeekend()) { %>
                        <span style="display:inline-flex; align-items:center; gap:5px; padding:3px 9px; border-radius:6px; font-size:12px; font-weight:700; background:#fffbeb; color:#b45309; border:1px solid #fde68a;">
                            <i class="fa-solid fa-mug-hot"></i> Weekend
                        </span>
                        <% } else { %>
                        <span style="display:inline-flex; align-items:center; gap:5px; padding:3px 9px; border-radius:6px; font-size:12px; font-weight:700; background:#eef2ff; color:#4338ca; border:1px solid #c7d2fe;">
                            <i class="fa-solid fa-calendar-day"></i> Weekday
                        </span>
                        <% } %>
                    </td>
                    <td><%= c.getTutorName() != null ? h(c.getTutorName()) : "Not assigned" %></td>
                    <td class="class-fee">Rs. <%= h(c.getFee()) %></td>
                    <td>
                        <a class="class-action-btn" href="<%= contextPath %>/enroll?classId=<%= c.getClassId() %>">
                            View <i class="fa-solid fa-arrow-right"></i>
                        </a>
                    </td>
                </tr>
                <% } %>
                </tbody>
            </table>
        </div>
        <% } else { %>
        <div class="class-empty-state">
            <i class="fa-regular fa-folder-open"></i>
            <strong>No classes found</strong>
            <span>Try changing your search filters.</span>
        </div>
        <% } %>
    </section>
</main>
</body>
</html>
