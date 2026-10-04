<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Exam" %>
<%@ page import="model.ExamMcqQuestion" %>
<%@ page import="model.ExamMcqSubmission" %>
<%@ page import="model.ExamResult" %>
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
    Exam exam = (Exam) request.getAttribute("exam");
    List<ExamMcqQuestion> questions = (List<ExamMcqQuestion>) request.getAttribute("questions");
    Boolean hasAttemptedObj = (Boolean) request.getAttribute("hasAttempted");
    boolean hasAttempted = Boolean.TRUE.equals(hasAttemptedObj);
    Boolean isPendingReviewObj = (Boolean) request.getAttribute("isPendingReview");
    boolean isPendingReview = Boolean.TRUE.equals(isPendingReviewObj);

    ExamMcqSubmission submission = (ExamMcqSubmission) request.getAttribute("submission");
    Map<Integer, String> studentAnswers = (Map<Integer, String>) request.getAttribute("studentAnswers");
    ExamResult examResult = (ExamResult) request.getAttribute("examResult");

    String flashSuccess = (String) session.getAttribute("flashSuccess");
    if (flashSuccess != null) {
        session.removeAttribute("flashSuccess");
    }
    String flashError = (String) session.getAttribute("flashError");
    if (flashError != null) {
        session.removeAttribute("flashError");
    }

    int qCount = questions != null ? questions.size() : 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= exam != null ? h(exam.getExamName()) : "MCQ Quiz" %> | Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/class-pages.css">
    <style>
        .quiz-shell { max-width: 900px; margin: 32px auto; padding: 0 20px; }
        .quiz-header { margin-bottom: 24px; }
        .card-panel { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; padding: 26px; box-shadow: 0 2px 8px rgba(0,0,0,.04); margin-bottom: 24px; }
        .meta-pill { display: inline-flex; align-items: center; gap: 6px; background: #f3f4f6; color: #4b5563; padding: 5px 12px; border-radius: 8px; font-size: 13px; font-weight: 500; }
        .meta-pill-highlight { background: #ede9fe; color: #6d28d9; font-weight: 600; }
        .alert-success { background: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0; padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        .alert-error { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        
        /* Score Hero (When tutor has published marks) */
        .score-hero { background: linear-gradient(135deg, #7c3aed 0%, #4f46e5 100%); color: #fff; border-radius: 16px; padding: 32px; margin-bottom: 28px; text-align: center; }
        .score-val { font-size: 44px; font-weight: 800; font-family: 'Plus Jakarta Sans', sans-serif; margin: 12px 0 6px 0; }
        .score-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 12px; margin-top: 20px; }
        .score-subcard { background: rgba(255,255,255,0.15); border-radius: 10px; padding: 12px; backdrop-filter: blur(4px); }
        .score-sublabel { font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.85; }
        .score-subvalue { font-size: 20px; font-weight: 700; margin-top: 4px; }
        
        /* Pending Review Hero */
        .pending-hero { background: linear-gradient(135deg, #1e293b 0%, #334155 100%); color: #fff; border-radius: 16px; padding: 32px; margin-bottom: 28px; text-align: center; border: 1px solid #475569; }
        .pending-title { font-size: 24px; font-weight: 800; font-family: 'Plus Jakarta Sans', sans-serif; margin: 12px 0 8px 0; }
        .pending-desc { font-size: 14px; color: #cbd5e1; max-width: 620px; margin: 0 auto; line-height: 1.6; }

        .q-card { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 22px; margin-bottom: 18px; box-shadow: 0 1px 4px rgba(0,0,0,.03); transition: border-color 0.15s ease; }
        .q-card:focus-within { border-color: #7c3aed; }
        .q-head { display: flex; align-items: flex-start; gap: 12px; margin-bottom: 16px; }
        .q-num { background: #7c3aed; color: #fff; width: 28px; height: 28px; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 13.5px; font-weight: 700; flex-shrink: 0; }
        .q-title { font-size: 15.5px; font-weight: 600; color: #111827; flex: 1; line-height: 1.45; }
        .opt-list { display: flex; flex-direction: column; gap: 10px; }
        .opt-item { display: flex; align-items: center; padding: 12px 16px; border: 1.5px solid #e5e7eb; border-radius: 10px; cursor: pointer; transition: all 0.15s ease; font-size: 14px; user-select: none; }
        .opt-item:hover { border-color: #c4b5fd; background: #faf5ff; }
        .opt-item input[type="radio"] { margin-right: 12px; accent-color: #7c3aed; transform: scale(1.2); }
        .opt-item.selected { border-color: #7c3aed; background: #f5f3ff; font-weight: 600; }
        
        /* Review styles when marks released */
        .opt-item.rev-correct { border-color: #10b981; background: #ecfdf5; color: #065f46; font-weight: 600; }
        .opt-item.rev-wrong { border-color: #ef4444; background: #fef2f2; color: #991b1b; }
        .badge-rev { margin-left: auto; font-size: 12px; font-weight: 700; display: inline-flex; align-items: center; gap: 4px; padding: 3px 9px; border-radius: 6px; }
        .badge-rev-correct { background: #d1fae5; color: #047857; }
        .badge-rev-wrong { background: #fee2e2; color: #b91c1c; }
        
        /* Neutral styles for pending review */
        .opt-item.rev-neutral { border-color: #6366f1; background: #f5f3ff; color: #4338ca; font-weight: 600; }
        .badge-rev-neutral { background: #e0e7ff; color: #3730a3; }

        .btn-submit-quiz { background: #7c3aed; color: #fff; border: none; padding: 14px 32px; border-radius: 10px; font-size: 15px; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; box-shadow: 0 4px 12px rgba(124,58,237,0.3); transition: all 0.15s ease; }
        .btn-submit-quiz:hover { background: #6d28d9; transform: translateY(-1px); }
        .btn-back { background: #f3f4f6; color: #374151; border: 1px solid #d1d5db; padding: 10px 18px; border-radius: 8px; font-weight: 600; font-size: 13.5px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; }
        .btn-back:hover { background: #e5e7eb; }
    </style>
</head>
<body class="dash-body">

<header class="class-page-header">
    <a class="class-brand" href="<%= contextPath %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle">Online Assessment</span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= contextPath %>/dashboard"><i class="fa-solid fa-gauge"></i> Student Dashboard</a>
        <a class="class-nav-link" href="<%= contextPath %>/results"><i class="fa-solid fa-award"></i> My Results</a>
    </div>
</header>

<main class="quiz-shell">
    <% if (flashSuccess != null && !flashSuccess.isEmpty()) { %>
        <div class="alert-success">
            <i class="fa-solid fa-circle-check" style="font-size:18px;"></i>
            <span><%= h(flashSuccess) %></span>
        </div>
    <% } %>

    <% if (flashError != null && !flashError.isEmpty()) { %>
        <div class="alert-error">
            <i class="fa-solid fa-circle-exclamation" style="font-size:18px;"></i>
            <span><%= h(flashError) %></span>
        </div>
    <% } %>

    <% if (exam != null) { %>
        <div class="quiz-header">
            <h1 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:26px;font-weight:800;margin:0 0 10px 0;color:#111827;">
                <%= h(exam.getExamName()) %>
            </h1>
            <div style="display:flex;gap:10px;flex-wrap:wrap;">
                <span class="meta-pill"><i class="fa-solid fa-book"></i> <%= h(exam.getSubject()) %> (<%= h(exam.getBatch()) %>)</span>
                <span class="meta-pill"><i class="fa-solid fa-star"></i> Max Marks: <%= exam.getMaxMarks() %></span>
                <span class="meta-pill meta-pill-highlight"><i class="fa-solid fa-circle-question"></i> <%= qCount %> Questions</span>
                <% if (hasAttempted) { 
                    if (isPendingReview) { %>
                        <span class="meta-pill" style="background:#fef3c7;color:#92400e;font-weight:700;"><i class="fa-solid fa-clock"></i> Submitted (Pending Tutor Review)</span>
                    <% } else { %>
                        <span class="meta-pill" style="background:#dcfce7;color:#15803d;font-weight:700;"><i class="fa-solid fa-check-circle"></i> Marks Released</span>
                    <% } 
                } else { %>
                    <span class="meta-pill" style="background:#fef3c7;color:#92400e;font-weight:700;"><i class="fa-solid fa-clock"></i> Not Submitted</span>
                <% } %>
            </div>
        </div>

        <%-- SCENARIO 1: ATTEMPTED BUT PENDING TUTOR REVIEW --%>
        <% if (hasAttempted && isPendingReview && submission != null) { %>
            <div class="pending-hero">
                <i class="fa-solid fa-hourglass-half" style="font-size:42px;color:#fde047;opacity:0.95;"></i>
                <div class="pending-title">Quiz Submitted — Awaiting Tutor Review</div>
                <div class="pending-desc">
                    Your answers have been submitted successfully! Your tutor is currently reviewing student submissions. Once your tutor finalizes and releases the marks, your score, grade, and full answer corrections will appear here.
                </div>

                <div class="score-grid" style="max-width:650px;margin:24px auto 0 auto;">
                    <div class="score-subcard">
                        <div class="score-sublabel">Submitted At</div>
                        <div class="score-subvalue" style="font-size:15px;">
                            <%= submission.getSubmittedAt() != null ? submission.getSubmittedAt().toString().substring(0, 16) : "-" %>
                        </div>
                    </div>
                    <div class="score-subcard">
                        <div class="score-sublabel">Questions Answered</div>
                        <div class="score-subvalue"><%= studentAnswers != null ? studentAnswers.size() : 0 %> / <%= submission.getTotalQuestions() %></div>
                    </div>
                    <div class="score-subcard">
                        <div class="score-sublabel">Status</div>
                        <div class="score-subvalue" style="font-size:16px;color:#fde047;">Pending Review</div>
                    </div>
                </div>
            </div>

            <div class="card-panel">
                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:18px;">
                    <h2 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:18px;font-weight:700;margin:0;">
                        <i class="fa-solid fa-list-check" style="color:#7c3aed;"></i> Your Submitted Responses
                    </h2>
                    <a href="<%= contextPath %>/dashboard" class="btn-back"><i class="fa-solid fa-arrow-left"></i> Dashboard</a>
                </div>

                <div style="background:#f8fafc;border:1px solid #e2e8f0;padding:14px 18px;border-radius:12px;margin-bottom:20px;font-size:13.5px;color:#475569;display:flex;align-items:center;gap:10px;">
                    <i class="fa-solid fa-shield-halved" style="color:#6366f1;font-size:18px;"></i>
                    <span><strong>Note:</strong> Right/wrong evaluation and correct answer keys are hidden until your tutor reviews and updates the marks.</span>
                </div>

                <% if (questions != null) {
                    int i = 1;
                    for (ExamMcqQuestion q : questions) {
                        String studentChoice = studentAnswers != null ? studentAnswers.get(q.getQuestionId()) : null;
                %>
                    <div class="q-card" style="background:#fafafa;">
                        <div class="q-head">
                            <span class="q-num"><%= i++ %></span>
                            <div class="q-title"><%= h(q.getQuestionText()) %></div>
                            <span class="meta-pill" style="font-size:12px;"><i class="fa-solid fa-star" style="color:#f59e0b;"></i> <%= q.getPoints() %> pt</span>
                        </div>

                        <div class="opt-list">
                            <div class="opt-item <%= "A".equalsIgnoreCase(studentChoice) ? "rev-neutral" : "" %>" style="cursor:default;">
                                <strong>A.</strong>&nbsp; <%= h(q.getOptionA()) %>
                                <% if ("A".equalsIgnoreCase(studentChoice)) { %>
                                    <span class="badge-rev badge-rev-neutral"><i class="fa-solid fa-check"></i> Your Response</span>
                                <% } %>
                            </div>
                            <div class="opt-item <%= "B".equalsIgnoreCase(studentChoice) ? "rev-neutral" : "" %>" style="cursor:default;">
                                <strong>B.</strong>&nbsp; <%= h(q.getOptionB()) %>
                                <% if ("B".equalsIgnoreCase(studentChoice)) { %>
                                    <span class="badge-rev badge-rev-neutral"><i class="fa-solid fa-check"></i> Your Response</span>
                                <% } %>
                            </div>
                            <div class="opt-item <%= "C".equalsIgnoreCase(studentChoice) ? "rev-neutral" : "" %>" style="cursor:default;">
                                <strong>C.</strong>&nbsp; <%= h(q.getOptionC()) %>
                                <% if ("C".equalsIgnoreCase(studentChoice)) { %>
                                    <span class="badge-rev badge-rev-neutral"><i class="fa-solid fa-check"></i> Your Response</span>
                                <% } %>
                            </div>
                            <div class="opt-item <%= "D".equalsIgnoreCase(studentChoice) ? "rev-neutral" : "" %>" style="cursor:default;">
                                <strong>D.</strong>&nbsp; <%= h(q.getOptionD()) %>
                                <% if ("D".equalsIgnoreCase(studentChoice)) { %>
                                    <span class="badge-rev badge-rev-neutral"><i class="fa-solid fa-check"></i> Your Response</span>
                                <% } %>
                            </div>
                        </div>
                    </div>
                <%  } 
                } %>

                <div style="text-align:center;margin-top:24px;">
                    <a href="<%= contextPath %>/dashboard" class="btn-back" style="font-size:14px;padding:12px 24px;">
                        <i class="fa-solid fa-arrow-left"></i> Return to Dashboard
                    </a>
                </div>
            </div>

        <%-- SCENARIO 2: TUTOR HAS REVIEWED AND PUBLISHED MARKS --%>
        <% } else if (hasAttempted && !isPendingReview && submission != null) { 
            BigDecimal marksObtained = examResult != null && examResult.getMarksObtained() != null 
                    ? examResult.getMarksObtained() : BigDecimal.ZERO;
            String grade = examResult != null && examResult.getGrade() != null ? examResult.getGrade() : "-";
            double pct = submission.getMaxPossible() != null && submission.getMaxPossible().doubleValue() > 0 
                    ? (submission.getScoreObtained().doubleValue() * 100.0 / submission.getMaxPossible().doubleValue()) : 0.0;
        %>
            <div class="score-hero">
                <i class="fa-solid fa-award" style="font-size:40px;opacity:0.9;"></i>
                <div class="score-val"><%= marksObtained %> <span style="font-size:24px;opacity:0.8;">/ <%= exam.getMaxMarks() %></span></div>
                <div style="font-size:15px;opacity:0.95;font-weight:500;">Official Exam Grade: <strong><%= grade %></strong></div>
                <% if (examResult != null && examResult.getRemarks() != null && !examResult.getRemarks().isBlank()) { %>
                    <div style="font-size:13.5px;opacity:0.85;margin-top:6px;font-style:italic;">"<%= h(examResult.getRemarks()) %>"</div>
                <% } %>

                <div class="score-grid">
                    <div class="score-subcard">
                        <div class="score-sublabel">Questions Correct</div>
                        <div class="score-subvalue"><%= submission.getCorrectAnswers() %> / <%= submission.getTotalQuestions() %></div>
                    </div>
                    <div class="score-subcard">
                        <div class="score-sublabel">Accuracy</div>
                        <div class="score-subvalue"><%= String.format("%.1f%%", pct) %></div>
                    </div>
                    <div class="score-subcard">
                        <div class="score-sublabel">Earned Points</div>
                        <div class="score-subvalue"><%= submission.getScoreObtained() %> / <%= submission.getMaxPossible() %></div>
                    </div>
                    <div class="score-subcard">
                        <div class="score-sublabel">Submitted At</div>
                        <div class="score-subvalue" style="font-size:14px;"><%= submission.getSubmittedAt() != null ? submission.getSubmittedAt().toString().substring(0, 16) : "" %></div>
                    </div>
                </div>
            </div>

            <div class="card-panel">
                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:18px;">
                    <h2 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:18px;font-weight:700;margin:0;">
                        <i class="fa-solid fa-clipboard-check" style="color:#7c3aed;"></i> Quiz Answers Review
                    </h2>
                    <a href="<%= contextPath %>/dashboard" class="btn-back"><i class="fa-solid fa-arrow-left"></i> Dashboard</a>
                </div>

                <% if (questions != null) {
                    int i = 1;
                    for (ExamMcqQuestion q : questions) {
                        String studentChoice = studentAnswers != null ? studentAnswers.get(q.getQuestionId()) : null;
                        String correct = q.getCorrectOption() != null ? q.getCorrectOption().toUpperCase() : "";
                        boolean isCorrect = studentChoice != null && studentChoice.equalsIgnoreCase(correct);
                %>
                    <div class="q-card" style="background:#fafafa;">
                        <div class="q-head">
                            <span class="q-num"><%= i++ %></span>
                            <div class="q-title"><%= h(q.getQuestionText()) %></div>
                            <div>
                                <% if (isCorrect) { %>
                                    <span class="badge-rev badge-rev-correct"><i class="fa-solid fa-check"></i> Correct (+<%= q.getPoints() %>)</span>
                                <% } else { %>
                                    <span class="badge-rev badge-rev-wrong"><i class="fa-solid fa-xmark"></i> Incorrect (0/<%= q.getPoints() %>)</span>
                                <% } %>
                            </div>
                        </div>

                        <div class="opt-list">
                            <div class="opt-item <%= "A".equals(correct) ? "rev-correct" : ("A".equals(studentChoice) ? "rev-wrong" : "") %>" style="cursor:default;">
                                <strong>A.</strong>&nbsp; <%= h(q.getOptionA()) %>
                                <% if ("A".equals(correct)) { %><span class="badge-rev badge-rev-correct">Correct Answer</span><% } %>
                                <% if ("A".equals(studentChoice) && !"A".equals(correct)) { %><span class="badge-rev badge-rev-wrong">Your Answer</span><% } %>
                            </div>
                            <div class="opt-item <%= "B".equals(correct) ? "rev-correct" : ("B".equals(studentChoice) ? "rev-wrong" : "") %>" style="cursor:default;">
                                <strong>B.</strong>&nbsp; <%= h(q.getOptionB()) %>
                                <% if ("B".equals(correct)) { %><span class="badge-rev badge-rev-correct">Correct Answer</span><% } %>
                                <% if ("B".equals(studentChoice) && !"B".equals(correct)) { %><span class="badge-rev badge-rev-wrong">Your Answer</span><% } %>
                            </div>
                            <div class="opt-item <%= "C".equals(correct) ? "rev-correct" : ("C".equals(studentChoice) ? "rev-wrong" : "") %>" style="cursor:default;">
                                <strong>C.</strong>&nbsp; <%= h(q.getOptionC()) %>
                                <% if ("C".equals(correct)) { %><span class="badge-rev badge-rev-correct">Correct Answer</span><% } %>
                                <% if ("C".equals(studentChoice) && !"C".equals(correct)) { %><span class="badge-rev badge-rev-wrong">Your Answer</span><% } %>
                            </div>
                            <div class="opt-item <%= "D".equals(correct) ? "rev-correct" : ("D".equals(studentChoice) ? "rev-wrong" : "") %>" style="cursor:default;">
                                <strong>D.</strong>&nbsp; <%= h(q.getOptionD()) %>
                                <% if ("D".equals(correct)) { %><span class="badge-rev badge-rev-correct">Correct Answer</span><% } %>
                                <% if ("D".equals(studentChoice) && !"D".equals(correct)) { %><span class="badge-rev badge-rev-wrong">Your Answer</span><% } %>
                            </div>
                        </div>
                    </div>
                <%  } 
                } %>

                <div style="text-align:center;margin-top:24px;">
                    <a href="<%= contextPath %>/dashboard" class="btn-back" style="font-size:14px;padding:12px 24px;">
                        <i class="fa-solid fa-arrow-left"></i> Return to Dashboard
                    </a>
                </div>
            </div>

        <%-- SCENARIO 3: EXAM COMPLETED BUT NOT ATTEMPTED --%>
        <% } else if (exam != null && "COMPLETED".equalsIgnoreCase(exam.getStatus())) { %>
            <div class="card-panel" style="text-align:center;padding:48px 20px;">
                <i class="fa-solid fa-lock" style="font-size:42px;color:#9ca3af;margin-bottom:14px;display:block;"></i>
                <h2 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:20px;font-weight:700;margin:0 0 8px 0;color:#1f2937;">
                    Quiz Concluded &amp; Closed
                </h2>
                <p style="font-size:14px;color:#6b7280;max-width:480px;margin:0 auto 20px auto;">
                    This quiz process has been completed and finalized by your tutor. Submissions are now closed.
                </p>
                <a href="<%= contextPath %>/dashboard" class="btn-back">
                    <i class="fa-solid fa-arrow-left"></i> Back to Dashboard
                </a>
            </div>

        <%-- SCENARIO 4: QUIZ TAKING FORM --%>
        <% } else if (questions != null && !questions.isEmpty()) { %>
            <div class="card-panel" style="background:#fefce8;border-color:#fde047;padding:16px 20px;margin-bottom:20px;">
                <div style="display:flex;align-items:center;gap:12px;color:#854d0e;font-size:14px;">
                    <i class="fa-solid fa-circle-info" style="font-size:18px;"></i>
                    <div>
                        <strong>Instructions:</strong> Please answer all questions carefully. Once you click "Submit Quiz for Review", your answers will be sent to your tutor for review. Your final marks will be available after your tutor publishes them.
                    </div>
                </div>
            </div>

            <form action="<%= contextPath %>/student/quiz" method="post" id="quizForm"
                  onsubmit="return confirm('Are you sure you want to submit your quiz? You will not be able to change your answers.');">
                <input type="hidden" name="examId" value="<%= exam.getExamId() %>">

                <% int num = 1;
                for (ExamMcqQuestion q : questions) { %>
                    <div class="q-card">
                        <div class="q-head">
                            <span class="q-num"><%= num++ %></span>
                            <div class="q-title"><%= h(q.getQuestionText()) %></div>
                            <span class="meta-pill" style="font-size:12px;"><i class="fa-solid fa-star" style="color:#f59e0b;"></i> <%= q.getPoints() %> pt</span>
                        </div>

                        <div class="opt-list">
                            <label class="opt-item" onclick="selectOption(this)">
                                <input type="radio" name="q_<%= q.getQuestionId() %>" value="A">
                                <strong>A.</strong>&nbsp; <%= h(q.getOptionA()) %>
                            </label>
                            <label class="opt-item" onclick="selectOption(this)">
                                <input type="radio" name="q_<%= q.getQuestionId() %>" value="B">
                                <strong>B.</strong>&nbsp; <%= h(q.getOptionB()) %>
                            </label>
                            <label class="opt-item" onclick="selectOption(this)">
                                <input type="radio" name="q_<%= q.getQuestionId() %>" value="C">
                                <strong>C.</strong>&nbsp; <%= h(q.getOptionC()) %>
                            </label>
                            <label class="opt-item" onclick="selectOption(this)">
                                <input type="radio" name="q_<%= q.getQuestionId() %>" value="D">
                                <strong>D.</strong>&nbsp; <%= h(q.getOptionD()) %>
                            </label>
                        </div>
                    </div>
                <% } %>

                <div style="margin-top:28px;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:16px;">
                    <a href="<%= contextPath %>/dashboard" class="btn-back">
                        <i class="fa-solid fa-arrow-left"></i> Cancel
                    </a>
                    <button type="submit" class="btn-submit-quiz">
                        <i class="fa-solid fa-paper-plane"></i> Submit Quiz for Review
                    </button>
                </div>
            </form>

        <% } else { %>
            <div class="card-panel" style="text-align:center;padding:48px 20px;">
                <i class="fa-solid fa-hourglass-half" style="font-size:42px;color:#d1d5db;margin-bottom:14px;display:block;"></i>
                <h2 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:20px;font-weight:700;margin:0 0 8px 0;color:#1f2937;">
                    Quiz Questions Pending
                </h2>
                <p style="font-size:14px;color:#6b7280;max-width:480px;margin:0 auto 20px auto;">
                    Your tutor has scheduled this exam, but MCQ questions have not been added yet. Please check back soon or consult your tutor.
                </p>
                <a href="<%= contextPath %>/dashboard" class="btn-back">
                    <i class="fa-solid fa-arrow-left"></i> Back to Dashboard
                </a>
            </div>
        <% } %>

    <% } else { %>
        <div class="card-panel">
            <p>Exam not found.</p>
            <a href="<%= contextPath %>/dashboard" class="btn-back">Back to Dashboard</a>
        </div>
    <% } %>
</main>

<script>
    function selectOption(labelEl) {
        const parent = labelEl.closest('.opt-list');
        if (parent) {
            parent.querySelectorAll('.opt-item').forEach(el => el.classList.remove('selected'));
            labelEl.classList.add('selected');
        }
    }
</script>

</body>
</html>
