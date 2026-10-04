<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Class" %>
<%@ page import="model.Exam" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%!
    private String h(Object val) {
        if (val == null) return "";
        return String.valueOf(val).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    String contextPath = request.getContextPath();
    String errorMessage = request.getAttribute("errorMessage") != null ? request.getAttribute("errorMessage").toString() : "";
    List<Class> classes = (List<Class>) request.getAttribute("classes");
    List<Exam> exams = (List<Exam>) request.getAttribute("exams");
    Map<Integer, Integer> submissionCounts = (Map<Integer, Integer>) request.getAttribute("submissionCounts");
    Map<Integer, Integer> pendingCounts = (Map<Integer, Integer>) request.getAttribute("pendingCounts");

    String flashSuccess = (String) session.getAttribute("flashSuccess");
    if (flashSuccess != null) {
        session.removeAttribute("flashSuccess");
    }
    String flashError = (String) session.getAttribute("flashError");
    if (flashError != null) {
        session.removeAttribute("flashError");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Schedule Exams | Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/class-pages.css">
    <style>
        .exam-shell { max-width: 1200px; margin: 32px auto; padding: 0 20px; }
        .exam-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .card-panel { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; padding: 24px; box-shadow: 0 2px 8px rgba(0,0,0,.04); margin-bottom: 28px; }
        .panel-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 18px; }
        .panel-head h2 { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 18px; font-weight: 700; color: #171717; margin: 0; }
        .table-wrap { overflow-x: auto; }
        .data-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13.5px; }
        .data-table th { background: #f9fafb; padding: 13px 15px; border-bottom: 1px solid #e5e7eb; color: #4b5563; font-weight: 600; }
        .data-table td { padding: 13px 15px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
        .form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; align-items: flex-end; }
        .form-group { display: flex; flex-direction: column; gap: 6px; }
        .form-group label { font-size: 13px; font-weight: 600; color: #374151; }
        .form-control { padding: 9px 12px; border: 1px solid #d4d4d4; border-radius: 8px; font-size: 13.5px; font-family: inherit; width: 100%; box-sizing: border-box; }
        .form-control:focus { border-color: #7c3aed; outline: none; box-shadow: 0 0 0 3px rgba(124, 58, 237, 0.1); }
        .btn-action { background: #7c3aed; color: #fff; border: none; padding: 10px 18px; border-radius: 8px; font-weight: 600; font-size: 13.5px; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; gap: 8px; }
        .btn-action:hover { background: #6d28d9; }
        .btn-enter-marks { background: #ede9fe; color: #6d28d9; border: none; padding: 6px 12px; border-radius: 6px; font-size: 12.5px; font-weight: 600; text-decoration: none; display: inline-flex; align-items: center; gap: 5px; }
        .btn-enter-marks:hover { background: #ddd6fe; }
        .btn-manage-mcq { background: #e0e7ff; color: #4338ca; border: none; padding: 6px 12px; border-radius: 6px; font-size: 12.5px; font-weight: 600; text-decoration: none; display: inline-flex; align-items: center; gap: 5px; }
        .btn-manage-mcq:hover { background: #c7d2fe; }
        .btn-finish-exam { background: #dcfce7; color: #15803d; border: 1px solid #86efac; padding: 6px 12px; border-radius: 6px; font-size: 12px; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; gap: 4px; transition: all 0.15s ease; }
        .btn-finish-exam:hover { background: #15803d; color: #fff; border-color: #15803d; }
        .btn-cancel-exam { background: #fee2e2; color: #dc2626; border: none; padding: 6px 10px; border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 4px; }
        .btn-cancel-exam:hover { background: #fca5a5; }
        .badge-status { padding: 4px 10px; border-radius: 9999px; font-size: 11.5px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; display: inline-block; }
        .badge-scheduled { background: #dbeafe; color: #1d4ed8; }
        .badge-completed { background: #dcfce7; color: #15803d; }
        .badge-cancelled { background: #f3f4f6; color: #6b7280; }
        .alert-success { background: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0; padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        .alert-error { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
    </style>
</head>
<body class="dash-body">

<header class="class-page-header">
    <a class="class-brand" href="<%= contextPath %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle">Examination Management</span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= contextPath %>/dashboard"><i class="fa-solid fa-arrow-left"></i> Dashboard</a>
    </div>
</header>

<main class="exam-shell">
    <div class="exam-header">
        <div>
            <h1 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:24px;font-weight:700;margin:0;">Assessments &amp; Examinations</h1>
            <p style="font-size:14px;color:#737373;margin-top:4px;margin-bottom:0;">Schedule upcoming class exams, manage quizzes, enter marks, and complete exam processes.</p>
        </div>
    </div>

    <% if (flashSuccess != null && !flashSuccess.isEmpty()) { %>
        <div class="alert-success">
            <i class="fa-solid fa-circle-check"></i>
            <span><%= h(flashSuccess) %></span>
        </div>
    <% } %>

    <% if (flashError != null && !flashError.isEmpty()) { %>
        <div class="alert-error">
            <i class="fa-solid fa-circle-exclamation"></i>
            <span><%= h(flashError) %></span>
        </div>
    <% } %>

    <% if (!errorMessage.isEmpty()) { %>
        <div class="alert-error">
            <i class="fa-solid fa-circle-exclamation"></i>
            <span><%= h(errorMessage) %></span>
        </div>
    <% } %>

    <!-- Schedule New Exam Card -->
    <div class="card-panel">
        <div class="panel-head">
            <h2><i class="fa-solid fa-calendar-plus" style="color:#7c3aed;"></i> Schedule New Exam</h2>
        </div>

        <form action="<%= contextPath %>/tutor/exams" method="post">
            <input type="hidden" name="action" value="create">

            <div class="form-grid">
                <div class="form-group" style="grid-column: span 1;">
                    <label for="classId"><i class="fa-solid fa-book"></i> Select Class</label>
                    <select name="classId" id="classId" class="form-control" required>
                        <option value="">-- Choose Class --</option>
                        <% if (classes != null) { for (Class c : classes) { %>
                        <option value="<%= c.getClassId() %>"><%= h(c.getSubject()) %> - <%= h(c.getBatch()) %></option>
                        <% } } %>
                    </select>
                </div>

                <div class="form-group">
                    <label for="examName"><i class="fa-solid fa-pen-nib"></i> Exam Name</label>
                    <input type="text" name="examName" id="examName" class="form-control"
                           required maxlength="150" placeholder="e.g. Mid-Term Test">
                </div>

                <div class="form-group">
                    <label for="examDate"><i class="fa-regular fa-calendar"></i> Exam Date</label>
                    <input type="date" name="examDate" id="examDate" class="form-control" required>
                </div>

                <div class="form-group">
                    <label for="maxMarks"><i class="fa-solid fa-award"></i> Maximum Marks</label>
                    <input type="number" step="0.01" min="1" name="maxMarks" id="maxMarks" class="form-control"
                           required value="100" placeholder="100">
                </div>

                <div class="form-group">
                    <button type="submit" class="btn-action">
                        <i class="fa-solid fa-plus"></i> Schedule Exam
                    </button>
                </div>
            </div>
        </form>
    </div>

    <!-- Scheduled Exams Table -->
    <div class="card-panel">
        <div class="panel-head">
            <h2><i class="fa-solid fa-list-check" style="color:#7c3aed;"></i> Scheduled Exams</h2>
            <span style="font-size:13px;color:#737373;"><%= exams != null ? exams.size() : 0 %> exams recorded</span>
        </div>

        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Exam Name</th>
                        <th>Class / Batch</th>
                        <th>Exam Date</th>
                        <th>Max Marks</th>
                        <th>Status</th>
                        <th style="text-align:right;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (exams != null && !exams.isEmpty()) { 
                        for (Exam e : exams) { 
                            String status = e.getStatus() != null ? e.getStatus().toUpperCase() : "SCHEDULED";
                            String badgeClass = "badge-scheduled";
                            boolean isCompleted = "COMPLETED".equals(status);
                            boolean isCancelled = "CANCELLED".equals(status);
                            if (isCompleted) {
                                badgeClass = "badge-completed";
                            } else if (isCancelled) {
                                badgeClass = "badge-cancelled";
                            }
                    %>
                    <tr>
                        <td style="font-weight:700;color:#111827;">
                            <i class="fa-solid fa-file-lines" style="color:#7c3aed;margin-right:6px;"></i>
                            <%= h(e.getExamName()) %>
                        </td>
                        <td><%= h(e.getSubject()) %> <span style="font-size:12px;color:#6b7280;">(<%= h(e.getBatch()) %>)</span></td>
                        <td><i class="fa-regular fa-calendar-days" style="color:#9ca3af;margin-right:4px;"></i><%= e.getExamDate() %></td>
                        <td style="font-weight:600;"><%= e.getMaxMarks() %></td>
                        <td><span class="badge-status <%= badgeClass %>"><%= status %></span></td>
                        <td style="text-align:right;">
                            <% if (isCompleted) { %>
                                <a href="<%= contextPath %>/tutor/marks?examId=<%= e.getExamId() %>" class="btn-enter-marks">
                                    <i class="fa-solid fa-award"></i> View Marks
                                </a>
                                <span style="font-size:12px;color:#15803d;margin-left:6px;font-weight:700;display:inline-flex;align-items:center;gap:4px;">
                                    <i class="fa-solid fa-circle-check"></i> Completed
                                </span>
                            <% } else if (!isCancelled) { 
                                int subCount = submissionCounts != null ? submissionCounts.getOrDefault(e.getExamId(), 0) : 0;
                                int pCount = pendingCounts != null ? pendingCounts.getOrDefault(e.getExamId(), 0) : 0;
                            %>
                                <a href="<%= contextPath %>/tutor/mcq?examId=<%= e.getExamId() %>" class="btn-manage-mcq">
                                    <i class="fa-solid fa-list-check"></i> Manage Quiz
                                </a>
                                <% if (subCount > 0) { %>
                                    <a href="<%= contextPath %>/tutor/marks?examId=<%= e.getExamId() %>" class="btn-enter-marks" style="margin-left:4px;">
                                        <i class="fa-solid fa-pen-to-square"></i> Review &amp; Enter Marks
                                        <% if (pCount > 0) { %>
                                            <span style="background:#ef4444;color:#fff;padding:1px 6px;border-radius:10px;font-size:11px;margin-left:4px;"><%= pCount %></span>
                                        <% } %>
                                    </a>
                                <% } else { %>
                                    <span style="font-size:12px;color:#6b7280;margin-left:6px;display:inline-flex;align-items:center;gap:4px;">
                                        <i class="fa-regular fa-clock"></i> Awaiting Submissions
                                    </span>
                                <% } %>
                                <form style="display:inline;margin-left:4px;" action="<%= contextPath %>/tutor/exams" method="post"
                                      onsubmit="return confirm('Finish and complete this quiz process for <%= h(e.getExamName()) %>? Once completed, quiz questions will be locked and no more questions can be added.');">
                                    <input type="hidden" name="action" value="complete">
                                    <input type="hidden" name="examId" value="<%= e.getExamId() %>">
                                    <button type="submit" class="btn-finish-exam" title="Finish and close this quiz process">
                                        <i class="fa-solid fa-circle-check"></i> Finish Quiz
                                    </button>
                                </form>
                                <form style="display:inline;margin-left:4px;" action="<%= contextPath %>/tutor/exams" method="post"
                                      onsubmit="return confirm('Are you sure you want to cancel <%= h(e.getExamName()) %>?');">
                                    <input type="hidden" name="action" value="cancel">
                                    <input type="hidden" name="examId" value="<%= e.getExamId() %>">
                                    <button type="submit" class="btn-cancel-exam">
                                        <i class="fa-solid fa-ban"></i> Cancel
                                    </button>
                                </form>
                            <% } else { %>
                                <span style="font-size:12px;color:#9ca3af;">Cancelled</span>
                            <% } %>
                        </td>
                    </tr>
                    <%  } 
                    } else { %>
                    <tr>
                        <td colspan="6" style="text-align:center;padding:32px;color:#6b7280;">
                            <i class="fa-solid fa-calendar-xmark" style="font-size:24px;margin-bottom:8px;display:block;"></i>
                            No exams have been scheduled yet. Use the form above to create your first exam.
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>
</main>

</body>
</html>