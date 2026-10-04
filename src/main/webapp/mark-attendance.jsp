<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Class" %>
<%@ page import="model.Attendance" %>
<%@ page import="java.util.List" %>
<%!
    private String h(Object val) {
        if (val == null) return "";
        return String.valueOf(val).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    String contextPath = request.getContextPath();
    String errorMessage = request.getAttribute("errorMessage") != null ? request.getAttribute("errorMessage").toString() : "";
    String successMessage = request.getAttribute("successMessage") != null ? request.getAttribute("successMessage").toString() : "";
    List<Class> classes = (List<Class>) request.getAttribute("classes");
    List<Attendance> roster = (List<Attendance>) request.getAttribute("roster");
    Integer selectedClassId = (Integer) request.getAttribute("selectedClassId");
    String selectedDate = (String) request.getAttribute("selectedDate");
    String maxDate = request.getAttribute("maxDate") != null ? request.getAttribute("maxDate").toString() : java.time.LocalDate.now().toString();
    if (selectedDate == null || selectedDate.isBlank()) {
        selectedDate = maxDate;
    }

    String selectedClassName = "";
    if (classes != null && selectedClassId != null) {
        for (Class c : classes) {
            if (c.getClassId() == selectedClassId) {
                selectedClassName = c.getSubject() + " - " + c.getBatch();
                break;
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mark Attendance | Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/class-pages.css">
    <style>
        .att-shell { max-width: 1100px; margin: 32px auto; padding: 0 20px; }
        .att-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .card-panel { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; padding: 24px; box-shadow: 0 2px 8px rgba(0,0,0,.04); margin-bottom: 28px; }
        .panel-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 18px; }
        .panel-head h2 { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 18px; font-weight: 700; color: #171717; margin: 0; }
        .filter-row { display: flex; gap: 16px; align-items: flex-end; flex-wrap: wrap; }
        .form-group { display: flex; flex-direction: column; gap: 6px; }
        .form-group label { font-size: 13px; font-weight: 600; color: #374151; }
        .form-control { padding: 9px 12px; border: 1px solid #d4d4d4; border-radius: 8px; font-size: 13.5px; font-family: inherit; }
        .form-control:focus { border-color: #7c3aed; outline: none; box-shadow: 0 0 0 3px rgba(124, 58, 237, 0.1); }
        .table-wrap { overflow-x: auto; margin-top: 16px; }
        .data-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13.5px; }
        .data-table th { background: #f9fafb; padding: 13px 15px; border-bottom: 1px solid #e5e7eb; color: #4b5563; font-weight: 600; }
        .data-table td { padding: 13px 15px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
        .btn-action { background: #7c3aed; color: #fff; border: none; padding: 10px 22px; border-radius: 8px; font-weight: 600; font-size: 14px; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; }
        .btn-action:hover { background: #6d28d9; }
        .btn-clear { background: #fee2e2; color: #dc2626; border: none; padding: 6px 10px; border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 4px; }
        .btn-clear:hover { background: #fca5a5; }
        .alert-error { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        .alert-success { background: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0; padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        .status-select { padding: 7px 10px; border: 1px solid #d4d4d4; border-radius: 8px; font-size: 13px; font-weight: 600; }
        .status-select option[value="PRESENT"] { color: #15803d; }
        .status-select option[value="ABSENT"] { color: #b91c1c; }
        .status-select option[value="LATE"] { color: #b45309; }
    </style>
</head>
<body class="dash-body">

<header class="class-page-header">
    <a class="class-brand" href="<%= contextPath %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle">Attendance Management</span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= contextPath %>/dashboard"><i class="fa-solid fa-arrow-left"></i> Dashboard</a>
    </div>
</header>

<main class="att-shell">
    <div class="att-header">
        <div>
            <h1 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:24px;font-weight:700;margin:0;">Mark Daily Attendance</h1>
            <p style="font-size:14px;color:#737373;margin-top:4px;margin-bottom:0;">Record student presence, absence, or tardiness. Automated absence alerts are dispatched to parents.</p>
        </div>
    </div>

    <% if (!errorMessage.isEmpty()) { %>
        <div class="alert-error">
            <i class="fa-solid fa-circle-exclamation"></i>
            <span><%= h(errorMessage) %></span>
        </div>
    <% } %>

    <% if (!successMessage.isEmpty()) { %>
        <div class="alert-success">
            <i class="fa-solid fa-circle-check"></i>
            <span><%= h(successMessage) %></span>
        </div>
    <% } %>

    <div class="card-panel">
        <div class="panel-head">
            <h2><i class="fa-solid fa-filter" style="color:#7c3aed;"></i> Select Class &amp; Session Date</h2>
        </div>

        <form action="<%= contextPath %>/attendance" method="get">
            <div class="filter-row">
                <div class="form-group" style="flex: 2; min-width: 250px;">
                    <label for="classId">Class &amp; Batch</label>
                    <select name="classId" id="classId" class="form-control" required>
                        <option value="">-- Select Class --</option>
                        <% if (classes != null) { for (Class c : classes) { %>
                        <option value="<%= c.getClassId() %>"
                                <%= selectedClassId != null && selectedClassId == c.getClassId() ? "selected" : "" %>>
                            <%= h(c.getSubject()) %> - <%= h(c.getBatch()) %>
                        </option>
                        <% } } %>
                    </select>
                </div>

                <div class="form-group" style="flex: 1; min-width: 180px;">
                    <label for="date">Session Date <span style="font-size:11px;font-weight:600;color:#6b7280;">(Max: Today)</span></label>
                    <input type="date" name="date" id="date" class="form-control"
                           value="<%= h(selectedDate) %>"
                           max="<%= h(maxDate) %>" required>
                </div>

                <div class="form-group">
                    <button type="submit" class="btn-action">
                        <i class="fa-solid fa-users-viewfinder"></i> Load Roster
                    </button>
                </div>
            </div>
        </form>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const dateInput = document.getElementById('date');
            if (dateInput) {
                const maxAllowed = '<%= h(maxDate) %>';
                dateInput.max = maxAllowed;
                dateInput.addEventListener('change', function() {
                    if (this.value > maxAllowed) {
                        alert('Cannot select future dates for attendance. Session date reset to today (' + maxAllowed + ').');
                        this.value = maxAllowed;
                    }
                });
            }
        });
    </script>

    <% if (roster != null) { %>
    <div class="card-panel">
        <div class="panel-head">
            <div>
                <h2><i class="fa-solid fa-clipboard-user" style="color:#7c3aed;"></i> Roster: <%= h(selectedClassName) %></h2>
                <span style="font-size:13px;color:#737373;"><i class="fa-regular fa-calendar"></i> Date: <%= h(selectedDate) %> &bull; <%= roster.size() %> students</span>
            </div>
        </div>

        <form action="<%= contextPath %>/attendance" method="post">
            <input type="hidden" name="classId" value="<%= selectedClassId %>">
            <input type="hidden" name="sessionDate" value="<%= h(selectedDate) %>">

            <div class="table-wrap">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Student</th>
                            <th>Status</th>
                            <th>Remarks</th>
                            <th style="text-align:right;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Attendance a : roster) { 
                            boolean hasRecord = a.getAttendanceId() > 0;
                            String currentStatus = a.getStatus() != null ? a.getStatus().toUpperCase() : "PRESENT";
                        %>
                        <tr>
                            <td style="font-weight:600;">
                                <%= h(a.getStudentName()) %>
                                <input type="hidden" name="studentId" value="<%= a.getStudentId() %>">
                            </td>
                            <td>
                                <select name="status" class="status-select">
                                    <option value="PRESENT" <%= "PRESENT".equals(currentStatus) ? "selected" : "" %>>Present</option>
                                    <option value="ABSENT" <%= "ABSENT".equals(currentStatus) ? "selected" : "" %>>Absent</option>
                                    <option value="LATE" <%= "LATE".equals(currentStatus) ? "selected" : "" %>>Late</option>
                                </select>
                            </td>
                            <td>
                                <input type="text" name="remarks" maxlength="500" class="form-control"
                                       style="padding:6px 10px;font-size:13px;max-width:300px;"
                                       placeholder="Optional notes"
                                       value="<%= a.getRemarks() != null ? h(a.getRemarks()) : "" %>">
                            </td>
                            <td style="text-align:right;">
                                <% if (hasRecord) { %>
                                    <button type="submit" form="del-att-<%= a.getAttendanceId() %>" class="btn-clear"
                                            onclick="return confirm('Clear attendance record for <%= h(a.getStudentName()) %>?');">
                                        <i class="fa-solid fa-trash-can"></i> Clear
                                    </button>
                                <% } else { %>
                                    <span style="font-size:12px;color:#9ca3af;">-</span>
                                <% } %>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>

            <div style="margin-top:24px;display:flex;justify-content:flex-end;">
                <button type="submit" class="btn-action">
                    <i class="fa-solid fa-check"></i> Save Attendance
                </button>
            </div>
        </form>

        <%-- Clear/delete attendance forms --%>
        <% for (Attendance a : roster) {
            if (a.getAttendanceId() > 0) { %>
                <form id="del-att-<%= a.getAttendanceId() %>" action="<%= contextPath %>/attendance" method="post" style="display:none;">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="attendanceId" value="<%= a.getAttendanceId() %>">
                    <input type="hidden" name="returnUrl" value="<%= contextPath %>/attendance?classId=<%= selectedClassId %>&date=<%= selectedDate %>">
                </form>
        <%  }
        } %>
    </div>
    <% } %>
</main>

</body>
</html>