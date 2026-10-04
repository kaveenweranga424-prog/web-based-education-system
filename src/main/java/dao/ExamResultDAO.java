package dao;

import model.ExamResult;
import util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class ExamResultDAO {

    /**
     * All students enrolled in the exam's classItem, each paired with their result
     * for this exam if one exists (marksObtained/grade null, resultId 0 otherwise).
     */
    public List<ExamResult> getRoster(int examId, int classId) throws SQLException {
        String sql = """
                SELECT en.student_id, u.first_name, u.last_name,
                       r.result_id, r.marks_obtained, r.grade, r.remarks, r.entered_at
                FROM dbo.enrollments en
                JOIN dbo.users u ON u.user_id = en.student_id
                LEFT JOIN dbo.exam_results r
                       ON r.exam_id = ? AND r.student_id = en.student_id
                WHERE en.class_id = ? AND en.status = 'ACTIVE'
                ORDER BY u.first_name
                """;

        List<ExamResult> roster = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, examId);
            statement.setInt(2, classId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    ExamResult result = new ExamResult();
                    result.setExamId(examId);
                    result.setStudentId(resultSet.getInt("student_id"));
                    result.setStudentName(
                            resultSet.getString("first_name") + " " + resultSet.getString("last_name")
                    );
                    result.setResultId(resultSet.getInt("result_id")); // 0 if null
                    result.setMarksObtained(resultSet.getBigDecimal("marks_obtained"));
                    result.setGrade(resultSet.getString("grade"));
                    result.setRemarks(resultSet.getString("remarks"));
                    result.setEnteredAt(resultSet.getTimestamp("entered_at"));

                    roster.add(result);
                }
            }
        }

        return roster;
    }

    /**
     * Insert or update the result for one student/exam (upsert) — same pattern as attendance.
     */
    public boolean upsert(int examId, int studentId, BigDecimal marksObtained,
                          String grade, String remarks, int enteredBy) throws SQLException {

        String updateSql = """
                UPDATE dbo.exam_results
                SET marks_obtained = ?, grade = ?, remarks = ?, entered_by = ?, entered_at = GETDATE()
                WHERE exam_id = ? AND student_id = ?
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement updateStatement = connection.prepareStatement(updateSql)) {

            updateStatement.setBigDecimal(1, marksObtained);
            updateStatement.setString(2, grade);
            updateStatement.setString(3, remarks);
            updateStatement.setInt(4, enteredBy);
            updateStatement.setInt(5, examId);
            updateStatement.setInt(6, studentId);

            int updatedRows = updateStatement.executeUpdate();

            if (updatedRows > 0) {
                return true;
            }

            String insertSql = """
                    INSERT INTO dbo.exam_results (exam_id, student_id, marks_obtained, grade, remarks, entered_by, entered_at)
                    VALUES (?, ?, ?, ?, ?, ?, GETDATE())
                    """;

            try (PreparedStatement insertStatement =
                         connection.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {

                insertStatement.setInt(1, examId);
                insertStatement.setInt(2, studentId);
                insertStatement.setBigDecimal(3, marksObtained);
                insertStatement.setString(4, grade);
                insertStatement.setString(5, remarks);
                insertStatement.setInt(6, enteredBy);

                return insertStatement.executeUpdate() > 0;
            }
        }
    }

    public List<ExamResult> findByExam(int examId) throws SQLException {
        String sql = """
                SELECT r.result_id, r.exam_id, r.marks_obtained, r.grade, r.remarks,
                       r.entered_by, r.entered_at,
                       u.first_name, u.last_name,
                       e.exam_name, e.max_marks, c.subject, c.batch
                FROM dbo.exam_results r
                JOIN dbo.users u ON u.user_id = r.student_id
                JOIN dbo.exams e ON e.exam_id = r.exam_id
                JOIN dbo.classes c ON c.class_id = e.class_id
                WHERE r.exam_id = ?
                ORDER BY u.first_name
                """;

        List<ExamResult> results = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, examId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    results.add(mapResult(resultSet));
                }
            }
        }

        return results;
    }

    public List<ExamResult> findByStudent(int studentId) throws SQLException {
        String sql = """
                SELECT r.result_id, r.exam_id, r.marks_obtained, r.grade, r.remarks,
                       r.entered_by, r.entered_at,
                       u.first_name, u.last_name,
                       e.exam_name, e.max_marks, c.subject, c.batch,
                       CASE WHEN EXISTS (
                           SELECT 1 FROM dbo.exam_mcq_submissions s
                           WHERE s.exam_id = e.exam_id AND s.student_id = r.student_id
                       ) OR EXISTS (
                           SELECT 1 FROM dbo.exam_mcq_questions q
                           WHERE q.exam_id = e.exam_id
                       ) THEN 1 ELSE 0 END AS is_mcq
                FROM dbo.exam_results r
                JOIN dbo.users u ON u.user_id = r.student_id
                JOIN dbo.exams e ON e.exam_id = r.exam_id
                JOIN dbo.classes c ON c.class_id = e.class_id
                WHERE r.student_id = ?
                ORDER BY e.exam_date DESC
                """;

        List<ExamResult> results = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, studentId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    results.add(mapResult(resultSet));
                }
            }
        }

        return results;
    }

    public ExamResult findByExamAndStudent(int examId, int studentId) throws SQLException {
        String sql = """
                SELECT r.result_id, r.exam_id, r.marks_obtained, r.grade, r.remarks,
                       r.entered_by, r.entered_at,
                       u.first_name, u.last_name,
                       e.exam_name, e.max_marks, c.subject, c.batch,
                       CASE WHEN EXISTS (
                           SELECT 1 FROM dbo.exam_mcq_submissions s
                           WHERE s.exam_id = e.exam_id AND s.student_id = r.student_id
                       ) OR EXISTS (
                           SELECT 1 FROM dbo.exam_mcq_questions q
                           WHERE q.exam_id = e.exam_id
                       ) THEN 1 ELSE 0 END AS is_mcq
                FROM dbo.exam_results r
                JOIN dbo.users u ON u.user_id = r.student_id
                JOIN dbo.exams e ON e.exam_id = r.exam_id
                JOIN dbo.classes c ON c.class_id = e.class_id
                WHERE r.exam_id = ? AND r.student_id = ?
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, examId);
            statement.setInt(2, studentId);

            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return mapResult(resultSet);
                }
            }
        }

        return null;
    }

    private ExamResult mapResult(ResultSet resultSet) throws SQLException {
        ExamResult result = new ExamResult();
        result.setResultId(resultSet.getInt("result_id"));
        result.setExamId(resultSet.getInt("exam_id"));
        result.setMarksObtained(resultSet.getBigDecimal("marks_obtained"));
        result.setGrade(resultSet.getString("grade"));
        result.setRemarks(resultSet.getString("remarks"));
        result.setEnteredBy(resultSet.getInt("entered_by"));
        result.setEnteredAt(resultSet.getTimestamp("entered_at"));
        result.setStudentName(resultSet.getString("first_name") + " " + resultSet.getString("last_name"));
        result.setExamName(resultSet.getString("exam_name"));
        result.setMaxMarks(resultSet.getBigDecimal("max_marks"));
        result.setSubject(resultSet.getString("subject"));
        result.setBatch(resultSet.getString("batch"));
        try {
            result.setMcqQuiz(resultSet.getInt("is_mcq") == 1);
        } catch (SQLException ignored) {
        }
        return result;
    }

    public boolean deleteResult(int resultId) throws SQLException {
        String sql = "DELETE FROM dbo.exam_results WHERE result_id = ?";
        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, resultId);
            return statement.executeUpdate() > 0;
        }
    }
}