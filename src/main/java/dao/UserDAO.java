package dao;

import model.User;
import util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;

public class UserDAO {

    public boolean registerUser(User user) throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            return registerUser(connection, user) > 0;
        }
    }

    public int registerUser(Connection connection, User user) throws SQLException {
        String sql = """
                INSERT INTO dbo.users
                (
                    first_name,
                    last_name,
                    email,
                    phone,
                    password,
                    role,
                    status
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """;

        try (PreparedStatement statement = connection.prepareStatement(
                sql,
                Statement.RETURN_GENERATED_KEYS
        )) {

            statement.setString(1, user.getFirstName());
            statement.setString(2, user.getLastName());
            statement.setString(3, user.getEmail());
            statement.setString(4, user.getPhone());
            statement.setString(5, user.getPassword());
            statement.setString(6, user.getRole());
            statement.setString(7, user.getStatus());

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

    public User findById(int userId) throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            return findById(connection, userId);
        }
    }

    public User findById(Connection connection, int userId) throws SQLException {
        String sql = """
                SELECT user_id, first_name, last_name, email, phone, password, role, status
                FROM dbo.users
                WHERE user_id = ?
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? mapUser(resultSet) : null;
            }
        }
    }

    public User findByEmail(String email) throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            return findByEmail(connection, email);
        }
    }

    public User findByEmail(Connection connection, String email) throws SQLException {
        String sql = """
                SELECT
                    user_id,
                    first_name,
                    last_name,
                    email,
                    phone,
                    password,
                    role,
                    status
                FROM dbo.users
                WHERE email = ?
                """;

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email);

            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return mapUser(resultSet);
                }
            }
        }

        return null;
    }

    public User findActiveStudentByEmail(Connection connection, String email) throws SQLException {
        String sql = """
                SELECT
                    user_id,
                    first_name,
                    last_name,
                    email,
                    phone,
                    password,
                    role,
                    status
                FROM dbo.users
                WHERE email = ?
                  AND role = 'STUDENT'
                  AND status = 'ACTIVE'
                """;

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email);

            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return mapUser(resultSet);
                }
            }
        }

        return null;
    }

    public boolean emailExists(String email) throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            return emailExists(connection, email);
        }
    }

    public boolean emailExists(Connection connection, String email) throws SQLException {
        String sql = """
                SELECT COUNT(*) AS user_count
                FROM dbo.users
                WHERE email = ?
                """;

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email);

            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getInt("user_count") > 0;
                }
            }
        }

        return false;
    }

    private User mapUser(ResultSet resultSet) throws SQLException {
        User user = new User();
        user.setUserId(resultSet.getInt("user_id"));
        user.setFirstName(resultSet.getString("first_name"));
        user.setLastName(resultSet.getString("last_name"));
        user.setEmail(resultSet.getString("email"));
        user.setPhone(resultSet.getString("phone"));
        user.setPassword(resultSet.getString("password"));
        user.setRole(resultSet.getString("role"));
        user.setStatus(resultSet.getString("status"));
        return user;
    }
    public List<Integer> findActiveUserIdsByRole(String role) throws SQLException {
        String sql = "SELECT user_id FROM dbo.users WHERE role = ? AND status = 'ACTIVE'";

        List<Integer> userIds = new java.util.ArrayList<>();

        try (Connection connection = util.DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setString(1, role);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    userIds.add(resultSet.getInt("user_id"));
                }
            }
        }

        return userIds;
    }

    public boolean updateStatus(int userId, String status) throws SQLException {
        String sql = "UPDATE dbo.users SET status = ? WHERE user_id = ?";
        try (Connection connection = util.DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, status);
            statement.setInt(2, userId);
            return statement.executeUpdate() > 0;
        }
    }

    public boolean updateUser(int userId, String firstName, String lastName, String email, String phone) throws SQLException {
        String sql = """
                UPDATE dbo.users
                SET first_name = ?, last_name = ?, email = ?, phone = ?, updated_at = GETDATE()
                WHERE user_id = ?
                """;
        try (Connection connection = util.DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, firstName);
            statement.setString(2, lastName);
            statement.setString(3, email);
            statement.setString(4, phone);
            statement.setInt(5, userId);
            return statement.executeUpdate() > 0;
        }
    }

    public List<User> findByRole(String role) throws SQLException {
        String sql = """
                SELECT user_id, first_name, last_name, email, phone, password, role, status
                FROM dbo.users
                WHERE role = ?
                ORDER BY first_name, last_name
                """;
        List<User> list = new java.util.ArrayList<>();
        try (Connection connection = util.DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, role);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    list.add(mapUser(rs));
                }
            }
        }
        return list;
    }

    public boolean updatePassword(int userId, String hashedPassword) throws SQLException {
        String sql = """
                UPDATE dbo.users
                SET password = ?, updated_at = GETDATE()
                WHERE user_id = ?
                """;
        try (Connection connection = util.DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, hashedPassword);
            statement.setInt(2, userId);
            return statement.executeUpdate() > 0;
        }
    }
}
