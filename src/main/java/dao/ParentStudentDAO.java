package dao;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class ParentStudentDAO {

    public boolean createPendingLink(
            Connection connection,
            int parentUserId,
            int studentUserId,
            String relationship
    ) throws SQLException {

        String sql = """
                INSERT INTO dbo.parent_student
                (
                    parent_user_id,
                    student_user_id,
                    relationship,
                    status
                )
                VALUES (?, ?, ?, 'PENDING')
                """;

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, parentUserId);
            statement.setInt(2, studentUserId);
            statement.setString(3, relationship);
            return statement.executeUpdate() > 0;
        }
    }
    public List<Integer> findActiveStudentIdsForParent(Connection connection, int parentUserId) throws SQLException {
        String sql = """
                SELECT student_user_id
                FROM dbo.parent_student
                WHERE parent_user_id = ? AND status = 'ACTIVE'
                """;

        List<Integer> studentIds = new ArrayList<>();

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, parentUserId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    studentIds.add(resultSet.getInt("student_user_id"));
                }
            }
        }

        return studentIds;
    }

    public List<Integer> findActiveStudentIdsForParent(int parentUserId) throws SQLException {
        try (Connection connection = util.DBUtil.getConnection()) {
            return findActiveStudentIdsForParent(connection, parentUserId);
        }
    }
    public List<Integer> findActiveParentIdsForStudent(int studentUserId) throws SQLException {
        String sql = """
                SELECT parent_user_id
                FROM dbo.parent_student
                WHERE student_user_id = ? AND status = 'ACTIVE'
                """;

        List<Integer> parentIds = new ArrayList<>();

        try (Connection connection = util.DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, studentUserId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    parentIds.add(resultSet.getInt("parent_user_id"));
                }
            }
        }

        return parentIds;
    }

    public List<java.util.Map<String, Object>> findPendingLinks() throws SQLException {
        String sql = """
                SELECT ps.parent_student_id, ps.parent_user_id, ps.student_user_id, ps.relationship, ps.status, ps.created_at,
                       p.first_name AS parent_first, p.last_name AS parent_last, p.email AS parent_email, p.phone AS parent_phone,
                       s.first_name AS student_first, s.last_name AS student_last, s.email AS student_email
                FROM dbo.parent_student ps
                JOIN dbo.users p ON p.user_id = ps.parent_user_id
                JOIN dbo.users s ON s.user_id = ps.student_user_id
                WHERE ps.status = 'PENDING'
                ORDER BY ps.created_at DESC
                """;

        List<java.util.Map<String, Object>> list = new ArrayList<>();
        try (Connection connection = util.DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                java.util.Map<String, Object> map = new java.util.LinkedHashMap<>();
                map.put("parentStudentId", resultSet.getInt("parent_student_id"));
                map.put("parentUserId", resultSet.getInt("parent_user_id"));
                map.put("parentName", resultSet.getString("parent_first") + " " + resultSet.getString("parent_last"));
                map.put("parentEmail", resultSet.getString("parent_email"));
                map.put("parentPhone", resultSet.getString("parent_phone"));
                map.put("studentUserId", resultSet.getInt("student_user_id"));
                map.put("studentName", resultSet.getString("student_first") + " " + resultSet.getString("student_last"));
                map.put("studentEmail", resultSet.getString("student_email"));
                map.put("relationship", resultSet.getString("relationship"));
                map.put("createdAt", resultSet.getTimestamp("created_at"));
                list.add(map);
            }
        }
        return list;
    }

    public boolean updateLinkStatus(int parentStudentId, String status) throws SQLException {
        String sql = "UPDATE dbo.parent_student SET status = ? WHERE parent_student_id = ?";
        try (Connection connection = util.DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, status);
            statement.setInt(2, parentStudentId);
            return statement.executeUpdate() > 0;
        }
    }

    public java.util.Map<String, Object> findLinkById(int parentStudentId) throws SQLException {
        String sql = """
                SELECT ps.parent_student_id, ps.parent_user_id, ps.student_user_id, ps.relationship, ps.status,
                       p.first_name AS parent_first, p.last_name AS parent_last,
                       s.first_name AS student_first, s.last_name AS student_last
                FROM dbo.parent_student ps
                JOIN dbo.users p ON p.user_id = ps.parent_user_id
                JOIN dbo.users s ON s.user_id = ps.student_user_id
                WHERE ps.parent_student_id = ?
                """;
        try (Connection connection = util.DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, parentStudentId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    java.util.Map<String, Object> map = new java.util.LinkedHashMap<>();
                    map.put("parentStudentId", resultSet.getInt("parent_student_id"));
                    map.put("parentUserId", resultSet.getInt("parent_user_id"));
                    map.put("studentUserId", resultSet.getInt("student_user_id"));
                    map.put("relationship", resultSet.getString("relationship"));
                    map.put("status", resultSet.getString("status"));
                    map.put("parentName", resultSet.getString("parent_first") + " " + resultSet.getString("parent_last"));
                    map.put("studentName", resultSet.getString("student_first") + " " + resultSet.getString("student_last"));
                    return map;
                }
            }
        }
        return null;
    }
}
