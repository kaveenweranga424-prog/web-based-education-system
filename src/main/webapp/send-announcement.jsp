<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Class" %>
<%@ page import="model.Notification" %>
<%@ page import="java.util.List" %>
<%!
    private String h(Object val) {
        if (val == null) return "";
        return String.valueOf(val).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    String contextPath = request.getContextPath();
    List<Class> classes = (List<Class>) request.getAttribute("classes");
    List<Notification> sentHistory = (List<Notification>) request.getAttribute("sentHistory");
    Boolean isAdmin = (Boolean) request.getAttribute("isAdmin");
    if (isAdmin == null) isAdmin = false;
    String errorMessage = request.getAttribute("errorMessage") != null ? String.valueOf(request.getAttribute("errorMessage")) : "";
    boolean sentSuccess = "1".equals(request.getParameter("sent"));
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Send Announcements | Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/class-pages.css">
    <style>
        .ann-container { max-width: 900px; margin: 32px auto; padding: 0 20px; }
        .ann-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .ann-title-group h1 { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 24px; font-weight: 700; color: #171717; }
        .ann-title-group p { font-size: 14px; color: #737373; margin-top: 4px; }
        .card-panel { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; padding: 24px; box-shadow: 0 2px 8px rgba(0,0,0,.04); margin-bottom: 28px; }
        .form-grid { display: flex; flex-direction: column; gap: 18px; }
        .form-group { display: flex; flex-direction: column; gap: 6px; }
        .form-group label { font-size: 13.5px; font-weight: 600; color: #262626; display: flex; align-items: center; gap: 8px; }
        .form-control { width: 100%; padding: 11px 14px; border: 1px solid #d4d4d4; border-radius: 10px; font-size: 14px; font-family: inherit; transition: border-color .2s; }
        .form-control:focus { outline: none; border-color: #7c3aed; box-shadow: 0 0 0 3px rgba(124, 58, 237, 0.1); }
        textarea.form-control { min-height: 120px; resize: vertical; line-height: 1.5; }
        .radio-pills { display: flex; gap: 12px; }
        .radio-pill { display: inline-flex; align-items: center; gap: 6px; padding: 8px 16px; border: 1px solid #e5e5e5; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; }
        .radio-pill input { accent-color: #7c3aed; }
        .btn-submit { background: #7c3aed; color: #fff; padding: 12px 24px; border: none; border-radius: 10px; font-size: 14px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; transition: background .2s; align-self: flex-start; }
        .btn-submit:hover { background: #6d28d9; }
        .alert-box { padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        .alert-success { background: #dcfce7; color: #166534; border: 1px solid #bbf7d0; }
        .alert-error { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; }
        .table-wrap { overflow-x: auto; margin-top: 12px; }
        .data-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13.5px; }
        .data-table th { background: #f9fafb; padding: 12px 14px; border-bottom: 1px solid #e5e7eb; color: #4b5563; font-weight: 600; }
        .data-table td { padding: 12px 14px; border-bottom: 1px solid #f3f4f6; color: #1f2937; }
    </style>
    <script>
        function toggleScope() {
            var broadcastDiv = document.getElementById('broadcastScope');
            var classDiv = document.getElementById('classScope');
            var radioBroadcast = document.getElementById('scopeBroadcast');
            if (radioBroadcast && radioBroadcast.checked) {
                if (broadcastDiv) broadcastDiv.style.display = 'block';
                if (classDiv) classDiv.style.display = 'none';
            } else {
                if (broadcastDiv) broadcastDiv.style.display = 'none';
                if (classDiv) classDiv.style.display = 'block';
            }
        }
    </script>
</head>
<body class="dash-body">

<header class="class-page-header">
    <a class="class-brand" href="<%= contextPath %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle"><%= isAdmin ? "Admin Announcements" : "Tutor Announcements" %></span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= contextPath %>/dashboard"><i class="fa-solid fa-arrow-left"></i> Dashboard</a>
    </div>
</header>

<main class="ann-container">
    <div class="ann-header">
        <div class="ann-title-group">
            <h1>Send Institute Announcements</h1>
            <p>Publish important messages, class schedule changes, or notices to students and parents.</p>
        </div>
    </div>

    <% if (sentSuccess) { %>
        <div class="alert-box alert-success">
            <i class="fa-solid fa-circle-check"></i>
            <span>Announcement was sent successfully to all targeted recipients and linked parents!</span>
        </div>
    <% } %>

    <% if (!errorMessage.isEmpty()) { %>
        <div class="alert-box alert-error">
            <i class="fa-solid fa-circle-exclamation"></i>
            <span><%= h(errorMessage) %></span>
        </div>
    <% } %>

    <div class="card-panel">
        <form action="<%= contextPath %>/announcements" method="post" class="form-grid">
            <% if (isAdmin) { %>
            <div class="form-group">
                <label><i class="fa-solid fa-bullseye"></i> Announcement Scope</label>
                <div class="radio-pills">
                    <label class="radio-pill">
                        <input type="radio" name="scope" id="scopeClass" value="class" checked onchange="toggleScope()"> Specific Class
                    </label>
                    <label class="radio-pill">
                        <input type="radio" name="scope" id="scopeBroadcast" value="broadcast" onchange="toggleScope()"> Role Broadcast
                    </label>
                </div>
            </div>

            <div class="form-group" id="broadcastScope" style="display: none;">
                <label for="targetRole"><i class="fa-solid fa-users"></i> Target Audience (All users with role)</label>
                <select name="targetRole" id="targetRole" class="form-control">
                    <option value="STUDENT">All Active Students</option>
                    <option value="PARENT">All Active Parents</option>
                    <option value="TUTOR">All Active Tutors</option>
                </select>
            </div>
            <% } else { %>
                <input type="hidden" name="scope" value="class">
            <% } %>

            <div class="form-group" id="classScope">
                <label for="classId"><i class="fa-solid fa-chalkboard"></i> Target Class</label>
                <select name="classId" id="classId" class="form-control" required>
                    <option value="">-- Select Class --</option>
                    <% if (classes != null) { for (Class c : classes) { %>
                        <option value="<%= c.getClassId() %>"><%= h(c.getSubject()) %> — <%= h(c.getBatch()) %></option>
                    <% } } %>
                </select>
            </div>

            <div class="form-group">
                <label for="title"><i class="fa-solid fa-heading"></i> Announcement Title</label>
                <input type="text" name="title" id="title" class="form-control" placeholder="e.g. Special Revision Class Rescheduled" required maxlength="200">
            </div>

            <div class="form-group">
                <label for="message"><i class="fa-solid fa-message"></i> Message Content</label>
                <textarea name="message" id="message" class="form-control" placeholder="Write your announcement details here..." required maxlength="1000"></textarea>
            </div>

            <button type="submit" class="btn-submit">
                <i class="fa-solid fa-paper-plane"></i> Publish &amp; Send
            </button>
        </form>
    </div>

    <% if (sentHistory != null && !sentHistory.isEmpty()) { %>
    <div class="card-panel">
        <h2 style="font-size: 18px; font-weight: 700; margin-bottom: 14px;"><i class="fa-solid fa-clock-rotate-left"></i> Sent Announcements History</h2>
        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Date &amp; Time</th>
                        <th>Title</th>
                        <th>Class / Target</th>
                        <th>Recipient</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                <% for (Notification n : sentHistory) { %>
                    <tr>
                        <td><%= n.getCreatedAt() != null ? n.getCreatedAt().toString().substring(0, 16) : "" %></td>
                        <td><strong><%= h(n.getTitle()) %></strong></td>
                        <td><%= n.getSubject() != null ? h(n.getSubject()) : "Broadcast" %></td>
                        <td><%= h(n.getRecipientName() != null ? n.getRecipientName() : "User #" + n.getRecipientId()) %></td>
                        <td><span class="badge <%= n.isRead() ? "badge-paid" : "badge-pending" %>"><%= n.isRead() ? "Read" : "Delivered" %></span></td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
    <% } %>
</main>

</body>
</html>
