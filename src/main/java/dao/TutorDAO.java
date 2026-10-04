package dao;

import model.TutorProfile;
import util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class TutorDAO {

    public int createProfile(TutorProfile profile) throws SQLException {
        String sql = """
                INSERT INTO dbo.tutor_profiles (user_id, specialization, bio)
                VALUES (?, ?, ?)
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement =
                     connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            statement.setInt(1, profile.getUserId());
            statement.setString(2, profile.getSpecialization());
            statement.setString(3, profile.getBio());

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

    public boolean updateProfile(TutorProfile profile) throws SQLException {
        String sql = """
                UPDATE dbo.tutor_profiles
                SET specialization = ?, bio = ?
                WHERE user_id = ?
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setString(1, profile.getSpecialization());
            statement.setString(2, profile.getBio());
            statement.setInt(3, profile.getUserId());

            return statement.executeUpdate() > 0;
        }
    }

    public TutorProfile findByUserId(int userId) throws SQLException {
        String sql = """
                SELECT t.tutor_profile_id, t.user_id, t.specialization, t.bio,
                       u.first_name, u.last_name, u.email, u.phone, u.status
                FROM dbo.tutor_profiles t
                JOIN dbo.users u ON u.user_id = t.user_id
                WHERE t.user_id = ?
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, userId);

            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return mapProfile(resultSet);
                }
            }
        }

        return null;
    }

    public List<TutorProfile> findAll() throws SQLException {
        String sql = """
                SELECT t.tutor_profile_id, t.user_id, t.specialization, t.bio,
                       u.first_name, u.last_name, u.email, u.phone, u.status
                FROM dbo.tutor_profiles t
                JOIN dbo.users u ON u.user_id = t.user_id
                ORDER BY u.first_name
                """;

        List<TutorProfile> profiles = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement();
             ResultSet resultSet = statement.executeQuery(sql)) {

            while (resultSet.next()) {
                profiles.add(mapProfile(resultSet));
            }
        }

        return profiles;
    }

    public List<TutorProfile> findActiveTutors() throws SQLException {
        String sql = """
                SELECT t.tutor_profile_id, t.user_id, t.specialization, t.bio,
                       u.first_name, u.last_name, u.email, u.phone, u.status
                FROM dbo.tutor_profiles t
                JOIN dbo.users u ON u.user_id = t.user_id
                WHERE u.status = 'ACTIVE'
                ORDER BY u.first_name
                """;

        List<TutorProfile> profiles = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement();
             ResultSet resultSet = statement.executeQuery(sql)) {

            while (resultSet.next()) {
                profiles.add(mapProfile(resultSet));
            }
        }

        return profiles;
    }

    /**
     * Tutor users that don't yet have a tutor_profiles row (needed when
     * an admin creates a TUTOR user account before filling in the profile).
     */
    public List<model.User> findTutorUsersWithoutProfile() throws SQLException {
        String sql = """
                SELECT u.user_id, u.first_name, u.last_name, u.email, u.phone, u.password, u.role, u.status
                FROM dbo.users u
                LEFT JOIN dbo.tutor_profiles t ON t.user_id = u.user_id
                WHERE u.role = 'TUTOR' AND u.status = 'ACTIVE' AND t.tutor_profile_id IS NULL
                ORDER BY u.first_name
                """;

        List<model.User> users = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement();
             ResultSet resultSet = statement.executeQuery(sql)) {

            while (resultSet.next()) {
                model.User user = new model.User();
                user.setUserId(resultSet.getInt("user_id"));
                user.setFirstName(resultSet.getString("first_name"));
                user.setLastName(resultSet.getString("last_name"));
                user.setEmail(resultSet.getString("email"));
                user.setPhone(resultSet.getString("phone"));
                user.setRole(resultSet.getString("role"));
                user.setStatus(resultSet.getString("status"));
                users.add(user);
            }
        }

        return users;
    }

    private TutorProfile mapProfile(ResultSet resultSet) throws SQLException {
        TutorProfile profile = new TutorProfile();
        profile.setTutorProfileId(resultSet.getInt("tutor_profile_id"));
        profile.setUserId(resultSet.getInt("user_id"));
        profile.setSpecialization(resultSet.getString("specialization"));
        profile.setBio(resultSet.getString("bio"));
        profile.setFirstName(resultSet.getString("first_name"));
        profile.setLastName(resultSet.getString("last_name"));
        profile.setEmail(resultSet.getString("email"));
        try {
            profile.setPhone(resultSet.getString("phone"));
        } catch (SQLException ignored) {}
        try {
            profile.setStatus(resultSet.getString("status"));
        } catch (SQLException ignored) {}
        return profile;
    }

    public boolean deleteTutor(int tutorUserId) throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            connection.setAutoCommit(false);
            try {
                // 1. Verify user exists and has role 'TUTOR'
                String checkUser = "SELECT role FROM dbo.users WHERE user_id = ?";
                try (PreparedStatement ps = connection.prepareStatement(checkUser)) {
                    ps.setInt(1, tutorUserId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next() || !"TUTOR".equalsIgnoreCase(rs.getString("role"))) {
                            connection.rollback();
                            return false;
                        }
                    }
                }

                // 2. Find an admin user id for reassigning audit records
                int fallbackAdminId = -1;
                String findAdmin = "SELECT TOP 1 user_id FROM dbo.users WHERE role = 'ADMIN' ORDER BY user_id";
                try (PreparedStatement ps = connection.prepareStatement(findAdmin);
                     ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        fallbackAdminId = rs.getInt("user_id");
                    }
                }

                // 3. Unassign classes assigned to this tutor
                String unassignClasses = "UPDATE dbo.classes SET tutor_id = NULL WHERE tutor_id = ?";
                try (PreparedStatement ps = connection.prepareStatement(unassignClasses)) {
                    ps.setInt(1, tutorUserId);
                    ps.executeUpdate();
                }

                // 4. Delete timetable slots assigned to this tutor
                String deleteSlots = "DELETE FROM dbo.timetable_slots WHERE tutor_id = ?";
                try (PreparedStatement ps = connection.prepareStatement(deleteSlots)) {
                    ps.setInt(1, tutorUserId);
                    ps.executeUpdate();
                }

                // 5. Reassign attendance marked by this tutor
                if (fallbackAdminId > 0) {
                    String reassignAttendance = "UPDATE dbo.attendance SET marked_by = ? WHERE marked_by = ?";
                    try (PreparedStatement ps = connection.prepareStatement(reassignAttendance)) {
                        ps.setInt(1, fallbackAdminId);
                        ps.setInt(2, tutorUserId);
                        ps.executeUpdate();
                    }

                    // 6. Reassign exam marks entered by this tutor
                    String reassignExamResults = "UPDATE dbo.exam_results SET entered_by = ? WHERE entered_by = ?";
                    try (PreparedStatement ps = connection.prepareStatement(reassignExamResults)) {
                        ps.setInt(1, fallbackAdminId);
                        ps.setInt(2, tutorUserId);
                        ps.executeUpdate();
                    }

                    // 6b. Reassign exams created by this tutor
                    String reassignExams = "UPDATE dbo.exams SET created_by = ? WHERE created_by = ?";
                    try (PreparedStatement ps = connection.prepareStatement(reassignExams)) {
                        ps.setInt(1, fallbackAdminId);
                        ps.setInt(2, tutorUserId);
                        ps.executeUpdate();
                    }

                    // 6c. Reassign invoices created by this tutor (if any)
                    String reassignInvoices = "UPDATE dbo.invoices SET created_by = ? WHERE created_by = ?";
                    try (PreparedStatement ps = connection.prepareStatement(reassignInvoices)) {
                        ps.setInt(1, fallbackAdminId);
                        ps.setInt(2, tutorUserId);
                        ps.executeUpdate();
                    }

                    // 6d. Reassign payments received/confirmed/approved by this tutor (if any)
                    String reassignPayments = "UPDATE dbo.payments SET received_by = CASE WHEN received_by = ? THEN ? ELSE received_by END, " +
                            "confirmed_by = CASE WHEN confirmed_by = ? THEN ? ELSE confirmed_by END, " +
                            "approved_by = CASE WHEN approved_by = ? THEN ? ELSE approved_by END " +
                            "WHERE received_by = ? OR confirmed_by = ? OR approved_by = ?";
                    try (PreparedStatement ps = connection.prepareStatement(reassignPayments)) {
                        ps.setInt(1, tutorUserId);
                        ps.setInt(2, fallbackAdminId);
                        ps.setInt(3, tutorUserId);
                        ps.setInt(4, fallbackAdminId);
                        ps.setInt(5, tutorUserId);
                        ps.setInt(6, fallbackAdminId);
                        ps.setInt(7, tutorUserId);
                        ps.setInt(8, tutorUserId);
                        ps.setInt(9, tutorUserId);
                        ps.executeUpdate();
                    }
                }

                // 7. Clear notifications
                String deleteNotices = "DELETE FROM dbo.notifications WHERE recipient_id = ?";
                try (PreparedStatement ps = connection.prepareStatement(deleteNotices)) {
                    ps.setInt(1, tutorUserId);
                    ps.executeUpdate();
                }

                String unlinkNotices = "UPDATE dbo.notifications SET created_by = NULL WHERE created_by = ?";
                try (PreparedStatement ps = connection.prepareStatement(unlinkNotices)) {
                    ps.setInt(1, tutorUserId);
                    ps.executeUpdate();
                }

                // 8. Delete tutor profile
                String deleteProfile = "DELETE FROM dbo.tutor_profiles WHERE user_id = ?";
                try (PreparedStatement ps = connection.prepareStatement(deleteProfile)) {
                    ps.setInt(1, tutorUserId);
                    ps.executeUpdate();
                }

                // 9. Delete user record
                int rows;
                String deleteUser = "DELETE FROM dbo.users WHERE user_id = ? AND role = 'TUTOR'";
                try (PreparedStatement ps = connection.prepareStatement(deleteUser)) {
                    ps.setInt(1, tutorUserId);
                    rows = ps.executeUpdate();
                }

                connection.commit();
                return rows > 0;
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }
}