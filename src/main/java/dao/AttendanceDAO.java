package dao;

import model.Attendance;
import util.DBUtil;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class AttendanceDAO {

    /**
     * All students enrolled in the classItem, each paired with their attendance
     * record for the given date if one exists (status/attendanceId null/0 otherwise).
     */
    public List<Attendance> getRoster(int classId, Date sessionDate) throws SQLException {
        String sql = """
                SELECT e.student_id, u.first_name, u.last_name,
                       a.attendance_id, a.status, a.remarks, a.marked_by, a.marked_at
                FROM dbo.enrollments e
                JOIN dbo.users u ON u.user_id = e.student_id
                LEFT JOIN dbo.attendance a
                       ON a.class_id = e.class_id
                      AND a.student_id = e.student_id
                      AND a.session_date = ?
                WHERE e.class_id = ? AND e.status = 'ACTIVE'
                ORDER BY u.first_name
                """;

        List<Attendance> roster = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setDate(1, sessionDate);
            statement.setInt(2, classId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    Attendance attendance = new Attendance();
                    attendance.setClassId(classId);
                    attendance.setSessionDate(sessionDate);
                    attendance.setStudentId(resultSet.getInt("student_id"));
                    attendance.setStudentName(
                            resultSet.getString("first_name") + " " + resultSet.getString("last_name")
                    );
                    attendance.setAttendanceId(resultSet.getInt("attendance_id")); // 0 if null
                    attendance.setStatus(resultSet.getString("status"));
                    attendance.setRemarks(resultSet.getString("remarks"));

                    roster.add(attendance);
                }
            }
        }

        return roster;
    }

    /**
     * Insert or update the attendance record for one student/class/date (upsert).
     */
    public boolean upsert(int classId, int studentId, Date sessionDate,
                          String status, String remarks, int markedBy) throws SQLException {

        String updateSql = """
                UPDATE dbo.attendance
                SET status = ?, remarks = ?, marked_by = ?, marked_at = GETDATE()
                WHERE class_id = ? AND student_id = ? AND session_date = ?
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement updateStatement = connection.prepareStatement(updateSql)) {

            updateStatement.setString(1, status);
            updateStatement.setString(2, remarks);
            updateStatement.setInt(3, markedBy);
            updateStatement.setInt(4, classId);
            updateStatement.setInt(5, studentId);
            updateStatement.setDate(6, sessionDate);

            int updatedRows = updateStatement.executeUpdate();

            if (updatedRows > 0) {
                return true;
            }

            String insertSql = """
                    INSERT INTO dbo.attendance (class_id, student_id, session_date, status, remarks, marked_by)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """;

            try (PreparedStatement insertStatement =
                         connection.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {

                insertStatement.setInt(1, classId);
                insertStatement.setInt(2, studentId);
                insertStatement.setDate(3, sessionDate);
                insertStatement.setString(4, status);
                insertStatement.setString(5, remarks);
                insertStatement.setInt(6, markedBy);

                return insertStatement.executeUpdate() > 0;
            }
        }
    }

    public List<Attendance> findHistoryByClass(int classId) throws SQLException {
        String sql = """
                SELECT a.attendance_id, a.class_id, a.student_id, a.session_date,
                       a.status, a.remarks, a.marked_by, a.marked_at,
                       u.first_name, u.last_name, c.subject, c.batch
                FROM dbo.attendance a
                JOIN dbo.users u ON u.user_id = a.student_id
                JOIN dbo.classes c ON c.class_id = a.class_id
                WHERE a.class_id = ?
                ORDER BY a.session_date DESC, u.first_name
                """;

        List<Attendance> history = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, classId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    history.add(mapAttendance(resultSet));
                }
            }
        }

        return history;
    }

    public List<Attendance> findHistoryByStudent(int studentId) throws SQLException {
        String sql = """
                SELECT a.attendance_id, a.class_id, a.student_id, a.session_date,
                       a.status, a.remarks, a.marked_by, a.marked_at,
                       u.first_name, u.last_name, c.subject, c.batch
                FROM dbo.attendance a
                JOIN dbo.users u ON u.user_id = a.student_id
                JOIN dbo.classes c ON c.class_id = a.class_id
                WHERE a.student_id = ?
                ORDER BY a.session_date DESC
                """;

        List<Attendance> history = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, studentId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    history.add(mapAttendance(resultSet));
                }
            }
        }

        return history;
    }

    private Attendance mapAttendance(ResultSet resultSet) throws SQLException {
        Attendance attendance = new Attendance();
        attendance.setAttendanceId(resultSet.getInt("attendance_id"));
        attendance.setClassId(resultSet.getInt("class_id"));
        attendance.setStudentId(resultSet.getInt("student_id"));
        attendance.setSessionDate(resultSet.getDate("session_date"));
        attendance.setStatus(resultSet.getString("status"));
        attendance.setRemarks(resultSet.getString("remarks"));
        attendance.setMarkedBy(resultSet.getInt("marked_by"));
        attendance.setMarkedAt(resultSet.getTimestamp("marked_at"));
        attendance.setStudentName(
                resultSet.getString("first_name") + " " + resultSet.getString("last_name")
        );
        attendance.setSubject(resultSet.getString("subject"));
        attendance.setBatch(resultSet.getString("batch"));
        return attendance;
    }

    public boolean deleteAttendance(int attendanceId) throws SQLException {
        String sql = "DELETE FROM dbo.attendance WHERE attendance_id = ?";
        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, attendanceId);
            return statement.executeUpdate() > 0;
        }
    }
}