<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Exam" %>
<%@ page import="model.ExamMcqQuestion" %>
<%@ page import="model.ExamMcqSubmission" %>
<%@ page import="java.util.List" %>
<%@ page import="java.math.BigDecimal" %>
<%!
    private String h(Object val) {
        if (val == null) return "";
        return String.valueOf(val).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    String contextPath = request.getContextPath();
    Exam exam = (Exam) request.getAttribute("exam");
    List<ExamMcqQuestion> questions = (List<ExamMcqQuestion>) request.getAttribute("questions");
    List<ExamMcqSubmission> submissions = (List<ExamMcqSubmission>) request.getAttribute("submissions");

    String flashSuccess = (String) session.getAttribute("flashSuccess");
    if (flashSuccess != null) {
        session.removeAttribute("flashSuccess");
    }
    String flashError = (String) session.getAttribute("flashError");
    if (flashError != null) {
        session.removeAttribute("flashError");
    }

    boolean isCompleted = exam != null && "COMPLETED".equalsIgnoreCase(exam.getStatus());

    BigDecimal totalPoints = BigDecimal.ZERO;
    if (questions != null) {
        for (ExamMcqQuestion q : questions) {
            if (q.getPoints() != null) {
                totalPoints = totalPoints.add(q.getPoints());
            }
        }
    }
    int questionCount = questions != null ? questions.size() : 0;
    int submissionCount = submissions != null ? submissions.size() : 0;
    int pendingCount = 0;
    if (submissions != null) {
        for (ExamMcqSubmission s : submissions) {
            if (!"REVIEWED".equalsIgnoreCase(s.getStatus())) {
                pendingCount++;
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage MCQ Quiz | Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/class-pages.css">
    <style>
        .mcq-shell { max-width: 1080px; margin: 32px auto; padding: 0 20px; }
        .mcq-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .card-panel { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; padding: 24px; box-shadow: 0 2px 8px rgba(0,0,0,.04); margin-bottom: 28px; }
        .panel-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 18px; }
        .panel-head h2 { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 18px; font-weight: 700; color: #171717; margin: 0; }
        .meta-pill { display: inline-flex; align-items: center; gap: 6px; background: #f3f4f6; color: #4b5563; padding: 5px 12px; border-radius: 8px; font-size: 13px; font-weight: 500; }
        .meta-pill-highlight { background: #ede9fe; color: #6d28d9; font-weight: 600; }
        .meta-pill-warning { background: #fef3c7; color: #b45309; font-weight: 700; }
        .meta-pill-success { background: #dcfce7; color: #15803d; font-weight: 700; }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        .form-group { display: flex; flex-direction: column; gap: 6px; margin-bottom: 14px; }
        .form-group.full { grid-column: span 2; }
        .form-group label { font-size: 13px; font-weight: 600; color: #374151; }
        .form-control { padding: 9px 12px; border: 1px solid #d4d4d4; border-radius: 8px; font-size: 13.5px; font-family: inherit; width: 100%; box-sizing: border-box; }
        .form-control:focus { border-color: #7c3aed; outline: none; box-shadow: 0 0 0 3px rgba(124, 58, 237, 0.1); }
        .btn-action { background: #7c3aed; color: #fff; border: none; padding: 10px 20px; border-radius: 8px; font-weight: 600; font-size: 13.5px; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; gap: 8px; transition: background 0.15s ease; }
        .btn-action:hover { background: #6d28d9; }
        .btn-delete-q { background: #fee2e2; color: #dc2626; border: none; padding: 6px 12px; border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 5px; }
        .btn-delete-q:hover { background: #fca5a5; }
        .btn-secondary { background: #f3f4f6; color: #374151; border: 1px solid #d1d5db; padding: 9px 16px; border-radius: 8px; font-weight: 600; font-size: 13.5px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; }
        .btn-secondary:hover { background: #e5e7eb; }
        .btn-marks { background: #10b981; color: #fff; border: none; padding: 9px 16px; border-radius: 8px; font-weight: 600; font-size: 13.5px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; }
        .btn-marks:hover { background: #059669; }
        .btn-finish-exam { background: #dcfce7; color: #15803d; border: 1px solid #86efac; padding: 8px 16px; border-radius: 8px; font-weight: 700; font-size: 13px; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; transition: all 0.15s ease; }
        .btn-finish-exam:hover { background: #15803d; color: #fff; border-color: #15803d; }
        .alert-success { background: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0; padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        .alert-error { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        .q-card { background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 12px; padding: 18px 20px; margin-bottom: 16px; }
        .q-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; margin-bottom: 12px; }
        .q-number { background: #7c3aed; color: #fff; width: 26px; height: 26px; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 13px; font-weight: 700; flex-shrink: 0; }
        .q-text { font-size: 15px; font-weight: 600; color: #111827; flex: 1; }
        .q-options-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-top: 10px; }
        .q-opt-box { padding: 9px 14px; border-radius: 8px; font-size: 13.5px; border: 1px solid #e5e7eb; background: #fff; display: flex; align-items: center; gap: 8px; }
        .q-opt-box.is-correct { background: #ecfdf5; border-color: #10b981; color: #047857; font-weight: 600; }
        .opt-letter { font-weight: 700; width: 22px; height: 22px; border-radius: 4px; background: #f3f4f6; display: inline-flex; align-items: center; justify-content: center; font-size: 12px; color: #4b5563; }
        .q-opt-box.is-correct .opt-letter { background: #10b981; color: #fff; }
        .empty-box { text-align: center; padding: 40px 20px; color: #6b7280; }
        
        .sub-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13.5px; }
        .sub-table th { background: #f9fafb; padding: 12px 14px; border-bottom: 1px solid #e5e7eb; color: #4b5563; font-weight: 600; }
        .sub-table td { padding: 12px 14px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
        .badge-pending { background: #fef3c7; color: #b45309; padding: 3px 8px; border-radius: 6px; font-size: 11.5px; font-weight: 700; display: inline-flex; align-items: center; gap: 4px; }
        .badge-reviewed { background: #ecfdf5; color: #047857; padding: 3px 8px; border-radius: 6px; font-size: 11.5px; font-weight: 700; display: inline-flex; align-items: center; gap: 4px; }
    </style>
</head>
<body class="dash-body">

<header class="class-page-header">
    <a class="class-brand" href="<%= contextPath %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle">MCQ Quiz Creator</span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= contextPath %>/tutor/exams"><i class="fa-solid fa-arrow-left"></i> Exams List</a>
        <a class="class-nav-link" href="<%= contextPath %>/dashboard"><i class="fa-solid fa-gauge"></i> Dashboard</a>
    </div>
</header>

<main class="mcq-shell">
    <% if (exam != null) { %>
    <div class="mcq-header">
        <div>
            <h1 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:24px;font-weight:700;margin:0;">
                <i class="fa-solid fa-list-check" style="color:#7c3aed;margin-right:8px;"></i>
                MCQ Quiz: <%= h(exam.getExamName()) %>
            </h1>
            <div style="display:flex;gap:10px;margin-top:8px;flex-wrap:wrap;">
                <span class="meta-pill"><i class="fa-solid fa-book"></i> <%= h(exam.getSubject()) %> (<%= h(exam.getBatch()) %>)</span>
                <span class="meta-pill"><i class="fa-solid fa-award"></i> Exam Max Marks: <%= exam.getMaxMarks() %></span>
                <span class="meta-pill meta-pill-highlight"><i class="fa-solid fa-circle-question"></i> <%= questionCount %> Questions</span>
                <span class="meta-pill meta-pill-highlight"><i class="fa-solid fa-star"></i> Total Points: <%= totalPoints %></span>
                <% if (isCompleted) { %>
                    <span class="meta-pill meta-pill-success"><i class="fa-solid fa-circle-check"></i> Status: COMPLETED</span>
                <% } else if (pendingCount > 0) { %>
                    <span class="meta-pill meta-pill-warning"><i class="fa-solid fa-clock"></i> <%= pendingCount %> Pending Review</span>
                <% } %>
            </div>
        </div>
        <div style="display:flex;gap:10px;flex-wrap:wrap;align-items:center;">
            <% if (!isCompleted) { %>
                <form action="<%= contextPath %>/tutor/exams" method="post" style="display:inline;"
                      onsubmit="return confirm('Finish and complete this quiz process? Once marked completed, quiz questions will be locked and no more questions can be added.');">
                    <input type="hidden" name="action" value="complete">
                    <input type="hidden" name="examId" value="<%= exam.getExamId() %>">
                    <button type="submit" class="btn-finish-exam">
                        <i class="fa-solid fa-circle-check"></i> Finish Quiz Process
                    </button>
                </form>
            <% } %>
            <% if (submissionCount > 0) { %>
                <a href="<%= contextPath %>/tutor/marks?examId=<%= exam.getExamId() %>" class="btn-marks">
                    <i class="fa-solid fa-pen-to-square"></i> Review Submissions (<%= submissionCount %>)
                    <% if (pendingCount > 0) { %>
                        <span style="background:#ef4444;color:#fff;padding:1px 6px;border-radius:10px;font-size:11px;margin-left:4px;"><%= pendingCount %></span>
                    <% } %>
                </a>
            <% } else { %>
                <span class="meta-pill" style="color:#6b7280;font-size:12.5px;">
                    <i class="fa-regular fa-clock"></i> No Submissions Yet
                </span>
            <% } %>
            <a href="<%= contextPath %>/tutor/exams" class="btn-secondary">
                <i class="fa-solid fa-arrow-left"></i> Back to Exams
            </a>
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

    <% if (isCompleted) { %>
        <!-- Completed Banner (Questions Locked - No adding/editing allowed) -->
        <div class="card-panel" style="background:#f0fdf4;border:1px solid #86efac;padding:22px 24px;border-radius:16px;">
            <div style="display:flex;align-items:center;gap:16px;flex-wrap:wrap;">
                <i class="fa-solid fa-lock" style="font-size:32px;color:#16a34a;"></i>
                <div style="flex:1;">
                    <h3 style="margin:0 0 4px 0;font-size:17px;font-weight:700;color:#14532d;">Quiz Process Finished &amp; Completed</h3>
                    <p style="margin:0;font-size:13.5px;color:#166534;">This quiz has been marked as Completed. Question modifications are locked. No additional questions can be added to this quiz.</p>
                </div>
                <a href="<%= contextPath %>/tutor/marks?examId=<%= exam.getExamId() %>" class="btn-marks" style="padding:10px 18px;">
                    <i class="fa-solid fa-award"></i> View Student Marks Sheet
                </a>
            </div>
        </div>
    <% } else { %>
        <!-- Add Question Panel (Only active when quiz is not completed) -->
        <div class="card-panel">
            <div class="panel-head">
                <h2><i class="fa-solid fa-plus-circle" style="color:#7c3aed;"></i> Add New Question</h2>
                <span style="font-size:13px;color:#737373;">Enter question, 4 choices, and select the correct answer</span>
            </div>

            <form action="<%= contextPath %>/tutor/mcq" method="post">
                <input type="hidden" name="action" value="add">
                <input type="hidden" name="examId" value="<%= exam.getExamId() %>">

                <div class="form-group full">
                    <label for="questionText"><i class="fa-solid fa-circle-question"></i> Question Prompt *</label>
                    <textarea name="questionText" id="questionText" rows="2" class="form-control" required
                              placeholder="Type your question prompt here..."></textarea>
                </div>

                <div class="form-grid">
                    <div class="form-group">
                        <label for="optionA"><span class="opt-letter">A</span> Option A *</label>
                        <input type="text" name="optionA" id="optionA" class="form-control" required placeholder="Option A content">
                    </div>
                    <div class="form-group">
                        <label for="optionB"><span class="opt-letter">B</span> Option B *</label>
                        <input type="text" name="optionB" id="optionB" class="form-control" required placeholder="Option B content">
                    </div>
                    <div class="form-group">
                        <label for="optionC"><span class="opt-letter">C</span> Option C *</label>
                        <input type="text" name="optionC" id="optionC" class="form-control" required placeholder="Option C content">
                    </div>
                    <div class="form-group">
                        <label for="optionD"><span class="opt-letter">D</span> Option D *</label>
                        <input type="text" name="optionD" id="optionD" class="form-control" required placeholder="Option D content">
                    </div>

                    <div class="form-group">
                        <label for="correctOption"><i class="fa-solid fa-check-circle" style="color:#10b981;"></i> Correct Answer Option *</label>
                        <select name="correctOption" id="correctOption" class="form-control" required>
                            <option value="">-- Choose Correct Option --</option>
                            <option value="A">Option A</option>
                            <option value="B">Option B</option>
                            <option value="C">Option C</option>
                            <option value="D">Option D</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="points"><i class="fa-solid fa-star" style="color:#f59e0b;"></i> Question Points</label>
                        <input type="number" step="0.5" min="0.5" name="points" id="points" value="1.0" class="form-control" required>
                    </div>
                </div>

                <div style="margin-top:16px;display:flex;justify-content:flex-end;">
                    <button type="submit" class="btn-action">
                        <i class="fa-solid fa-plus"></i> Save Question
                    </button>
                </div>
            </form>
        </div>
    <% } %>

    <!-- Questions List Panel -->
    <div class="card-panel">
        <div class="panel-head">
            <h2><i class="fa-solid fa-list-ol" style="color:#7c3aed;"></i> Quiz Questions (<%= questionCount %>)</h2>
            <span style="font-size:13px;color:#737373;">Total quiz weight: <%= totalPoints %> points</span>
        </div>

        <% if (questions != null && !questions.isEmpty()) { 
            int idx = 1;
            for (ExamMcqQuestion q : questions) { 
                String correct = q.getCorrectOption() != null ? q.getCorrectOption().toUpperCase() : "A";
        %>
            <div class="q-card">
                <div class="q-head">
                    <div style="display:flex;align-items:flex-start;gap:10px;flex:1;">
                        <span class="q-number"><%= idx++ %></span>
                        <div style="flex:1;">
                            <div class="q-text"><%= h(q.getQuestionText()) %></div>
                            <span class="meta-pill" style="margin-top:6px;font-size:11.5px;">
                                <i class="fa-solid fa-star" style="color:#f59e0b;"></i> <%= q.getPoints() %> Points
                            </span>
                        </div>
                    </div>
                    <div>
                        <% if (!isCompleted) { %>
                            <form action="<%= contextPath %>/tutor/mcq" method="post" style="display:inline;"
                                  onsubmit="return confirm('Are you sure you want to delete this question?');">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="examId" value="<%= exam.getExamId() %>">
                                <input type="hidden" name="questionId" value="<%= q.getQuestionId() %>">
                                <button type="submit" class="btn-delete-q">
                                    <i class="fa-solid fa-trash-can"></i> Delete
                                </button>
                            </form>
                        <% } else { %>
                            <span style="font-size:12px;color:#9ca3af;font-weight:600;"><i class="fa-solid fa-lock"></i> Locked</span>
                        <% } %>
                    </div>
                </div>

                <div class="q-options-grid">
                    <div class="q-opt-box <%= "A".equals(correct) ? "is-correct" : "" %>">
                        <span class="opt-letter">A</span>
                        <span><%= h(q.getOptionA()) %></span>
                        <% if ("A".equals(correct)) { %><i class="fa-solid fa-circle-check" style="margin-left:auto;color:#10b981;"></i><% } %>
                    </div>
                    <div class="q-opt-box <%= "B".equals(correct) ? "is-correct" : "" %>">
                        <span class="opt-letter">B</span>
                        <span><%= h(q.getOptionB()) %></span>
                        <% if ("B".equals(correct)) { %><i class="fa-solid fa-circle-check" style="margin-left:auto;color:#10b981;"></i><% } %>
                    </div>
                    <div class="q-opt-box <%= "C".equals(correct) ? "is-correct" : "" %>">
                        <span class="opt-letter">C</span>
                        <span><%= h(q.getOptionC()) %></span>
                        <% if ("C".equals(correct)) { %><i class="fa-solid fa-circle-check" style="margin-left:auto;color:#10b981;"></i><% } %>
                    </div>
                    <div class="q-opt-box <%= "D".equals(correct) ? "is-correct" : "" %>">
                        <span class="opt-letter">D</span>
                        <span><%= h(q.getOptionD()) %></span>
                        <% if ("D".equals(correct)) { %><i class="fa-solid fa-circle-check" style="margin-left:auto;color:#10b981;"></i><% } %>
                    </div>
                </div>
            </div>
        <%  } 
        } else { %>
            <div class="empty-box">
                <i class="fa-solid fa-clipboard-question" style="font-size:36px;color:#d1d5db;margin-bottom:12px;display:block;"></i>
                <h3 style="font-size:16px;font-weight:600;color:#374151;margin:0 0 6px 0;">No MCQ questions added yet</h3>
                <p style="font-size:13.5px;color:#6b7280;margin:0;">Use the form above to add questions. When students take the quiz, you can review their answers and publish marks from the Student Marks Sheet.</p>
            </div>
        <% } %>
    </div>

    <!-- Student Quiz Submissions Panel -->
    <div class="card-panel">
        <div class="panel-head">
            <div>
                <h2><i class="fa-solid fa-user-graduate" style="color:#7c3aed;"></i> Student Submissions (<%= submissionCount %>)</h2>
                <div style="font-size:13px;color:#737373;margin-top:2px;">Submitted student quizzes awaiting tutor review and mark release.</div>
            </div>
            <a href="<%= contextPath %>/tutor/marks?examId=<%= exam.getExamId() %>" class="btn-action sm" style="font-size:12.5px;padding:7px 14px;text-decoration:none;">
                <i class="fa-solid fa-arrow-up-right-from-square"></i> Open Marks Sheet
            </a>
        </div>

        <% if (submissions != null && !submissions.isEmpty()) { %>
            <div style="overflow-x:auto;">
                <table class="sub-table">
                    <thead>
                        <tr>
                            <th>Student</th>
                            <th>Questions Correct</th>
                            <th>Earned Points</th>
                            <th>Suggested Marks</th>
                            <th>Submitted At</th>
                            <th>Status</th>
                            <th style="text-align:right;">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (ExamMcqSubmission s : submissions) { 
                            boolean isPending = !"REVIEWED".equalsIgnoreCase(s.getStatus());
                        %>
                        <tr>
                            <td style="font-weight:600;"><%= h(s.getStudentName()) %></td>
                            <td><%= s.getCorrectAnswers() %> / <%= s.getTotalQuestions() %></td>
                            <td><%= s.getScoreObtained() %> / <%= s.getMaxPossible() %></td>
                            <td style="font-weight:700;color:#7c3aed;"><%= s.getScaledMarks() %> / <%= exam.getMaxMarks() %></td>
                            <td style="font-size:12.5px;color:#6b7280;"><%= s.getSubmittedAt() != null ? s.getSubmittedAt().toString().substring(0, 16) : "-" %></td>
                            <td>
                                <% if (isPending) { %>
                                    <span class="badge-pending"><i class="fa-solid fa-clock"></i> Pending Review</span>
                                <% } else { %>
                                    <span class="badge-reviewed"><i class="fa-solid fa-circle-check"></i> Marks Released</span>
                                <% } %>
                            </td>
                            <td style="text-align:right;">
                                <a href="<%= contextPath %>/tutor/marks?examId=<%= exam.getExamId() %>" class="btn-action sm" style="font-size:12px;padding:6px 12px;text-decoration:none;">
                                    <i class="fa-solid fa-clipboard-check"></i> Review &amp; Release
                                </a>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        <% } else { %>
            <div class="empty-box" style="padding:24px 20px;">
                <i class="fa-solid fa-inbox" style="font-size:32px;color:#d1d5db;margin-bottom:8px;display:block;"></i>
                <p style="margin:0;font-size:13.5px;color:#6b7280;">No students have submitted this quiz yet.</p>
            </div>
        <% } %>
    </div>

    <% } %>
</main>

</body>
</html>
