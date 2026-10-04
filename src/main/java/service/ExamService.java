package service;

import dao.ExamDAO;
import model.Exam;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.SQLException;
import java.util.List;

public class ExamService {

    private final ExamDAO examDAO = new ExamDAO();

    /**
     * Returns an error message, or null if the exam was scheduled successfully.
     */
    public String scheduleExam(int classId, String examName, Date examDate,
                               BigDecimal maxMarks, int createdBy) throws SQLException {

        if (examName == null || examName.isBlank()) {
            return "Exam name is required.";
        }

        if (examName.length() > 150) {
            return "Exam name is too long.";
        }

        if (examDate == null) {
            return "Exam date is required.";
        }

        if (maxMarks == null || maxMarks.compareTo(BigDecimal.ZERO) <= 0) {
            return "Max marks must be greater than zero.";
        }

        Exam exam = new Exam();
        exam.setClassId(classId);
        exam.setExamName(examName.trim());
        exam.setExamDate(examDate);
        exam.setMaxMarks(maxMarks);
        exam.setCreatedBy(createdBy);

        int id = examDAO.createExam(exam);

        if (id <= 0) {
            return "Failed to schedule the exam. Please try again.";
        }

        return null;
    }

    public boolean cancelExam(int examId) throws SQLException {
        return examDAO.cancelExam(examId);
    }

    public boolean markCompleted(int examId) throws SQLException {
        return examDAO.markCompleted(examId);
    }

    public Exam findById(int examId) throws SQLException {
        return examDAO.findById(examId);
    }

    public List<Exam> findAll() throws SQLException {
        return examDAO.findAll();
    }

    public List<Exam> findByClass(int classId) throws SQLException {
        return examDAO.findByClass(classId);
    }

    public List<Exam> findByTutor(int tutorId) throws SQLException {
        return examDAO.findByTutor(tutorId);
    }
}