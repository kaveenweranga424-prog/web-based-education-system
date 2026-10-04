package dao;

import model.Exam;
import util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class ExamDAO {

    private static final String BASE_SELECT = """
            SELECT e.exam_id, e.class_id, e.exam_name, e.exam_date, e.max_marks,
                   e.status, e.created_by, e.created_at,
                   c.subject, c.batch
            FROM dbo.exams e
            JOIN dbo.classes c ON c.class_id = e.class_id
            """;

    public int createExam(Exam exam) throws SQLException {
        String sql = """
                INSERT INTO dbo.exams (class_id, exam_name, exam_date, max_marks, status, created_by)
                VALUES (?, ?, ?, ?, 'SCHEDULED', ?)
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement =
                     connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            statement.setInt(1, exam.getClassId());
            statement.setString(2, exam.getExamName());
            statement.setDate(3, exam.getExamDate());
            statement.setBigDecimal(4, exam.getMaxMarks());
            statement.setInt(5, exam.getCreatedBy());

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

    public boolean cancelExam(int examId) throws SQLException {
        String sql = "UPDATE dbo.exams SET status = 'CANCELLED' WHERE exam_id = ?";

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, examId);
            return statement.executeUpdate() > 0;
        }
    }

    public boolean markCompleted(int examId) throws SQLException {
        String sql = "UPDATE dbo.exams SET status = 'COMPLETED' WHERE exam_id = ?";

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, examId);
            return statement.executeUpdate() > 0;
        }
    }

    public Exam findById(int examId) throws SQLException {
        String sql = BASE_SELECT + " WHERE e.exam_id = ?";

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, examId);

            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return mapExam(resultSet);
                }
            }
        }

        return null;
    }

    public List<Exam> findAll() throws SQLException {
        String sql = BASE_SELECT + " WHERE e.status <> 'CANCELLED' ORDER BY e.exam_date DESC";

        List<Exam> exams = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement();
             ResultSet resultSet = statement.executeQuery(sql)) {

            while (resultSet.next()) {
                exams.add(mapExam(resultSet));
            }
        }

        return exams;
    }

    public List<Exam> findByClass(int classId) throws SQLException {
        String sql = BASE_SELECT + " WHERE e.class_id = ? AND e.status <> 'CANCELLED' ORDER BY e.exam_date DESC";

        List<Exam> exams = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, classId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    exams.add(mapExam(resultSet));
                }
            }
        }

        return exams;
    }

    public List<Exam> findByTutor(int tutorId) throws SQLException {
        String sql = BASE_SELECT
                + " JOIN dbo.classes cc ON cc.class_id = e.class_id "
                + " WHERE cc.tutor_id = ? AND e.status <> 'CANCELLED' ORDER BY e.exam_date DESC";

        // NOTE: BASE_SELECT already joins classes as "c"; join again as "cc" only for the filter.
        String finalSql = BASE_SELECT + " WHERE c.tutor_id = ? AND e.status <> 'CANCELLED' ORDER BY e.exam_date DESC";

        List<Exam> exams = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(finalSql)) {

            statement.setInt(1, tutorId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    exams.add(mapExam(resultSet));
                }
            }
        }

        return exams;
    }

    private Exam mapExam(ResultSet resultSet) throws SQLException {
        Exam exam = new Exam();
        exam.setExamId(resultSet.getInt("exam_id"));
        exam.setClassId(resultSet.getInt("class_id"));
        exam.setExamName(resultSet.getString("exam_name"));
        exam.setExamDate(resultSet.getDate("exam_date"));
        exam.setMaxMarks(resultSet.getBigDecimal("max_marks"));
        exam.setStatus(resultSet.getString("status"));
        exam.setCreatedBy(resultSet.getInt("created_by"));
        exam.setCreatedAt(resultSet.getTimestamp("created_at"));
        exam.setSubject(resultSet.getString("subject"));
        exam.setBatch(resultSet.getString("batch"));
        return exam;
    }
}