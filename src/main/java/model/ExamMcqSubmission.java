package model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class ExamMcqSubmission {

    private int submissionId;
    private int examId;
    private int studentId;
    private int totalQuestions;
    private int correctAnswers;
    private BigDecimal scoreObtained;
    private BigDecimal maxPossible;
    private Timestamp submittedAt;
    private String status; // "PENDING" or "REVIEWED"
    private Timestamp reviewedAt;
    private Integer reviewedBy;
    private String studentName;
    private BigDecimal scaledMarks;

    public ExamMcqSubmission() {
    }

    public int getSubmissionId() {
        return submissionId;
    }

    public void setSubmissionId(int submissionId) {
        this.submissionId = submissionId;
    }

    public int getExamId() {
        return examId;
    }

    public void setExamId(int examId) {
        this.examId = examId;
    }

    public int getStudentId() {
        return studentId;
    }

    public void setStudentId(int studentId) {
        this.studentId = studentId;
    }

    public int getTotalQuestions() {
        return totalQuestions;
    }

    public void setTotalQuestions(int totalQuestions) {
        this.totalQuestions = totalQuestions;
    }

    public int getCorrectAnswers() {
        return correctAnswers;
    }

    public void setCorrectAnswers(int correctAnswers) {
        this.correctAnswers = correctAnswers;
    }

    public BigDecimal getScoreObtained() {
        return scoreObtained;
    }

    public void setScoreObtained(BigDecimal scoreObtained) {
        this.scoreObtained = scoreObtained;
    }

    public BigDecimal getMaxPossible() {
        return maxPossible;
    }

    public void setMaxPossible(BigDecimal maxPossible) {
        this.maxPossible = maxPossible;
    }

    public Timestamp getSubmittedAt() {
        return submittedAt;
    }

    public void setSubmittedAt(Timestamp submittedAt) {
        this.submittedAt = submittedAt;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Timestamp getReviewedAt() {
        return reviewedAt;
    }

    public void setReviewedAt(Timestamp reviewedAt) {
        this.reviewedAt = reviewedAt;
    }

    public Integer getReviewedBy() {
        return reviewedBy;
    }

    public void setReviewedBy(Integer reviewedBy) {
        this.reviewedBy = reviewedBy;
    }

    public String getStudentName() {
        return studentName;
    }

    public void setStudentName(String studentName) {
        this.studentName = studentName;
    }

    public BigDecimal getScaledMarks() {
        return scaledMarks;
    }

    public void setScaledMarks(BigDecimal scaledMarks) {
        this.scaledMarks = scaledMarks;
    }
}
