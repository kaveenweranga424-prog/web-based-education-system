package service;

import dao.ExamDAO;
import dao.ExamResultDAO;
import model.Exam;
import model.ExamResult;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.SQLException;
import java.util.List;

public class ResultService {

    private final ExamResultDAO examResultDAO = new ExamResultDAO();
    private final ExamDAO examDAO = new ExamDAO();
    private final NotificationService notificationService = new NotificationService();

    public List<ExamResult> getRoster(int examId) throws SQLException {
        Exam exam = examDAO.findById(examId);

        if (exam == null) {
            return List.of();
        }

        return examResultDAO.getRoster(examId, exam.getClassId());
    }

    /**
     * Enters/corrects one student's marks for an exam. Computes the letter grade
     * automatically from the percentage of max marks. Returns an error message,
     * or null on success. tutorId/isAdmin gate who may enter marks for this exam.
     */
    public String enterMarks(int examId, int studentId, BigDecimal marksObtained,
                             String remarks, int enteredByUserId, boolean isAdmin) throws SQLException {

        Exam exam = examDAO.findById(examId);

        if (exam == null) {
            return "Exam not found.";
        }

        if (!isAdmin) {
            // tutor must own the exam's classItem; ClassDAO check happens via the servlet,
            // this service assumes the caller already verified ownership for non-admins.
        }

        if (marksObtained == null || marksObtained.compareTo(BigDecimal.ZERO) < 0) {
            return "Marks cannot be negative.";
        }

        if (marksObtained.compareTo(exam.getMaxMarks()) > 0) {
            return "Marks cannot exceed the maximum of " + exam.getMaxMarks() + ".";
        }

        ExamResult existing = examResultDAO.findByExamAndStudent(examId, studentId);
        boolean isUpdate = existing != null && existing.getResultId() > 0;

        String grade = calculateGrade(marksObtained, exam.getMaxMarks());

        boolean saved = examResultDAO.upsert(examId, studentId, marksObtained, grade, remarks, enteredByUserId);

        if (!saved) {
            return "Failed to save the result. Please try again.";
        }

        String title = isUpdate ? "Exam Result Updated" : "Result published";

        String message = isUpdate
                ? "Your result for " + exam.getExamName() + " (" + exam.getSubject() + ") has been updated: "
                  + marksObtained + " / " + exam.getMaxMarks() + " (Grade " + grade + ")."
                : exam.getExamName() + " (" + exam.getSubject()
                  + " - " + exam.getBatch() + ") — you scored "
                  + marksObtained + " / " + exam.getMaxMarks()
                  + " (Grade " + grade + ").";

        notificationService.notifyStudentAndParents(
                studentId,
                title,
                message,
                "RESULT",
                exam.getClassId()
        );

        return null;
    }

    public List<ExamResult> getResultsByExam(int examId) throws SQLException {
        return examResultDAO.findByExam(examId);
    }

    public ExamResult getResult(int examId, int studentId) throws SQLException {
        return examResultDAO.findByExamAndStudent(examId, studentId);
    }

    public List<ExamResult> getResultsByStudent(int studentId) throws SQLException {
        return examResultDAO.findByStudent(studentId);
    }

    public boolean deleteResult(int resultId) throws SQLException {
        return examResultDAO.deleteResult(resultId);
    }

    /**
     * A+ >= 90, A >= 80, B >= 70, C >= 60, D >= 50, E >= 40, F < 40 (percentage-based).
     */
    private String calculateGrade(BigDecimal marksObtained, BigDecimal maxMarks) {
        BigDecimal percentage = marksObtained
                .divide(maxMarks, 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100));

        double pct = percentage.doubleValue();

        if (pct >= 90) return "A+";
        if (pct >= 80) return "A";
        if (pct >= 70) return "B";
        if (pct >= 60) return "C";
        if (pct >= 50) return "D";
        if (pct >= 40) return "E";
        return "F";
    }
}