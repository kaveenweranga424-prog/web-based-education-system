package servlet;

import dao.ClassDAO;
import model.Class;
import model.Exam;
import model.ExamMcqQuestion;
import model.ExamMcqSubmission;
import service.ExamMcqService;
import service.ExamService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;

@WebServlet("/tutor/mcq")
public class TutorMcqServlet extends HttpServlet {

    private ExamService examService;
    private ExamMcqService examMcqService;
    private ClassDAO classDAO;

    @Override
    public void init() {
        examService = new ExamService();
        examMcqService = new ExamMcqService();
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

            List<ExamMcqQuestion> questions = examMcqService.getQuestions(examId);
            List<ExamMcqSubmission> submissions = examMcqService.getSubmissionsByExam(examId);

            request.setAttribute("exam", exam);
            request.setAttribute("questions", questions);
            request.setAttribute("submissions", submissions);

            request.getRequestDispatcher("/tutor/manage-mcq.jsp").forward(request, response);

        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/tutor/exams");
        }
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

        try {
            int examId = Integer.parseInt(request.getParameter("examId"));
            Exam exam = examService.findById(examId);

            if (exam == null || !canManageExam(session, exam)) {
                response.sendRedirect(request.getContextPath() + "/tutor/exams");
                return;
            }

            if ("COMPLETED".equalsIgnoreCase(exam.getStatus()) || "CANCELLED".equalsIgnoreCase(exam.getStatus())) {
                session.setAttribute("flashError", "This quiz is already completed or cancelled. Questions cannot be modified.");
                response.sendRedirect(request.getContextPath() + "/tutor/mcq?examId=" + examId);
                return;
            }

            String action = request.getParameter("action");

            if ("delete".equalsIgnoreCase(action)) {
                int questionId = Integer.parseInt(request.getParameter("questionId"));
                examMcqService.deleteQuestion(questionId, examId);
                session.setAttribute("flashSuccess", "Question deleted successfully.");
            } else if ("add".equalsIgnoreCase(action)) {
                String questionText = request.getParameter("questionText");
                String optionA = request.getParameter("optionA");
                String optionB = request.getParameter("optionB");
                String optionC = request.getParameter("optionC");
                String optionD = request.getParameter("optionD");
                String correctOption = request.getParameter("correctOption");
                String rawPoints = request.getParameter("points");

                BigDecimal points = BigDecimal.ONE;
                if (rawPoints != null && !rawPoints.isBlank()) {
                    try {
                        points = new BigDecimal(rawPoints.trim());
                    } catch (NumberFormatException ignored) {}
                }

                String error = examMcqService.addQuestion(
                        examId, questionText, optionA, optionB, optionC, optionD, correctOption, points
                );

                if (error != null) {
                    session.setAttribute("flashError", error);
                } else {
                    session.setAttribute("flashSuccess", "Question added successfully.");
                }
            }

            response.sendRedirect(request.getContextPath() + "/tutor/mcq?examId=" + examId);

        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
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
