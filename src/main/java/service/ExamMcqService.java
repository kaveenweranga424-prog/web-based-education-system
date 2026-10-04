package service;

import dao.ClassDAO;
import dao.ExamDAO;
import dao.ExamMcqDAO;
import model.Exam;
import model.ExamMcqQuestion;
import model.ExamMcqReviewItem;
import model.ExamMcqSubmission;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ExamMcqService {

    private final ExamMcqDAO examMcqDAO = new ExamMcqDAO();
    private final ExamDAO examDAO = new ExamDAO();
    private final ClassDAO classDAO = new ClassDAO();
    private final ResultService resultService = new ResultService();

    public List<ExamMcqQuestion> getQuestions(int examId) throws SQLException {
        return examMcqDAO.findQuestionsByExam(examId);
    }

    public int countQuestions(int examId) throws SQLException {
        return examMcqDAO.countQuestionsByExam(examId);
    }

    public ExamMcqSubmission getSubmission(int examId, int studentId) throws SQLException {
        return examMcqDAO.findSubmission(examId, studentId);
    }

    public Map<Integer, String> getStudentAnswers(int submissionId) throws SQLException {
        return examMcqDAO.findStudentAnswers(submissionId);
    }

    public boolean hasAttempted(int examId, int studentId) throws SQLException {
        return examMcqDAO.hasStudentAttempted(examId, studentId);
    }

    public List<ExamMcqSubmission> getSubmissionsByExam(int examId) throws SQLException {
        Exam exam = examDAO.findById(examId);
        List<ExamMcqSubmission> list = examMcqDAO.findSubmissionsByExam(examId);
        for (ExamMcqSubmission sub : list) {
            calculateScaledMarks(sub, exam);
        }
        return list;
    }

    public Map<Integer, ExamMcqSubmission> getSubmissionsMapByExam(int examId) throws SQLException {
        Exam exam = examDAO.findById(examId);
        List<ExamMcqSubmission> list = examMcqDAO.findSubmissionsByExam(examId);
        Map<Integer, ExamMcqSubmission> map = new HashMap<>();
        for (ExamMcqSubmission sub : list) {
            calculateScaledMarks(sub, exam);
            map.put(sub.getStudentId(), sub);
        }
        return map;
    }

    private void calculateScaledMarks(ExamMcqSubmission sub, Exam exam) {
        if (sub != null && sub.getMaxPossible() != null && sub.getMaxPossible().compareTo(BigDecimal.ZERO) > 0
                && exam != null && exam.getMaxMarks() != null) {
            BigDecimal scaled = sub.getScoreObtained()
                    .divide(sub.getMaxPossible(), 4, RoundingMode.HALF_UP)
                    .multiply(exam.getMaxMarks())
                    .setScale(2, RoundingMode.HALF_UP);
            sub.setScaledMarks(scaled);
        } else if (sub != null) {
            sub.setScaledMarks(BigDecimal.ZERO);
        }
    }

    public List<ExamMcqReviewItem> getSubmissionReview(int examId, int studentId) throws SQLException {
        return examMcqDAO.findSubmissionReviewItems(examId, studentId);
    }

    public boolean markSubmissionReviewed(int examId, int studentId, int reviewedBy) throws SQLException {
        return examMcqDAO.updateSubmissionStatus(examId, studentId, "REVIEWED", reviewedBy);
    }

    public String addQuestion(int examId, String questionText,
                              String optA, String optB, String optC, String optD,
                              String correctOpt, BigDecimal points) throws SQLException {

        if (questionText == null || questionText.trim().isBlank()) {
            return "Question text cannot be empty.";
        }
        if (optA == null || optA.trim().isBlank() ||
            optB == null || optB.trim().isBlank() ||
            optC == null || optC.trim().isBlank() ||
            optD == null || optD.trim().isBlank()) {
            return "All four options (A, B, C, D) must be provided.";
        }
        if (correctOpt == null || !correctOpt.trim().matches("(?i)[ABCD]")) {
            return "Please select a valid correct option (A, B, C, or D).";
        }
        if (points == null || points.compareTo(BigDecimal.ZERO) <= 0) {
            points = BigDecimal.ONE;
        }

        Exam exam = examDAO.findById(examId);
        if (exam == null) {
            return "Exam not found.";
        }

        ExamMcqQuestion q = new ExamMcqQuestion();
        q.setExamId(examId);
        q.setQuestionText(questionText.trim());
        q.setOptionA(optA.trim());
        q.setOptionB(optB.trim());
        q.setOptionC(optC.trim());
        q.setOptionD(optD.trim());
        q.setCorrectOption(correctOpt.trim().toUpperCase());
        q.setPoints(points);

        int id = examMcqDAO.addQuestion(q);
        return id > 0 ? null : "Failed to add question. Please try again.";
    }

    public boolean deleteQuestion(int questionId, int examId) throws SQLException {
        return examMcqDAO.deleteQuestion(questionId, examId);
    }

    /**
     * Records student's quiz submission with 'PENDING' status.
     * Evaluates answers and stores correctness/score for tutor review,
     * but DOES NOT publish to dbo.exam_results immediately.
     * The tutor must review and update/publish marks from the tutor side.
     */
    public String submitAndGradeQuiz(int examId, int studentId, Map<Integer, String> studentAnswers) throws SQLException {
        Exam exam = examDAO.findById(examId);
        if (exam == null) {
            return "Exam not found.";
        }

        if ("CANCELLED".equalsIgnoreCase(exam.getStatus())) {
            return "This exam has been cancelled.";
        }

        if (examMcqDAO.hasStudentAttempted(examId, studentId)) {
            return "You have already completed this quiz.";
        }

        List<ExamMcqQuestion> questions = examMcqDAO.findQuestionsByExam(examId);
        if (questions.isEmpty()) {
            return "No questions available for this exam.";
        }

        BigDecimal totalPossiblePoints = BigDecimal.ZERO;
        BigDecimal earnedPoints = BigDecimal.ZERO;
        int correctCount = 0;
        Map<Integer, Boolean> isCorrectMap = new HashMap<>();

        for (ExamMcqQuestion q : questions) {
            BigDecimal qPoints = q.getPoints() != null && q.getPoints().compareTo(BigDecimal.ZERO) > 0
                    ? q.getPoints() : BigDecimal.ONE;
            totalPossiblePoints = totalPossiblePoints.add(qPoints);

            String selected = studentAnswers != null ? studentAnswers.get(q.getQuestionId()) : null;
            boolean isCorrect = selected != null && selected.trim().equalsIgnoreCase(q.getCorrectOption().trim());

            if (isCorrect) {
                correctCount++;
                earnedPoints = earnedPoints.add(qPoints);
                isCorrectMap.put(q.getQuestionId(), true);
            } else {
                isCorrectMap.put(q.getQuestionId(), false);
            }
        }

        // Save detailed quiz submission with PENDING status for tutor review
        int submissionId = examMcqDAO.saveSubmission(
                examId, studentId, questions.size(), correctCount,
                earnedPoints, totalPossiblePoints, studentAnswers, isCorrectMap,
                "PENDING"
        );

        if (submissionId <= 0) {
            return "Failed to save your quiz submission. Please try again.";
        }

        return null; // Successfully submitted, pending tutor review
    }

    public Map<Integer, Integer> getSubmissionCounts() throws SQLException {
        return examMcqDAO.getSubmissionCounts();
    }

    public Map<Integer, Integer> getPendingCounts() throws SQLException {
        return examMcqDAO.getPendingCounts();
    }

    public int countSubmissions(int examId) throws SQLException {
        return examMcqDAO.countSubmissions(examId);
    }
}
