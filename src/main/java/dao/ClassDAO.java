package dao;

import model.Class;
import util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class ClassDAO {

    public int createClass(Class classItem) throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            return createClass(connection, classItem);
        }
    }

    public int createClass(Connection connection, Class classItem) throws SQLException {
        String sql = """
                INSERT INTO dbo.classes (subject, batch, tutor_id, fee, status, image_path, class_type)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """;

        try (PreparedStatement statement =
                     connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            statement.setString(1, classItem.getSubject());
            statement.setString(2, classItem.getBatch());

            if (classItem.getTutorId() != null) {
                statement.setInt(3, classItem.getTutorId());
            } else {
                statement.setNull(3, java.sql.Types.INTEGER);
            }

            statement.setBigDecimal(4, classItem.getFee());
            statement.setString(5, classItem.getStatus());
            statement.setString(6, classItem.getImagePath());
            statement.setString(7, classItem.getClassType() != null ? classItem.getClassType() : "WEEKDAY");

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

    public boolean updateClass(Class classItem) throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            return updateClass(connection, classItem);
        }
    }

    public boolean updateClass(Connection connection, Class classItem) throws SQLException {
        String sql = """
                UPDATE dbo.classes
                SET subject = ?, batch = ?, tutor_id = ?, fee = ?, status = ?,
                    image_path = COALESCE(?, image_path),
                    class_type = ?,
                    updated_at = GETDATE()
                WHERE class_id = ?
                """;

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, classItem.getSubject());
            statement.setString(2, classItem.getBatch());

            if (classItem.getTutorId() != null) {
                statement.setInt(3, classItem.getTutorId());
            } else {
                statement.setNull(3, java.sql.Types.INTEGER);
            }

            statement.setBigDecimal(4, classItem.getFee());
            statement.setString(5, classItem.getStatus());
            statement.setString(6, classItem.getImagePath());
            statement.setString(7, classItem.getClassType() != null ? classItem.getClassType() : "WEEKDAY");
            statement.setInt(8, classItem.getClassId());

            return statement.executeUpdate() > 0;
        }
    }

    public boolean discontinueClass(int classId) throws SQLException {
        return deleteClass(classId) == null;
    }

    public String deleteClass(int classId) throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            connection.setAutoCommit(false);
            try {
                // Hard delete related records across all dependent tables
                String[] deletes = {
                        // 1. Delete payments related to invoices for enrollments in this class
                        """
                        DELETE p FROM dbo.payments p
                        JOIN dbo.invoices i ON i.invoice_id = p.invoice_id
                        JOIN dbo.enrollments e ON e.enrollment_id = i.enrollment_id
                        WHERE e.class_id = ?
                        """,
                        // 2. Delete attendance records for this class
                        "DELETE FROM dbo.attendance WHERE class_id = ?",
                        // 3. Delete exam results for exams in this class
                        "DELETE r FROM dbo.exam_results r JOIN dbo.exams x ON x.exam_id = r.exam_id WHERE x.class_id = ?",
                        // 4. Delete exams in this class
                        "DELETE FROM dbo.exams WHERE class_id = ?",
                        // 5. Delete class materials
                        "DELETE FROM dbo.class_materials WHERE class_id = ?",
                        // 6. Delete timetable slots
                        "DELETE FROM dbo.timetable_slots WHERE class_id = ?",
                        // 7. Delete notifications referencing this class
                        "DELETE FROM dbo.notifications WHERE class_id = ?",
                        // 8. Delete invoices for enrollments in this class
                        "DELETE i FROM dbo.invoices i JOIN dbo.enrollments e ON e.enrollment_id = i.enrollment_id WHERE e.class_id = ?",
                        // 9. Delete enrollments in this class
                        "DELETE FROM dbo.enrollments WHERE class_id = ?",
                        // 10. Delete the class itself permanently
                        "DELETE FROM dbo.classes WHERE class_id = ?"
                };

                for (String sql : deletes) {
                    try (PreparedStatement ps = connection.prepareStatement(sql)) {
                        ps.setInt(1, classId);
                        ps.executeUpdate();
                    }
                }

                connection.commit();
                return null;
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }

    public Class findById(Connection connection, int classId) throws SQLException {
        String sql = """
                SELECT c.class_id, c.subject, c.batch, c.tutor_id, c.fee, c.status, c.image_path, c.class_type, c.meeting_link,
                       u.first_name, u.last_name
                FROM dbo.classes c
                LEFT JOIN dbo.users u ON u.user_id = c.tutor_id
                WHERE c.class_id = ?
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, classId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? mapClass(resultSet) : null;
            }
        }
    }

    public Class findById(int classId) throws SQLException {
        String sql = """
                SELECT c.class_id, c.subject, c.batch, c.tutor_id, c.fee, c.status, c.image_path, c.class_type, c.meeting_link,
                       u.first_name, u.last_name
                FROM dbo.classes c
                LEFT JOIN dbo.users u ON u.user_id = c.tutor_id
                WHERE c.class_id = ?
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, classId);

            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return mapClass(resultSet);
                }
            }
        }

        return null;
    }

    public List<Class> findAll() throws SQLException {
        return search(null, null, null, null);
    }

    public List<Class> search(String subject, String tutorName, String batch) throws SQLException {
        return search(subject, tutorName, batch, null);
    }

    /**
     * Search/filter the class catalogue by subject, tutor name, batch and classType.
     * Any parameter can be null/blank to skip that filter.
     */
    public List<Class> search(String subject, String tutorName, String batch, String classType) throws SQLException {
        StringBuilder sql = new StringBuilder("""
                SELECT c.class_id, c.subject, c.batch, c.tutor_id, c.fee, c.status, c.image_path, c.class_type, c.meeting_link,
                       u.first_name, u.last_name
                FROM dbo.classes c
                LEFT JOIN dbo.users u ON u.user_id = c.tutor_id
                WHERE c.status = 'ACTIVE'
                """);

        List<Object> params = new ArrayList<>();

        if (subject != null && !subject.isBlank()) {
            sql.append(" AND c.subject LIKE ? ");
            params.add("%" + subject.trim() + "%");
        }

        if (tutorName != null && !tutorName.isBlank()) {
            sql.append(" AND (u.first_name LIKE ? OR u.last_name LIKE ?) ");
            params.add("%" + tutorName.trim() + "%");
            params.add("%" + tutorName.trim() + "%");
        }

        if (batch != null && !batch.isBlank()) {
            sql.append(" AND c.batch LIKE ? ");
            params.add("%" + batch.trim() + "%");
        }

        if (classType != null && !classType.isBlank() && !"ALL".equalsIgnoreCase(classType.trim())) {
            sql.append(" AND c.class_type = ? ");
            params.add(classType.trim().toUpperCase());
        }

        sql.append(" ORDER BY c.subject, c.batch ");

        List<Class> classes = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql.toString())) {

            for (int i = 0; i < params.size(); i++) {
                statement.setObject(i + 1, params.get(i));
            }

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    classes.add(mapClass(resultSet));
                }
            }
        }

        return classes;
    }

    public List<Class> findByTutor(int tutorId) throws SQLException {
        String sql = """
                SELECT c.class_id, c.subject, c.batch, c.tutor_id, c.fee, c.status, c.image_path, c.class_type, c.meeting_link,
                       u.first_name, u.last_name
                FROM dbo.classes c
                LEFT JOIN dbo.users u ON u.user_id = c.tutor_id
                WHERE c.tutor_id = ? AND c.status = 'ACTIVE'
                ORDER BY c.subject
                """;

        List<Class> classes = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, tutorId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    classes.add(mapClass(resultSet));
                }
            }
        }

        return classes;
    }

    public boolean updateMeetingLink(int classId, int tutorId, String meetingLink) throws SQLException {
        String sql = """
                UPDATE dbo.classes
                SET meeting_link = ?,
                    updated_at = GETDATE()
                WHERE class_id = ? AND tutor_id = ?
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            if (meetingLink != null && !meetingLink.isBlank()) {
                statement.setString(1, meetingLink.trim());
            } else {
                statement.setNull(1, java.sql.Types.VARCHAR);
            }

            statement.setInt(2, classId);
            statement.setInt(3, tutorId);

            return statement.executeUpdate() > 0;
        }
    }

    private Class mapClass(ResultSet resultSet) throws SQLException {
        Class classItem = new Class();
        classItem.setClassId(resultSet.getInt("class_id"));
        classItem.setSubject(resultSet.getString("subject"));
        classItem.setBatch(resultSet.getString("batch"));

        int tutorId = resultSet.getInt("tutor_id");
        if (!resultSet.wasNull()) {
            classItem.setTutorId(tutorId);

            String firstName = resultSet.getString("first_name");
            String lastName = resultSet.getString("last_name");

            if (firstName != null) {
                classItem.setTutorName(firstName + " " + lastName);
            }
        }

        classItem.setFee(resultSet.getBigDecimal("fee"));
        classItem.setStatus(resultSet.getString("status"));
        classItem.setImagePath(resultSet.getString("image_path"));
        String classType = resultSet.getString("class_type");
        classItem.setClassType(classType != null && !classType.isBlank() ? classType : "WEEKDAY");
        classItem.setMeetingLink(resultSet.getString("meeting_link"));
        return classItem;
    }
}