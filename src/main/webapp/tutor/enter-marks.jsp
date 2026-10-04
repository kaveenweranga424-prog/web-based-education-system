<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Exam" %>
<%@ page import="model.ExamResult" %>
<%@ page import="model.ExamMcqSubmission" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.math.BigDecimal" %>
<%!
    private String h(Object val) {
        if (val == null) return "";
        return String.valueOf(val).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    String contextPath = request.getContextPath();
    String errorMessage = request.getAttribute("errorMessage") != null ? request.getAttribute("errorMessage").toString() : "";
    Exam exam = (Exam) request.getAttribute("exam");
    List<ExamResult> roster = (List<ExamResult>) request.getAttribute("roster");
    Map<Integer, ExamMcqSubmission> mcqSubmissions = (Map<Integer, ExamMcqSubmission>) request.getAttribute("mcqSubmissions");

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
    <title>Enter Exam Marks | Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/class-pages.css">
    <style>
        .marks-shell { max-width: 1140px; margin: 32px auto; padding: 0 20px; }
        .marks-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .card-panel { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; padding: 24px; box-shadow: 0 2px 8px rgba(0,0,0,.04); margin-bottom: 28px; }
        .panel-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 18px; }
        .panel-head h2 { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 18px; font-weight: 700; color: #171717; margin: 0; }
        .table-wrap { overflow-x: auto; }
        .data-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13.5px; }
        .data-table th { background: #f9fafb; padding: 13px 15px; border-bottom: 1px solid #e5e7eb; color: #4b5563; font-weight: 600; }
        .data-table td { padding: 13px 15px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
        .form-control-num { width: 95px; padding: 7px 10px; border: 1px solid #d4d4d4; border-radius: 8px; font-size: 13.5px; font-family: inherit; }
        .form-control-num:focus { border-color: #7c3aed; outline: none; box-shadow: 0 0 0 3px rgba(124,58,237,0.1); }
        .form-control-text { width: 100%; max-width: 260px; padding: 7px 10px; border: 1px solid #d4d4d4; border-radius: 8px; font-size: 13.5px; font-family: inherit; }
        .form-control-text:focus { border-color: #7c3aed; outline: none; box-shadow: 0 0 0 3px rgba(124,58,237,0.1); }
        .btn-action { background: #7c3aed; color: #fff; border: none; padding: 10px 22px; border-radius: 8px; font-weight: 600; font-size: 14px; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; transition: background 0.15s ease; }
        .btn-action:hover { background: #6d28d9; }
        .btn-delete-mark { background: #fee2e2; color: #dc2626; border: none; padding: 6px 10px; border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 4px; }
        .btn-delete-mark:hover { background: #fca5a5; }
        .badge-grade { display: inline-block; padding: 3px 10px; border-radius: 9999px; font-size: 12px; font-weight: 700; }
        .grade-pass { background: #dcfce7; color: #15803d; }
        .grade-fail { background: #fee2e2; color: #b91c1c; }
        .alert-success { background: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0; padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        .alert-error { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        .meta-pill { display: inline-flex; align-items: center; gap: 6px; background: #f3f4f6; color: #4b5563; padding: 5px 12px; border-radius: 8px; font-size: 13px; font-weight: 500; }
        
        /* Submission Status Badges */
        .badge-sub-pending { background: #fef3c7; color: #b45309; padding: 3px 8px; border-radius: 6px; font-size: 11.5px; font-weight: 700; display: inline-flex; align-items: center; gap: 4px; }
        .badge-sub-reviewed { background: #ecfdf5; color: #047857; padding: 3px 8px; border-radius: 6px; font-size: 11.5px; font-weight: 700; display: inline-flex; align-items: center; gap: 4px; }
        .badge-sub-none { background: #f3f4f6; color: #6b7280; padding: 3px 8px; border-radius: 6px; font-size: 11.5px; font-weight: 600; display: inline-flex; align-items: center; gap: 4px; }
        
        .btn-review-q { background: #ede9fe; color: #6d28d9; border: 1px solid #ddd6fe; padding: 5px 10px; border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 5px; transition: all 0.15s ease; text-decoration: none; margin-top: 4px; }
        .btn-review-q:hover { background: #7c3aed; color: #fff; border-color: #7c3aed; }
        .btn-finish-exam { background: #dcfce7; color: #15803d; border: 1px solid #86efac; padding: 7px 14px; border-radius: 8px; font-size: 13px; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; transition: all 0.15s ease; text-decoration: none; }
        .btn-finish-exam:hover { background: #15803d; color: #fff; border-color: #15803d; }
        .btn-update-mark { background: #ede9fe; color: #6d28d9; border: 1px solid #c4b5fd; padding: 6px 12px; border-radius: 7px; font-size: 12px; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; gap: 5px; transition: all 0.15s ease; white-space: nowrap; }
        .btn-update-mark:hover { background: #7c3aed; color: #fff; border-color: #7c3aed; }
        .btn-publish-mark { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; padding: 6px 12px; border-radius: 7px; font-size: 12px; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; gap: 5px; transition: all 0.15s ease; white-space: nowrap; }
        .btn-publish-mark:hover { background: #10b981; color: #fff; border-color: #10b981; }

        /* Modal Styles */
        .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0, 0, 0, 0.55); z-index: 9999; backdrop-filter: blur(3px); align-items: center; justify-content: center; padding: 20px; }
        .modal-overlay.active { display: flex; }
        .modal-card { background: #fff; border-radius: 16px; width: 100%; max-width: 760px; max-height: 90vh; display: flex; flex-direction: column; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04); overflow: hidden; animation: modalIn 0.2s ease-out; }
        @keyframes modalIn { from { opacity: 0; transform: scale(0.96); } to { opacity: 1; transform: scale(1); } }
        .modal-header { padding: 18px 24px; border-bottom: 1px solid #e5e7eb; display: flex; align-items: center; justify-content: space-between; background: #fafafa; }
        .modal-header h3 { margin: 0; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 17px; font-weight: 700; color: #111827; }
        .modal-close-btn { background: none; border: none; font-size: 20px; color: #6b7280; cursor: pointer; padding: 4px; border-radius: 6px; }
        .modal-close-btn:hover { color: #111827; background: #f3f4f6; }
        .modal-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; padding: 14px 24px; background: #f8fafc; border-bottom: 1px solid #e2e8f0; }
        .stat-item { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px; text-align: center; }
        .stat-label { font-size: 11px; text-transform: uppercase; color: #64748b; font-weight: 600; }
        .stat-value { font-size: 16px; font-weight: 700; color: #0f172a; margin-top: 2px; }
        .modal-body { padding: 20px 24px; overflow-y: auto; flex: 1; }
        .modal-footer { padding: 16px 24px; border-top: 1px solid #e5e7eb; background: #fafafa; display: flex; justify-content: space-between; align-items: center; gap: 12px; flex-wrap: wrap; }
        
        .review-q-card { background: #fafafa; border: 1px solid #e5e7eb; border-radius: 12px; padding: 14px 16px; margin-bottom: 14px; }
        .review-q-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 10px; margin-bottom: 10px; }
        .review-q-num { background: #7c3aed; color: #fff; width: 24px; height: 24px; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700; flex-shrink: 0; }
        .review-q-title { font-size: 14px; font-weight: 600; color: #111827; flex: 1; }
        .review-opt { padding: 8px 12px; border: 1px solid #e5e7eb; border-radius: 8px; margin-bottom: 6px; font-size: 13px; display: flex; align-items: center; justify-content: space-between; background: #fff; }
        .review-opt.is-correct { border-color: #10b981; background: #ecfdf5; color: #047857; font-weight: 600; }
        .review-opt.is-student-wrong { border-color: #ef4444; background: #fef2f2; color: #991b1b; }
        .review-badge { font-size: 11px; font-weight: 700; padding: 2px 6px; border-radius: 4px; }
        .review-badge-green { background: #d1fae5; color: #047857; }
        .review-badge-red { background: #fee2e2; color: #b91c1c; }
    </style>
</head>
<body class="dash-body">

<header class="class-page-header">
    <a class="class-brand" href="<%= contextPath %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle">Grading &amp; Assessment</span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= contextPath %>/tutor/exams"><i class="fa-solid fa-arrow-left"></i> Exams List</a>
        <a class="class-nav-link" href="<%= contextPath %>/dashboard"><i class="fa-solid fa-gauge"></i> Dashboard</a>
    </div>
</header>

<main class="marks-shell">
    <% if (exam != null) { %>
    <div class="marks-header">
        <div>
            <h1 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:24px;font-weight:700;margin:0;">
                <%= h(exam.getExamName()) %>
            </h1>
            <div style="display:flex;gap:10px;margin-top:8px;flex-wrap:wrap;">
                <span class="meta-pill"><i class="fa-solid fa-book"></i> <%= h(exam.getSubject()) %> (<%= h(exam.getBatch()) %>)</span>
                <span class="meta-pill"><i class="fa-solid fa-star"></i> Max Marks: <%= exam.getMaxMarks() %></span>
                <span class="meta-pill"><i class="fa-regular fa-calendar"></i> Date: <%= exam.getExamDate() %></span>
            </div>
        </div>
        <div style="display:flex;gap:10px;flex-wrap:wrap;align-items:center;">
            <% boolean isCompletedExam = exam != null && "COMPLETED".equalsIgnoreCase(exam.getStatus());
               if (!isCompletedExam) { %>
                <a href="<%= contextPath %>/tutor/mcq?examId=<%= exam.getExamId() %>" class="btn-solid sm" style="text-decoration:none;background:#ede9fe;color:#6d28d9;display:inline-flex;align-items:center;gap:6px;">
                    <i class="fa-solid fa-list-check"></i> Manage MCQ Quiz
                </a>
                <form action="<%= contextPath %>/tutor/exams" method="post" style="display:inline;"
                      onsubmit="return confirm('Finish and complete this quiz process? This will finalize the exam and lock questions.');">
                    <input type="hidden" name="action" value="complete">
                    <input type="hidden" name="examId" value="<%= exam.getExamId() %>">
                    <button type="submit" class="btn-finish-exam">
                        <i class="fa-solid fa-circle-check"></i> Finish Quiz Process
                    </button>
                </form>
            <% } else { %>
                <span class="meta-pill" style="background:#dcfce7;color:#15803d;font-weight:700;"><i class="fa-solid fa-circle-check"></i> Status: COMPLETED</span>
            <% } %>
            <a href="<%= contextPath %>/tutor/exams" class="btn-solid sm" style="text-decoration:none;"><i class="fa-solid fa-arrow-left"></i> Back to Exams</a>
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

    <div class="card-panel">
        <div class="panel-head">
            <div>
                <h2><i class="fa-solid fa-pen-to-square" style="color:#7c3aed;"></i> Student Exam Roster</h2>
                <div style="font-size:13px;color:#737373;margin-top:2px;">Review student quiz submissions, verify marks, and release results.</div>
            </div>
            <span style="font-size:13px;color:#737373;"><%= roster != null ? roster.size() : 0 %> active students</span>
        </div>

        <form action="<%= contextPath %>/tutor/marks" method="post" id="bulkMarksForm">
            <input type="hidden" name="examId" value="<%= exam.getExamId() %>">

            <div class="table-wrap">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Student</th>
                            <th>Quiz Submission Status</th>
                            <th>Marks (Max <%= exam.getMaxMarks() %>)</th>
                            <th>Grade</th>
                            <th>Status &amp; Last Updated</th>
                            <th>Remarks</th>
                            <th style="text-align:right;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (roster != null && !roster.isEmpty()) {
                            for (ExamResult r : roster) {
                                boolean hasResult = r.getResultId() > 0;
                                String grade = r.getGrade();
                                boolean isFail = "F".equalsIgnoreCase(grade);
                                ExamMcqSubmission sub = mcqSubmissions != null ? mcqSubmissions.get(r.getStudentId()) : null;

                                // If marks not yet entered in exam_results, pre-fill with MCQ scaled marks
                                BigDecimal defaultMarks = r.getMarksObtained();
                                if (defaultMarks == null && sub != null && sub.getScaledMarks() != null) {
                                    defaultMarks = sub.getScaledMarks();
                                }

                                String defaultRemarks = r.getRemarks();
                        %>
                        <tr>
                            <td style="font-weight:600;">
                                <%= h(r.getStudentName()) %>
                                <input type="hidden" name="studentId" value="<%= r.getStudentId() %>">
                            </td>

                            <td>
                                <% if (sub != null) { 
                                    boolean isPending = !"REVIEWED".equalsIgnoreCase(sub.getStatus());
                                    if (isPending) { %>
                                        <span class="badge-sub-pending"><i class="fa-solid fa-clock"></i> Submitted (Needs Review)</span>
                                        <div style="font-size:11.5px;color:#6b7280;margin-top:2px;">
                                            Score: <%= sub.getCorrectAnswers() %>/<%= sub.getTotalQuestions() %> correct
                                        </div>
                                    <% } else { %>
                                        <span class="badge-sub-reviewed"><i class="fa-solid fa-circle-check"></i> Marks Released</span>
                                        <div style="font-size:11.5px;color:#6b7280;margin-top:2px;">
                                            Score: <%= sub.getCorrectAnswers() %>/<%= sub.getTotalQuestions() %> correct
                                        </div>
                                    <% } %>
                                    <div>
                                        <button type="button" class="btn-review-q"
                                                onclick="openReviewModal('<%= exam.getExamId() %>', '<%= r.getStudentId() %>', '<%= h(r.getStudentName()) %>')">
                                            <i class="fa-solid fa-clipboard-check"></i> Review Answers
                                        </button>
                                    </div>
                                <% } else { %>
                                    <span class="badge-sub-none"><i class="fa-solid fa-minus"></i> Not Attempted</span>
                                <% } %>
                            </td>

                            <td>
                                <input type="number" step="0.01" min="0" max="<%= exam.getMaxMarks() %>"
                                       name="marksObtained" id="row_marks_<%= r.getStudentId() %>" class="form-control-num"
                                       placeholder="Enter marks"
                                       value="<%= defaultMarks != null ? defaultMarks : "" %>">
                            </td>

                            <td>
                                <% if (grade != null && !grade.isBlank()) { %>
                                    <span class="badge-grade <%= isFail ? "grade-fail" : "grade-pass" %>"><%= h(grade) %></span>
                                <% } else { %>
                                    <span style="color:#9ca3af;font-size:12px;">Not graded</span>
                                <% } %>
                            </td>

                            <td>
                                <% if (r.getEnteredAt() != null) { 
                                    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("MMM dd, yyyy hh:mm a");
                                %>
                                    <div style="font-size:12px;color:#047857;font-weight:700;display:flex;align-items:center;gap:4px;">
                                        <i class="fa-solid fa-circle-check"></i> Graded
                                    </div>
                                    <div style="font-size:11px;color:#6b7280;margin-top:2px;" title="Last updated timestamp">
                                        <i class="fa-regular fa-clock"></i> <%= sdf.format(r.getEnteredAt()) %>
                                    </div>
                                <% } else { %>
                                    <span style="font-size:12px;color:#9ca3af;"><i class="fa-regular fa-clock"></i> Not graded</span>
                                <% } %>
                            </td>

                            <td>
                                <input type="text" name="remarks" id="row_remarks_<%= r.getStudentId() %>" maxlength="500" class="form-control-text"
                                       placeholder="Optional comment"
                                       value="<%= defaultRemarks != null ? h(defaultRemarks) : "" %>">
                            </td>

                            <td style="text-align:right;">
                                <div style="display:flex;align-items:center;justify-content:flex-end;gap:6px;">
                                    <% if (hasResult) { %>
                                        <button type="button" class="btn-update-mark"
                                                onclick="submitSingleStudent(<%= r.getStudentId() %>)"
                                                title="Save updated result for <%= h(r.getStudentName()) %>">
                                            <i class="fa-solid fa-arrows-rotate"></i> Update Result
                                        </button>
                                        <button type="submit" form="del-form-<%= r.getResultId() %>" class="btn-delete-mark"
                                                title="Clear score and revert to pending"
                                                onclick="return confirm('Clear score for <%= h(r.getStudentName()) %>? This will revert their quiz status to pending.');">
                                            <i class="fa-solid fa-trash-can"></i>
                                        </button>
                                    <% } else { %>
                                        <button type="button" class="btn-publish-mark"
                                                onclick="submitSingleStudent(<%= r.getStudentId() %>)"
                                                title="Save and publish marks for <%= h(r.getStudentName()) %>">
                                            <i class="fa-solid fa-paper-plane"></i> Save Result
                                        </button>
                                    <% } %>
                                </div>
                            </td>
                        </tr>
                        <% } } else { %>
                        <tr>
                            <td colspan="7" style="text-align:center;padding:32px;color:#6b7280;">
                                <i class="fa-solid fa-users-slash" style="font-size:24px;margin-bottom:8px;display:block;"></i>
                                No active students found enrolled in this class.
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>

            <p style="font-size:13px;color:#6b7280;margin:16px 0 0 0;display:flex;align-items:center;gap:6px;">
                <i class="fa-solid fa-circle-info" style="color:#7c3aed;"></i>
                <span>You can click <strong>Update Result</strong> in front of each student to save their latest marks individually anytime, or click <strong>Save &amp; Release All Marks</strong> below to update all rows at once.</span>
            </p>

            <% if (roster != null && !roster.isEmpty()) { %>
            <div style="margin-top:24px;display:flex;justify-content:flex-end;gap:12px;align-items:center;">
                <button type="submit" class="btn-action">
                    <i class="fa-solid fa-floppy-disk"></i> Save &amp; Release All Marks
                </button>
                <% if (!isCompletedExam) { %>
                    <button type="button" class="btn-finish-exam" style="padding:10px 18px;font-size:13.5px;"
                            onclick="if(confirm('Finish and complete this quiz process? This will finalize the exam, lock questions, and close the quiz.')) document.getElementById('finishExamFooterForm').submit();">
                        <i class="fa-solid fa-flag-checkered"></i> Finish &amp; Complete Exam
                    </button>
                <% } %>
            </div>
            <% } %>
        </form>

        <form id="finishExamFooterForm" action="<%= contextPath %>/tutor/exams" method="post" style="display:none;">
            <input type="hidden" name="action" value="complete">
            <input type="hidden" name="examId" value="<%= exam.getExamId() %>">
        </form>

        <%-- Independent single student save and delete forms outside bulk form --%>
        <% if (roster != null) {
            for (ExamResult r : roster) { %>
                <form id="single-form-<%= r.getStudentId() %>" action="<%= contextPath %>/tutor/marks" method="post" style="display:none;">
                    <input type="hidden" name="action" value="saveSingle">
                    <input type="hidden" name="examId" value="<%= exam.getExamId() %>">
                    <input type="hidden" name="studentId" value="<%= r.getStudentId() %>">
                    <input type="hidden" name="marksObtained" id="single_marks_<%= r.getStudentId() %>">
                    <input type="hidden" name="remarks" id="single_remarks_<%= r.getStudentId() %>">
                </form>
                <% if (r.getResultId() > 0) { %>
                    <form id="del-form-<%= r.getResultId() %>" action="<%= contextPath %>/tutor/marks" method="post" style="display:none;">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="examId" value="<%= exam.getExamId() %>">
                        <input type="hidden" name="resultId" value="<%= r.getResultId() %>">
                        <input type="hidden" name="studentId" value="<%= r.getStudentId() %>">
                    </form>
                <% } %>
        <%  }
        } %>
    </div>
    <% } else { %>
        <div class="card-panel">
            <p>Exam not found or you do not have permission to view it.</p>
            <a href="<%= contextPath %>/tutor/exams" class="btn-action">Back to Exams</a>
        </div>
    <% } %>
</main>

<!-- Review Student Answers Modal -->
<div class="modal-overlay" id="reviewModal">
    <div class="modal-card">
        <div class="modal-header">
            <div>
                <h3 id="modalStudentTitle"><i class="fa-solid fa-user-check" style="color:#7c3aed;margin-right:6px;"></i> Review Quiz Answers</h3>
                <div style="font-size:12px;color:#6b7280;margin-top:2px;" id="modalSubmittedAt">Submitted at: -</div>
            </div>
            <button type="button" class="modal-close-btn" onclick="closeReviewModal()">&times;</button>
        </div>

        <div class="modal-stats">
            <div class="stat-item">
                <div class="stat-label">Total Questions</div>
                <div class="stat-value" id="modalTotalQ">-</div>
            </div>
            <div class="stat-item">
                <div class="stat-label">Correct Answers</div>
                <div class="stat-value" style="color:#059669;" id="modalCorrectQ">-</div>
            </div>
            <div class="stat-item">
                <div class="stat-label">Points Earned</div>
                <div class="stat-value" id="modalEarnedPts">-</div>
            </div>
            <div class="stat-item">
                <div class="stat-label">Suggested Marks</div>
                <div class="stat-value" style="color:#7c3aed;" id="modalSuggestedMarks">-</div>
            </div>
        </div>

        <div class="modal-body" id="modalQuestionsBody">
            <div style="text-align:center;padding:30px;color:#6b7280;">
                <i class="fa-solid fa-spinner fa-spin" style="font-size:24px;margin-bottom:8px;display:block;"></i>
                Loading submission answers...
            </div>
        </div>

        <div class="modal-footer">
            <form action="<%= contextPath %>/tutor/marks" method="post" id="singleSaveForm" style="display:flex;align-items:center;gap:10px;width:100%;flex-wrap:wrap;">
                <input type="hidden" name="action" value="saveSingle">
                <input type="hidden" name="examId" value="<%= exam != null ? exam.getExamId() : 0 %>">
                <input type="hidden" name="studentId" id="singleStudentId" value="">

                <div style="display:flex;align-items:center;gap:6px;">
                    <label style="font-size:13px;font-weight:600;color:#374151;">Marks:</label>
                    <input type="number" step="0.01" min="0" max="<%= exam != null ? exam.getMaxMarks() : 100 %>"
                           name="marksObtained" id="singleMarksInput" required class="form-control-num" style="width:100px;">
                </div>

                <div style="display:flex;align-items:center;gap:6px;flex:1;min-width:180px;">
                    <label style="font-size:13px;font-weight:600;color:#374151;">Remarks:</label>
                    <input type="text" name="remarks" id="singleRemarksInput" class="form-control-text" style="width:100%;" placeholder="Remarks for student">
                </div>

                <div style="display:flex;gap:8px;margin-left:auto;">
                    <button type="button" class="btn-solid sm" style="background:#f3f4f6;color:#374151;border:1px solid #d1d5db;" onclick="closeReviewModal()">Close</button>
                    <button type="submit" class="btn-action" style="padding:8px 16px;font-size:13.5px;">
                        <i class="fa-solid fa-circle-check"></i> Release Marks to Student
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    function submitSingleStudent(studentId) {
        var markInput = document.getElementById('row_marks_' + studentId);
        var val = markInput ? markInput.value.trim() : '';
        if (!val) {
            alert('Please enter a mark before updating.');
            if (markInput) markInput.focus();
            return;
        }
        var num = parseFloat(val);
        var maxMarks = <%= exam != null ? exam.getMaxMarks() : 100 %>;
        if (isNaN(num) || num < 0 || num > maxMarks) {
            alert('Please enter a valid mark between 0 and ' + maxMarks + '.');
            if (markInput) markInput.focus();
            return;
        }
        var remInput = document.getElementById('row_remarks_' + studentId);
        document.getElementById('single_marks_' + studentId).value = val;
        document.getElementById('single_remarks_' + studentId).value = remInput ? remInput.value : '';
        document.getElementById('single-form-' + studentId).submit();
    }

    function openReviewModal(examId, studentId, studentName) {
        const modal = document.getElementById('reviewModal');
        modal.classList.add('active');
        document.getElementById('modalStudentTitle').innerHTML = '<i class="fa-solid fa-user-check" style="color:#7c3aed;margin-right:6px;"></i> Review Quiz: ' + escapeHtml(studentName);
        document.getElementById('singleStudentId').value = studentId;

        const bodyEl = document.getElementById('modalQuestionsBody');
        bodyEl.innerHTML = '<div style="text-align:center;padding:30px;color:#6b7280;"><i class="fa-solid fa-spinner fa-spin" style="font-size:24px;margin-bottom:8px;display:block;"></i>Loading submission answers...</div>';

        fetch('<%= contextPath %>/tutor/marks?action=getReviewJson&examId=' + examId + '&studentId=' + studentId)
            .then(res => res.json())
            .then(data => {
                if (data.error) {
                    bodyEl.innerHTML = '<div style="text-align:center;color:#dc2626;padding:20px;">' + escapeHtml(data.error) + '</div>';
                    return;
                }

                document.getElementById('modalSubmittedAt').innerText = 'Submitted at: ' + (data.submittedAt || 'N/A') + ' | Status: ' + data.status;
                document.getElementById('modalTotalQ').innerText = data.totalQuestions || 0;
                document.getElementById('modalCorrectQ').innerText = (data.correctAnswers || 0) + ' / ' + (data.totalQuestions || 0);
                document.getElementById('modalEarnedPts').innerText = (data.scoreObtained || 0) + ' / ' + (data.maxPossible || 0);
                document.getElementById('modalSuggestedMarks').innerText = data.suggestedMarks || 0;

                document.getElementById('singleMarksInput').value = data.suggestedMarks || 0;
                document.getElementById('singleRemarksInput').value = '';

                let html = '';
                if (data.items && data.items.length > 0) {
                    data.items.forEach((item, index) => {
                        const isCorrect = item.isCorrect;
                        const sel = (item.selectedOption || '').toUpperCase();
                        const cor = (item.correctOption || '').toUpperCase();

                        html += '<div class="review-q-card">';
                        html += '  <div class="review-q-head">';
                        html += '    <span class="review-q-num">' + (index + 1) + '</span>';
                        html += '    <div class="review-q-title">' + escapeHtml(item.questionText) + '</div>';
                        html += '    <div>';
                        if (isCorrect) {
                            html += '      <span class="review-badge review-badge-green"><i class="fa-solid fa-check"></i> Correct (+' + item.points + ')</span>';
                        } else {
                            html += '      <span class="review-badge review-badge-red"><i class="fa-solid fa-xmark"></i> Incorrect (0/' + item.points + ')</span>';
                        }
                        html += '    </div>';
                        html += '  </div>';

                        // Options
                        const opts = [
                            { letter: 'A', text: item.optionA },
                            { letter: 'B', text: item.optionB },
                            { letter: 'C', text: item.optionC },
                            { letter: 'D', text: item.optionD }
                        ];

                        opts.forEach(o => {
                            let optClass = 'review-opt';
                            let badge = '';

                            if (o.letter === cor) {
                                optClass += ' is-correct';
                                badge = '<span class="review-badge review-badge-green">Correct Answer</span>';
                            }
                            if (o.letter === sel && o.letter !== cor) {
                                optClass += ' is-student-wrong';
                                badge = '<span class="review-badge review-badge-red">Student Choice</span>';
                            } else if (o.letter === sel && o.letter === cor) {
                                badge = '<span class="review-badge review-badge-green">Student Choice (Correct)</span>';
                            }

                            html += '  <div class="' + optClass + '">';
                            html += '    <span><strong>' + o.letter + '.</strong> ' + escapeHtml(o.text) + '</span>';
                            html += '    ' + badge;
                            html += '  </div>';
                        });

                        html += '</div>';
                    });
                } else {
                    html = '<p style="text-align:center;color:#6b7280;">No questions found.</p>';
                }

                bodyEl.innerHTML = html;
            })
            .catch(err => {
                console.error(err);
                bodyEl.innerHTML = '<div style="text-align:center;color:#dc2626;padding:20px;">Failed to load submission details.</div>';
            });
    }

    function closeReviewModal() {
        document.getElementById('reviewModal').classList.remove('active');
    }

    function escapeHtml(text) {
        if (!text) return '';
        const map = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' };
        return String(text).replace(/[&<>"']/g, m => map[m]);
    }

    // Close on overlay click outside card
    document.getElementById('reviewModal').addEventListener('click', function(e) {
        if (e.target === this) {
            closeReviewModal();
        }
    });
</script>

</body>
</html>