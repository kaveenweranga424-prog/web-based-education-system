package servlet;

import dao.ClassDAO;
import dao.ExamMcqDAO;
import model.Class;
import model.Exam;
import model.ExamMcqReviewItem;
import model.ExamMcqSubmission;
import model.ExamResult;
import service.ExamMcqService;
import service.ExamService;
import service.ResultService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * Tutor (own class's exam) or Admin: enters/corrects marks, reviews quiz submissions, and views the result sheet.
 */
@WebServlet("/tutor/marks")
public class MarksServlet extends HttpServlet {

    private ResultService resultService;
    private ExamService examService;
    private ExamMcqService examMcqService;
    private ExamMcqDAO examMcqDAO;
    private ClassDAO classDAO;

    @Override
    public void init() {
        resultService = new ResultService();
        examService = new ExamService();
        examMcqService = new ExamMcqService();
        examMcqDAO = new ExamMcqDAO();
        classDAO = new ClassDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || !canAccess(session)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        try {
            int examId = Integer.parseInt(request.getParameter("examId"));
            Exam exam = examService.findById(examId);

            if (exam == null || !canManageExam(session, exam)) {
                response.sendRedirect(request.getContextPath() + "/tutor/exams");
                return;
            }

            String action = request.getParameter("action");
            if ("getReviewJson".equalsIgnoreCase(action)) {
                sendReviewJson(request, response, exam);
                return;
            }

            List<ExamResult> roster = resultService.getRoster(examId);
            Map<Integer, ExamMcqSubmission> mcqSubmissions = examMcqService.getSubmissionsMapByExam(examId);

            request.setAttribute("exam", exam);
            request.setAttribute("roster", roster);
            request.setAttribute("mcqSubmissions", mcqSubmissions);

            request.getRequestDispatcher("/tutor/enter-marks.jsp").forward(request, response);

        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/tutor/exams");
        }
    }

    private void sendReviewJson(HttpServletRequest request, HttpServletResponse response, Exam exam)
            throws IOException, SQLException {
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();

        int studentId = Integer.parseInt(request.getParameter("studentId"));
        ExamMcqSubmission sub = examMcqService.getSubmission(exam.getExamId(), studentId);
        List<ExamMcqReviewItem> items = examMcqService.getSubmissionReview(exam.getExamId(), studentId);

        if (sub == null) {
            out.write("{\"error\":\"No submission found for this student.\"}");
            return;
        }

        // Compute scaled marks
        BigDecimal scaledMarks = BigDecimal.ZERO;
        if (sub.getMaxPossible() != null && sub.getMaxPossible().compareTo(BigDecimal.ZERO) > 0 && exam.getMaxMarks() != null) {
            scaledMarks = sub.getScoreObtained()
                    .divide(sub.getMaxPossible(), 4, java.math.RoundingMode.HALF_UP)
                    .multiply(exam.getMaxMarks())
                    .setScale(2, java.math.RoundingMode.HALF_UP);
        }

        StringBuilder sb = new StringBuilder();
        sb.append("{");
        sb.append("\"examId\":").append(exam.getExamId()).append(",");
        sb.append("\"studentId\":").append(studentId).append(",");
        sb.append("\"status\":\"").append(escapeJson(sub.getStatus())).append("\",");
        sb.append("\"totalQuestions\":").append(sub.getTotalQuestions()).append(",");
        sb.append("\"correctAnswers\":").append(sub.getCorrectAnswers()).append(",");
        sb.append("\"scoreObtained\":").append(sub.getScoreObtained()).append(",");
        sb.append("\"maxPossible\":").append(sub.getMaxPossible()).append(",");
        sb.append("\"suggestedMarks\":").append(scaledMarks).append(",");
        sb.append("\"submittedAt\":\"").append(sub.getSubmittedAt() != null ? sub.getSubmittedAt().toString().substring(0, 16) : "").append("\",");
        sb.append("\"items\":[");

        for (int i = 0; i < items.size(); i++) {
            ExamMcqReviewItem item = items.get(i);
            if (i > 0) sb.append(",");
            sb.append("{");
            sb.append("\"questionId\":").append(item.getQuestionId()).append(",");
            sb.append("\"questionText\":\"").append(escapeJson(item.getQuestionText())).append("\",");
            sb.append("\"optionA\":\"").append(escapeJson(item.getOptionA())).append("\",");
            sb.append("\"optionB\":\"").append(escapeJson(item.getOptionB())).append("\",");
            sb.append("\"optionC\":\"").append(escapeJson(item.getOptionC())).append("\",");
            sb.append("\"optionD\":\"").append(escapeJson(item.getOptionD())).append("\",");
            sb.append("\"correctOption\":\"").append(escapeJson(item.getCorrectOption())).append("\",");
            sb.append("\"selectedOption\":\"").append(escapeJson(item.getSelectedOption())).append("\",");
            sb.append("\"isCorrect\":").append(item.isCorrect()).append(",");
            sb.append("\"points\":").append(item.getPoints() != null ? item.getPoints() : BigDecimal.ONE);
            sb.append("}");
        }

        sb.append("]}");
        out.write(sb.toString());
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\b", "\\b")
                .replace("\f", "\\f")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || !canAccess(session)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        int userId = (int) session.getAttribute("userId");
        boolean isAdmin = "ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("userRole")));

        try {
            int examId = Integer.parseInt(request.getParameter("examId"));
            Exam exam = examService.findById(examId);

            if (exam == null || !canManageExam(session, exam)) {
                response.sendRedirect(request.getContextPath() + "/tutor/exams");
                return;
            }

            String action = request.getParameter("action");

            if ("delete".equals(action)) {
                int resultId = Integer.parseInt(request.getParameter("resultId"));
                String rawStudentId = request.getParameter("studentId");
                resultService.deleteResult(resultId);

                if (rawStudentId != null && !rawStudentId.isBlank()) {
                    int sId = Integer.parseInt(rawStudentId);
                    examMcqDAO.updateSubmissionStatus(examId, sId, "PENDING", userId);
                }

                session.setAttribute("flashSuccess", "Result cleared. Status reverted to pending.");
                response.sendRedirect(request.getContextPath() + "/tutor/marks?examId=" + examId);
                return;
            }

            // Single student save & publish from modal
            if ("saveSingle".equalsIgnoreCase(action)) {
                int studentId = Integer.parseInt(request.getParameter("studentId"));
                String rawMarks = request.getParameter("marksObtained");
                String remarks = request.getParameter("remarks");

                if (rawMarks != null && !rawMarks.isBlank()) {
                    BigDecimal marksObtained = new BigDecimal(rawMarks.trim());
                    String err = resultService.enterMarks(examId, studentId, marksObtained, remarks, userId, isAdmin);
                    if (err != null) {
                        session.setAttribute("flashError", err);
                    } else {
                        examMcqService.markSubmissionReviewed(examId, studentId, userId);
                        session.setAttribute("flashSuccess", "Marks saved and released to student successfully!");
                    }
                }
                response.sendRedirect(request.getContextPath() + "/tutor/marks?examId=" + examId);
                return;
            }

            // Bulk save from table
            String[] studentIds = request.getParameterValues("studentId");
            String[] marksArr = request.getParameterValues("marksObtained");
            String[] remarksArr = request.getParameterValues("remarks");

            String firstError = null;

            if (studentIds != null) {
                for (int i = 0; i < studentIds.length; i++) {
                    String rawMarks = marksArr[i];

                    if (rawMarks == null || rawMarks.isBlank()) {
                        continue; // skip students not yet marked
                    }

                    int studentId = Integer.parseInt(studentIds[i]);
                    BigDecimal marksObtained = new BigDecimal(rawMarks.trim());
                    String remarks = (remarksArr != null && i < remarksArr.length) ? remarksArr[i] : null;

                    String error = resultService.enterMarks(
                            examId, studentId, marksObtained, remarks, userId, isAdmin
                    );

                    if (error != null && firstError == null) {
                        firstError = error;
                    } else if (error == null) {
                        // Mark MCQ submission reviewed as tutor has approved and published the marks
                        examMcqService.markSubmissionReviewed(examId, studentId, userId);
                    }
                }
            }

            if (firstError != null) {
                session.setAttribute("flashError", firstError);
            } else {
                session.setAttribute("flashSuccess", "All entered marks have been saved and released to students!");
            }

            response.sendRedirect(request.getContextPath() + "/tutor/marks?examId=" + examId);

        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/tutor/exams");
        } catch (SQLException e) {
            e.printStackTrace();
            session.setAttribute("flashError", "Database error occurred. Please try again.");
            response.sendRedirect(request.getContextPath() + "/tutor/exams");
        }
    }

    private boolean canAccess(HttpSession session) {
        String role = String.valueOf(session.getAttribute("userRole"));
        return "TUTOR".equalsIgnoreCase(role) || "ADMIN".equalsIgnoreCase(role);
    }

    private boolean canManageExam(HttpSession session, Exam exam) throws SQLException {
        String role = String.valueOf(session.getAttribute("userRole"));

        if ("ADMIN".equalsIgnoreCase(role)) {
            return true;
        }

        int tutorId = (int) session.getAttribute("userId");
        Class classItem = classDAO.findById(exam.getClassId());

        return classItem != null && classItem.getTutorId() != null && classItem.getTutorId() == tutorId;
    }
}