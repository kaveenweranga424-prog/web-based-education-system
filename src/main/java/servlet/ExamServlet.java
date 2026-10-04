package servlet;

import model.Class;
import model.Exam;
import service.ClassService;
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
import java.sql.Date;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * Tutor (own classes) or Admin (any classItem): schedule and cancel exams.
 */
@WebServlet("/tutor/exams")
public class ExamServlet extends HttpServlet {

    private ExamService examService;
    private ClassService classService;
    private ExamMcqService examMcqService;

    @Override
    public void init() {
        examService = new ExamService();
        classService = new ClassService();
        examMcqService = new ExamMcqService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String role = String.valueOf(session.getAttribute("userRole"));

        if (!"TUTOR".equalsIgnoreCase(role) && !"ADMIN".equalsIgnoreCase(role)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int userId = (int) session.getAttribute("userId");
        boolean isAdmin = "ADMIN".equalsIgnoreCase(role);

        try {
            List<Class> classes = isAdmin ? classService.findAll() : classService.findByTutor(userId);
            List<Exam> exams = isAdmin ? examService.findAll() : examService.findByTutor(userId);
            Map<Integer, Integer> submissionCounts = examMcqService.getSubmissionCounts();
            Map<Integer, Integer> pendingCounts = examMcqService.getPendingCounts();

            request.setAttribute("classes", classes);
            request.setAttribute("exams", exams);
            request.setAttribute("submissionCounts", submissionCounts);
            request.setAttribute("pendingCounts", pendingCounts);

            request.getRequestDispatcher("/tutor/schedule-exam.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("/tutor/schedule-exam.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String role = String.valueOf(session.getAttribute("userRole"));

        if (!"TUTOR".equalsIgnoreCase(role) && !"ADMIN".equalsIgnoreCase(role)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        int userId = (int) session.getAttribute("userId");
        boolean isAdmin = "ADMIN".equalsIgnoreCase(role);
        String action = request.getParameter("action");

        try {
            if ("cancel".equals(action)) {
                int examId = Integer.parseInt(request.getParameter("examId"));
                examService.cancelExam(examId);
                session.setAttribute("flashSuccess", "Exam cancelled successfully.");
                response.sendRedirect(request.getContextPath() + "/tutor/exams");
                return;
            }

            if ("complete".equals(action)) {
                int examId = Integer.parseInt(request.getParameter("examId"));
                Exam exam = examService.findById(examId);
                if (exam != null) {
                    if (!isAdmin) {
                        Class classItem = classService.findById(exam.getClassId());
                        if (classItem == null || classItem.getTutorId() == null || classItem.getTutorId() != userId) {
                            session.setAttribute("flashError", "You are not assigned to this class.");
                            response.sendRedirect(request.getContextPath() + "/tutor/exams");
                            return;
                        }
                    }
                    examService.markCompleted(examId);
                    session.setAttribute("flashSuccess", "Quiz process finished! Exam marked as COMPLETED.");
                }
                response.sendRedirect(request.getContextPath() + "/tutor/exams");
                return;
            }

            int classId = Integer.parseInt(request.getParameter("classId"));

            if (!isAdmin) {
                Class classItem = classService.findById(classId);
                if (classItem == null || classItem.getTutorId() == null || classItem.getTutorId() != userId) {
                    request.setAttribute("errorMessage", "You are not assigned to this class.");
                    request.setAttribute("classes", classService.findByTutor(userId));
                    request.setAttribute("exams", examService.findByTutor(userId));
                    request.getRequestDispatcher("/tutor/schedule-exam.jsp").forward(request, response);
                    return;
                }
            }

            String examName = request.getParameter("examName");
            Date examDate = Date.valueOf(request.getParameter("examDate"));
            BigDecimal maxMarks = new BigDecimal(request.getParameter("maxMarks"));

            String errorMessage = examService.scheduleExam(classId, examName, examDate, maxMarks, userId);

            if (errorMessage != null) {
                request.setAttribute("errorMessage", errorMessage);
                request.setAttribute("classes", isAdmin ? classService.findAll() : classService.findByTutor(userId));
                request.setAttribute("exams", isAdmin ? examService.findAll() : examService.findByTutor(userId));
                request.getRequestDispatcher("/tutor/schedule-exam.jsp").forward(request, response);
                return;
            }

            response.sendRedirect(request.getContextPath() + "/tutor/exams");

        } catch (IllegalArgumentException e) {
            response.sendRedirect(request.getContextPath() + "/tutor/exams");
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            response.sendRedirect(request.getContextPath() + "/tutor/exams");
        }
    }
}