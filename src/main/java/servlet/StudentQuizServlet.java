package servlet;

import dao.EnrollmentDAO;
import model.Class;
import model.Exam;
import model.ExamMcqQuestion;
import model.ExamMcqSubmission;
import model.ExamResult;
import model.User;
import service.ClassService;
import service.ExamMcqService;
import service.ExamService;
import service.NotificationService;
import service.ResultService;
import service.UserService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/student/quiz")
public class StudentQuizServlet extends HttpServlet {

    private ExamService examService;
    private ExamMcqService examMcqService;
    private EnrollmentDAO enrollmentDAO;
    private ResultService resultService;
    private ClassService classService;
    private NotificationService notificationService;
    private UserService userService;

    @Override
    public void init() {
        examService = new ExamService();
        examMcqService = new ExamMcqService();
        enrollmentDAO = new EnrollmentDAO();
        resultService = new ResultService();
        classService = new ClassService();
        notificationService = new NotificationService();
        userService = new UserService();
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
        if (!"STUDENT".equalsIgnoreCase(role)) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        int studentId = (int) session.getAttribute("userId");

        try {
            int examId = Integer.parseInt(request.getParameter("examId"));
            Exam exam = examService.findById(examId);

            if (exam == null) {
                response.sendRedirect(request.getContextPath() + "/dashboard");
                return;
            }

            if (!enrollmentDAO.isEnrolled(exam.getClassId(), studentId)) {
                request.setAttribute("dashboardError", "You are not enrolled in the class for this exam.");
                response.sendRedirect(request.getContextPath() + "/dashboard");
                return;
            }

            boolean hasAttempted = examMcqService.hasAttempted(examId, studentId);
            List<ExamMcqQuestion> questions = examMcqService.getQuestions(examId);

            request.setAttribute("exam", exam);
            request.setAttribute("questions", questions);
            request.setAttribute("hasAttempted", hasAttempted);

            if (hasAttempted) {
                ExamMcqSubmission submission = examMcqService.getSubmission(examId, studentId);
                Map<Integer, String> studentAnswers = submission != null
                        ? examMcqService.getStudentAnswers(submission.getSubmissionId())
                        : new HashMap<>();
                ExamResult examResult = resultService.getResult(examId, studentId);

                boolean isPendingReview = submission == null || !"REVIEWED".equalsIgnoreCase(submission.getStatus());

                request.setAttribute("submission", submission);
                request.setAttribute("studentAnswers", studentAnswers);
                request.setAttribute("examResult", examResult);
                request.setAttribute("isPendingReview", isPendingReview);
            }

            request.getRequestDispatcher("/student/take-quiz.jsp").forward(request, response);

        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/dashboard");
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
        if (!"STUDENT".equalsIgnoreCase(role)) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        request.setCharacterEncoding("UTF-8");
        int studentId = (int) session.getAttribute("userId");

        try {
            int examId = Integer.parseInt(request.getParameter("examId"));
            Exam exam = examService.findById(examId);

            if (exam == null || !enrollmentDAO.isEnrolled(exam.getClassId(), studentId)) {
                response.sendRedirect(request.getContextPath() + "/dashboard");
                return;
            }

            if (examMcqService.hasAttempted(examId, studentId)) {
                session.setAttribute("flashError", "You have already completed this quiz.");
                response.sendRedirect(request.getContextPath() + "/student/quiz?examId=" + examId);
                return;
            }

            if ("CANCELLED".equalsIgnoreCase(exam.getStatus()) || "COMPLETED".equalsIgnoreCase(exam.getStatus())) {
                session.setAttribute("flashError", "This exam has concluded and is closed for submissions.");
                response.sendRedirect(request.getContextPath() + "/student/quiz?examId=" + examId);
                return;
            }

            List<ExamMcqQuestion> questions = examMcqService.getQuestions(examId);
            Map<Integer, String> studentAnswers = new HashMap<>();

            for (ExamMcqQuestion q : questions) {
                String chosen = request.getParameter("q_" + q.getQuestionId());
                if (chosen != null && !chosen.isBlank()) {
                    studentAnswers.put(q.getQuestionId(), chosen.trim().toUpperCase());
                }
            }

            String error = examMcqService.submitAndGradeQuiz(examId, studentId, studentAnswers);

            if (error != null) {
                session.setAttribute("flashError", error);
            } else {
                session.setAttribute("flashSuccess", "Quiz submitted successfully! Your submission has been sent to your tutor for review. Marks and answers will be available once your tutor releases the results.");

                try {
                    Class classItem = classService.findById(exam.getClassId());
                    if (classItem != null && classItem.getTutorId() != null) {
                        User studentUser = userService.findById(studentId);
                        String studentName = (studentUser != null)
                                ? studentUser.getFirstName() + " " + studentUser.getLastName()
                                : "A student";
                        notificationService.notifyUser(
                                classItem.getTutorId(),
                                "New Quiz Submission: " + exam.getExamName(),
                                studentName + " has submitted their quiz for " + exam.getExamName() + " (" + classItem.getSubject() + "). Click to review answers and enter/release marks.",
                                "RESULT",
                                exam.getClassId(),
                                studentId
                        );
                    }
                } catch (Exception notifEx) {
                    notifEx.printStackTrace();
                }
            }

            response.sendRedirect(request.getContextPath() + "/student/quiz?examId=" + examId);

        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/dashboard");
        }
    }
}
