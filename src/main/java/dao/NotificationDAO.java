package dao;

import model.Notification;
import util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class NotificationDAO {

    public int insert(int recipientId, String title, String message, String type,
                      Integer classId, Integer createdBy) throws SQLException {

        String sql = """
                INSERT INTO dbo.notifications (recipient_id, title, message, type, class_id, created_by)
                VALUES (?, ?, ?, ?, ?, ?)
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement =
                     connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            statement.setInt(1, recipientId);
            statement.setString(2, title);
            statement.setString(3, message);
            statement.setString(4, type);

            if (classId != null) {
                statement.setInt(5, classId);
            } else {
                statement.setNull(5, java.sql.Types.INTEGER);
            }

            if (createdBy != null) {
                statement.setInt(6, createdBy);
            } else {
                statement.setNull(6, java.sql.Types.INTEGER);
            }

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

    public boolean markRead(int notificationId, int userId, String role) throws SQLException {
        if ("ADMIN".equalsIgnoreCase(role)) {
            String sql = "UPDATE dbo.notifications SET is_read = 1 WHERE notification_id = ?";
            try (Connection connection = DBUtil.getConnection();
                 PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setInt(1, notificationId);
                return statement.executeUpdate() > 0;
            }
        } else if ("PARENT".equalsIgnoreCase(role)) {
            String sql = """
                    UPDATE dbo.notifications SET is_read = 1
                    WHERE notification_id = ?
                      AND (
                           recipient_id = ?
                           OR recipient_id IN (
                               SELECT student_user_id FROM dbo.parent_student WHERE parent_user_id = ? AND status = 'ACTIVE'
                           )
                      )
                    """;
            try (Connection connection = DBUtil.getConnection();
                 PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setInt(1, notificationId);
                statement.setInt(2, userId);
                statement.setInt(3, userId);
                return statement.executeUpdate() > 0;
            }
        } else {
            String sql = "UPDATE dbo.notifications SET is_read = 1 WHERE notification_id = ? AND recipient_id = ?";
            try (Connection connection = DBUtil.getConnection();
                 PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setInt(1, notificationId);
                statement.setInt(2, userId);
                return statement.executeUpdate() > 0;
            }
        }
    }

    public boolean markRead(int notificationId, int recipientId) throws SQLException {
        return markRead(notificationId, recipientId, "STUDENT");
    }

    public boolean markAllRead(int userId, String role) throws SQLException {
        if ("ADMIN".equalsIgnoreCase(role)) {
            String sql = "UPDATE dbo.notifications SET is_read = 1 WHERE is_read = 0";
            try (Connection connection = DBUtil.getConnection();
                 PreparedStatement statement = connection.prepareStatement(sql)) {
                return statement.executeUpdate() >= 0;
            }
        } else if ("PARENT".equalsIgnoreCase(role)) {
            String sql = """
                    UPDATE dbo.notifications SET is_read = 1
                    WHERE is_read = 0
                      AND (
                           recipient_id = ?
                           OR recipient_id IN (
                               SELECT student_user_id FROM dbo.parent_student WHERE parent_user_id = ? AND status = 'ACTIVE'
                           )
                      )
                    """;
            try (Connection connection = DBUtil.getConnection();
                 PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setInt(1, userId);
                statement.setInt(2, userId);
                return statement.executeUpdate() >= 0;
            }
        } else {
            String sql = "UPDATE dbo.notifications SET is_read = 1 WHERE recipient_id = ? AND is_read = 0";
            try (Connection connection = DBUtil.getConnection();
                 PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setInt(1, userId);
                return statement.executeUpdate() >= 0;
            }
        }
    }

    public boolean markAllRead(int recipientId) throws SQLException {
        return markAllRead(recipientId, "STUDENT");
    }

    public List<Notification> findByUser(int userId, String role) throws SQLException {
        if ("ADMIN".equalsIgnoreCase(role)) {
            String sql = """
                    SELECT n.notification_id, n.recipient_id, n.title, n.message, n.type,
                           n.class_id, n.is_read, n.created_by, n.created_at,
                           c.subject,
                           u.first_name, u.last_name
                    FROM dbo.notifications n
                    LEFT JOIN dbo.classes c ON c.class_id = n.class_id
                    LEFT JOIN dbo.users u ON u.user_id = n.created_by
                    ORDER BY n.created_at DESC
                    """;
            List<Notification> notifications = new ArrayList<>();
            try (Connection connection = DBUtil.getConnection();
                 PreparedStatement statement = connection.prepareStatement(sql);
                 ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    notifications.add(mapNotification(resultSet));
                }
            }
            return notifications;
        } else if ("PARENT".equalsIgnoreCase(role)) {
            String sql = """
                    SELECT n.notification_id, n.recipient_id, n.title, n.message, n.type,
                           n.class_id, n.is_read, n.created_by, n.created_at,
                           c.subject,
                           u.first_name, u.last_name
                    FROM dbo.notifications n
                    LEFT JOIN dbo.classes c ON c.class_id = n.class_id
                    LEFT JOIN dbo.users u ON u.user_id = n.created_by
                    WHERE n.recipient_id = ?
                       OR n.recipient_id IN (
                           SELECT student_user_id FROM dbo.parent_student WHERE parent_user_id = ? AND status = 'ACTIVE'
                       )
                    ORDER BY n.created_at DESC
                    """;
            List<Notification> notifications = new ArrayList<>();
            try (Connection connection = DBUtil.getConnection();
                 PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setInt(1, userId);
                statement.setInt(2, userId);
                try (ResultSet resultSet = statement.executeQuery()) {
                    while (resultSet.next()) {
                        notifications.add(mapNotification(resultSet));
                    }
                }
            }
            return notifications;
        } else {
            return findByRecipient(userId);
        }
    }

    public List<Notification> findByRecipient(int recipientId) throws SQLException {
        String sql = """
                SELECT n.notification_id, n.recipient_id, n.title, n.message, n.type,
                       n.class_id, n.is_read, n.created_by, n.created_at,
                       c.subject,
                       u.first_name, u.last_name
                FROM dbo.notifications n
                LEFT JOIN dbo.classes c ON c.class_id = n.class_id
                LEFT JOIN dbo.users u ON u.user_id = n.created_by
                WHERE n.recipient_id = ?
                ORDER BY n.created_at DESC
                """;

        List<Notification> notifications = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, recipientId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    notifications.add(mapNotification(resultSet));
                }
            }
        }

        return notifications;
    }

    public int countUnread(int userId, String role) throws SQLException {
        if ("ADMIN".equalsIgnoreCase(role)) {
            String sql = "SELECT COUNT(*) AS cnt FROM dbo.notifications WHERE is_read = 0";
            try (Connection connection = DBUtil.getConnection();
                 PreparedStatement statement = connection.prepareStatement(sql);
                 ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getInt("cnt");
                }
            }
        } else if ("PARENT".equalsIgnoreCase(role)) {
            String sql = """
                    SELECT COUNT(*) AS cnt FROM dbo.notifications
                    WHERE is_read = 0
                      AND (
                           recipient_id = ?
                           OR recipient_id IN (
                               SELECT student_user_id FROM dbo.parent_student WHERE parent_user_id = ? AND status = 'ACTIVE'
                           )
                      )
                    """;
            try (Connection connection = DBUtil.getConnection();
                 PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setInt(1, userId);
                statement.setInt(2, userId);
                try (ResultSet resultSet = statement.executeQuery()) {
                    if (resultSet.next()) {
                        return resultSet.getInt("cnt");
                    }
                }
            }
        } else {
            String sql = "SELECT COUNT(*) AS cnt FROM dbo.notifications WHERE recipient_id = ? AND is_read = 0";
            try (Connection connection = DBUtil.getConnection();
                 PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setInt(1, userId);
                try (ResultSet resultSet = statement.executeQuery()) {
                    if (resultSet.next()) {
                        return resultSet.getInt("cnt");
                    }
                }
            }
        }

        return 0;
    }

    public int countUnread(int recipientId) throws SQLException {
        return countUnread(recipientId, "STUDENT");
    }

    /**
     * Full notification log for a class (admin/tutor oversight of what's been sent).
     */
    public List<Notification> findByClass(int classId) throws SQLException {
        String sql = """
                SELECT n.notification_id, n.recipient_id, n.title, n.message, n.type,
                       n.class_id, n.is_read, n.created_by, n.created_at,
                       c.subject,
                       u.first_name, u.last_name
                FROM dbo.notifications n
                LEFT JOIN dbo.classes c ON c.class_id = n.class_id
                LEFT JOIN dbo.users u ON u.user_id = n.created_by
                WHERE n.class_id = ?
                ORDER BY n.created_at DESC
                """;

        List<Notification> notifications = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, classId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    notifications.add(mapNotification(resultSet));
                }
            }
        }

        return notifications;
    }

    private Notification mapNotification(ResultSet resultSet) throws SQLException {
        Notification notification = new Notification();
        notification.setNotificationId(resultSet.getInt("notification_id"));
        notification.setRecipientId(resultSet.getInt("recipient_id"));
        notification.setTitle(resultSet.getString("title"));
        notification.setMessage(resultSet.getString("message"));
        notification.setType(resultSet.getString("type"));

        int classId = resultSet.getInt("class_id");
        if (!resultSet.wasNull()) {
            notification.setClassId(classId);
            notification.setSubject(resultSet.getString("subject"));
        }

        notification.setRead(resultSet.getBoolean("is_read"));

        int createdBy = resultSet.getInt("created_by");
        if (!resultSet.wasNull()) {
            notification.setCreatedBy(createdBy);
            String firstName = resultSet.getString("first_name");
            if (firstName != null) {
                notification.setCreatedByName(firstName + " " + resultSet.getString("last_name"));
            }
        }

        notification.setCreatedAt(resultSet.getTimestamp("created_at"));
        return notification;
    }

    public boolean deleteNotification(int notificationId) throws SQLException {
        String sql = "DELETE FROM dbo.notifications WHERE notification_id = ?";
        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, notificationId);
            return statement.executeUpdate() > 0;
        }
    }

    public List<Notification> findByCreatedBy(int createdBy) throws SQLException {
        String sql = """
                SELECT n.notification_id, n.recipient_id, n.title, n.message, n.type,
                       n.class_id, n.is_read, n.created_by, n.created_at,
                       c.subject,
                       u.first_name, u.last_name
                FROM dbo.notifications n
                LEFT JOIN dbo.classes c ON c.class_id = n.class_id
                LEFT JOIN dbo.users u ON u.user_id = n.recipient_id
                WHERE n.created_by = ?
                ORDER BY n.created_at DESC
                """;

        List<Notification> notifications = new ArrayList<>();
        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, createdBy);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    Notification n = mapNotification(resultSet);
                    String fName = resultSet.getString("first_name");
                    if (fName != null) {
                        n.setRecipientName(fName + " " + resultSet.getString("last_name"));
                    }
                    notifications.add(n);
                }
            }
        }
        return notifications;
    }
}