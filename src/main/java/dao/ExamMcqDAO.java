package dao;

import model.ExamMcqQuestion;
import model.ExamMcqReviewItem;
import model.ExamMcqSubmission;
import util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ExamMcqDAO {

    public int addQuestion(ExamMcqQuestion q) throws SQLException {
        String sql = """
                INSERT INTO dbo.exam_mcq_questions (exam_id, question_text, option_a, option_b, option_c, option_d, correct_option, points)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            statement.setInt(1, q.getExamId());
            statement.setString(2, q.getQuestionText());
            statement.setString(3, q.getOptionA());
            statement.setString(4, q.getOptionB());
            statement.setString(5, q.getOptionC());
            statement.setString(6, q.getOptionD());
            statement.setString(7, q.getCorrectOption().toUpperCase());
            statement.setBigDecimal(8, q.getPoints() != null ? q.getPoints() : BigDecimal.ONE);

            int rows = statement.executeUpdate();
            if (rows > 0) {
                try (ResultSet keys = statement.getGeneratedKeys()) {
                    if (keys.next()) {
                        return keys.getInt(1);
                    }
                }
            }
        }
        return -1;
    }

    public boolean deleteQuestion(int questionId, int examId) throws SQLException {
        String sql = "DELETE FROM dbo.exam_mcq_questions WHERE question_id = ? AND exam_id = ?";

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, questionId);
            statement.setInt(2, examId);
            return statement.executeUpdate() > 0;
        }
    }

    public List<ExamMcqQuestion> findQuestionsByExam(int examId) throws SQLException {
        String sql = """
                SELECT question_id, exam_id, question_text, option_a, option_b, option_c, option_d,
                       correct_option, points, created_at
                FROM dbo.exam_mcq_questions
                WHERE exam_id = ?
                ORDER BY question_id ASC
                """;

        List<ExamMcqQuestion> list = new ArrayList<>();
        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, examId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    ExamMcqQuestion q = new ExamMcqQuestion();
                    q.setQuestionId(rs.getInt("question_id"));
                    q.setExamId(rs.getInt("exam_id"));
                    q.setQuestionText(rs.getString("question_text"));
                    q.setOptionA(rs.getString("option_a"));
                    q.setOptionB(rs.getString("option_b"));
                    q.setOptionC(rs.getString("option_c"));
                    q.setOptionD(rs.getString("option_d"));
                    q.setCorrectOption(rs.getString("correct_option"));
                    q.setPoints(rs.getBigDecimal("points"));
                    q.setCreatedAt(rs.getTimestamp("created_at"));
                    list.add(q);
                }
            }
        }
        return list;
    }

    public int countQuestionsByExam(int examId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM dbo.exam_mcq_questions WHERE exam_id = ?";

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, examId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    public boolean hasStudentAttempted(int examId, int studentId) throws SQLException {
        String sql = "SELECT 1 FROM dbo.exam_mcq_submissions WHERE exam_id = ? AND student_id = ?";

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, examId);
            statement.setInt(2, studentId);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next();
            }
        }
    }

    public ExamMcqSubmission findSubmission(int examId, int studentId) throws SQLException {
        String sql = """
                SELECT submission_id, exam_id, student_id, total_questions, correct_answers,
                       score_obtained, max_possible, submitted_at, status, reviewed_at, reviewed_by
                FROM dbo.exam_mcq_submissions
                WHERE exam_id = ? AND student_id = ?
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, examId);
            statement.setInt(2, studentId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    ExamMcqSubmission sub = new ExamMcqSubmission();
                    sub.setSubmissionId(rs.getInt("submission_id"));
                    sub.setExamId(rs.getInt("exam_id"));
                    sub.setStudentId(rs.getInt("student_id"));
                    sub.setTotalQuestions(rs.getInt("total_questions"));
                    sub.setCorrectAnswers(rs.getInt("correct_answers"));
                    sub.setScoreObtained(rs.getBigDecimal("score_obtained"));
                    sub.setMaxPossible(rs.getBigDecimal("max_possible"));
                    sub.setSubmittedAt(rs.getTimestamp("submitted_at"));
                    sub.setStatus(rs.getString("status"));
                    sub.setReviewedAt(rs.getTimestamp("reviewed_at"));
                    int rBy = rs.getInt("reviewed_by");
                    if (!rs.wasNull()) {
                        sub.setReviewedBy(rBy);
                    }
                    return sub;
                }
            }
        }
        return null;
    }

    public List<ExamMcqSubmission> findSubmissionsByExam(int examId) throws SQLException {
        String sql = """
                SELECT s.submission_id, s.exam_id, s.student_id, s.total_questions, s.correct_answers,
                       s.score_obtained, s.max_possible, s.submitted_at, s.status, s.reviewed_at, s.reviewed_by,
                       u.first_name, u.last_name
                FROM dbo.exam_mcq_submissions s
                JOIN dbo.users u ON u.user_id = s.student_id
                WHERE s.exam_id = ?
                ORDER BY s.submitted_at DESC
                """;

        List<ExamMcqSubmission> list = new ArrayList<>();
        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, examId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    ExamMcqSubmission sub = new ExamMcqSubmission();
                    sub.setSubmissionId(rs.getInt("submission_id"));
                    sub.setExamId(rs.getInt("exam_id"));
                    sub.setStudentId(rs.getInt("student_id"));
                    sub.setTotalQuestions(rs.getInt("total_questions"));
                    sub.setCorrectAnswers(rs.getInt("correct_answers"));
                    sub.setScoreObtained(rs.getBigDecimal("score_obtained"));
                    sub.setMaxPossible(rs.getBigDecimal("max_possible"));
                    sub.setSubmittedAt(rs.getTimestamp("submitted_at"));
                    sub.setStatus(rs.getString("status"));
                    sub.setReviewedAt(rs.getTimestamp("reviewed_at"));
                    int rBy = rs.getInt("reviewed_by");
                    if (!rs.wasNull()) {
                        sub.setReviewedBy(rBy);
                    }
                    sub.setStudentName(rs.getString("first_name") + " " + rs.getString("last_name"));
                    list.add(sub);
                }
            }
        }
        return list;
    }

    public boolean updateSubmissionStatus(int examId, int studentId, String status, int reviewedBy) throws SQLException {
        String sql = """
                UPDATE dbo.exam_mcq_submissions
                SET status = ?, reviewed_at = GETDATE(), reviewed_by = ?
                WHERE exam_id = ? AND student_id = ?
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setString(1, status);
            statement.setInt(2, reviewedBy);
            statement.setInt(3, examId);
            statement.setInt(4, studentId);
            return statement.executeUpdate() > 0;
        }
    }

    public List<ExamMcqReviewItem> findSubmissionReviewItems(int examId, int studentId) throws SQLException {
        String sql = """
                SELECT q.question_id, q.question_text, q.option_a, q.option_b, q.option_c, q.option_d,
                       q.correct_option, q.points, a.selected_option, a.is_correct
                FROM dbo.exam_mcq_questions q
                LEFT JOIN dbo.exam_mcq_submissions s ON s.exam_id = q.exam_id AND s.student_id = ?
                LEFT JOIN dbo.exam_mcq_answers a ON a.question_id = q.question_id AND a.submission_id = s.submission_id
                WHERE q.exam_id = ?
                ORDER BY q.question_id ASC
                """;

        List<ExamMcqReviewItem> list = new ArrayList<>();
        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, studentId);
            statement.setInt(2, examId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    ExamMcqReviewItem item = new ExamMcqReviewItem();
                    item.setQuestionId(rs.getInt("question_id"));
                    item.setQuestionText(rs.getString("question_text"));
                    item.setOptionA(rs.getString("option_a"));
                    item.setOptionB(rs.getString("option_b"));
                    item.setOptionC(rs.getString("option_c"));
                    item.setOptionD(rs.getString("option_d"));
                    item.setCorrectOption(rs.getString("correct_option"));
                    item.setPoints(rs.getBigDecimal("points"));
                    item.setSelectedOption(rs.getString("selected_option"));
                    item.setCorrect(rs.getBoolean("is_correct"));
                    list.add(item);
                }
            }
        }
        return list;
    }

    public Map<Integer, String> findStudentAnswers(int submissionId) throws SQLException {
        String sql = "SELECT question_id, selected_option FROM dbo.exam_mcq_answers WHERE submission_id = ?";
        Map<Integer, String> map = new HashMap<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, submissionId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    map.put(rs.getInt("question_id"), rs.getString("selected_option"));
                }
            }
        }
        return map;
    }

    public int saveSubmission(int examId, int studentId, int totalQuestions, int correctAnswers,
                              BigDecimal scoreObtained, BigDecimal maxPossible,
                              Map<Integer, String> studentAnswers, Map<Integer, Boolean> isCorrectMap) throws SQLException {
        return saveSubmission(examId, studentId, totalQuestions, correctAnswers, scoreObtained, maxPossible,
                studentAnswers, isCorrectMap, "PENDING");
    }

    public int saveSubmission(int examId, int studentId, int totalQuestions, int correctAnswers,
                              BigDecimal scoreObtained, BigDecimal maxPossible,
                              Map<Integer, String> studentAnswers, Map<Integer, Boolean> isCorrectMap,
                              String status) throws SQLException {

        String subSql = """
                INSERT INTO dbo.exam_mcq_submissions
                (exam_id, student_id, total_questions, correct_answers, score_obtained, max_possible, submitted_at, status)
                VALUES (?, ?, ?, ?, ?, ?, GETDATE(), ?)
                """;

        String ansSql = """
                INSERT INTO dbo.exam_mcq_answers (submission_id, question_id, selected_option, is_correct)
                VALUES (?, ?, ?, ?)
                """;

        try (Connection connection = DBUtil.getConnection()) {
            connection.setAutoCommit(false);

            int submissionId = -1;
            try (PreparedStatement subStmt = connection.prepareStatement(subSql, Statement.RETURN_GENERATED_KEYS)) {
                subStmt.setInt(1, examId);
                subStmt.setInt(2, studentId);
                subStmt.setInt(3, totalQuestions);
                subStmt.setInt(4, correctAnswers);
                subStmt.setBigDecimal(5, scoreObtained);
                subStmt.setBigDecimal(6, maxPossible);
                subStmt.setString(7, status != null ? status : "PENDING");

                subStmt.executeUpdate();
                try (ResultSet keys = subStmt.getGeneratedKeys()) {
                    if (keys.next()) {
                        submissionId = keys.getInt(1);
                    }
                }
            }

            if (submissionId > 0 && studentAnswers != null) {
                try (PreparedStatement ansStmt = connection.prepareStatement(ansSql)) {
                    for (Map.Entry<Integer, String> entry : studentAnswers.entrySet()) {
                        int qId = entry.getKey();
                        String chosen = entry.getValue();
                        boolean correct = isCorrectMap != null && Boolean.TRUE.equals(isCorrectMap.get(qId));

                        ansStmt.setInt(1, submissionId);
                        ansStmt.setInt(2, qId);
                        ansStmt.setString(3, chosen);
                        ansStmt.setBoolean(4, correct);
                        ansStmt.addBatch();
                    }
                    ansStmt.executeBatch();
                }
            }

            connection.commit();
            return submissionId;
        } catch (SQLException e) {
            throw e;
        }
    }

    public Map<Integer, Integer> getSubmissionCounts() throws SQLException {
        String sql = "SELECT exam_id, COUNT(*) AS cnt FROM dbo.exam_mcq_submissions GROUP BY exam_id";
        Map<Integer, Integer> map = new HashMap<>();
        try (Connection connection = DBUtil.getConnection();
             Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                map.put(rs.getInt("exam_id"), rs.getInt("cnt"));
            }
        }
        return map;
    }

    public Map<Integer, Integer> getPendingCounts() throws SQLException {
        String sql = "SELECT exam_id, COUNT(*) AS cnt FROM dbo.exam_mcq_submissions WHERE status = 'PENDING' OR status IS NULL GROUP BY exam_id";
        Map<Integer, Integer> map = new HashMap<>();
        try (Connection connection = DBUtil.getConnection();
             Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                map.put(rs.getInt("exam_id"), rs.getInt("cnt"));
            }
        }
        return map;
    }

    public int countSubmissions(int examId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM dbo.exam_mcq_submissions WHERE exam_id = ?";
        try (Connection connection = DBUtil.getConnection();
             PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, examId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }
}
