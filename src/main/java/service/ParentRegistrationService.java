package service;

import dao.ParentStudentDAO;
import dao.UserDAO;
import model.User;
import util.DBUtil;
import util.PasswordUtil;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Set;
import java.util.regex.Pattern;

public class ParentRegistrationService {

    private final UserDAO userDAO = new UserDAO();
    private final ParentStudentDAO parentStudentDAO = new ParentStudentDAO();

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$");

    private static final Set<String> RELATIONSHIPS =
            Set.of("MOTHER", "FATHER", "GUARDIAN");

    public String registerParent(
            String firstName,
            String lastName,
            String email,
            String phone,
            String childEmail,
            String relationship,
            String password,
            String confirmPassword
    ) throws SQLException {

        firstName = normalize(firstName);
        lastName = normalize(lastName);
        email = normalizeEmail(email);
        phone = normalize(phone);
        childEmail = normalizeEmail(childEmail);
        relationship = normalize(relationship).toUpperCase();

        if (firstName.isEmpty()) return "Parent first name is required.";
        if (lastName.isEmpty()) return "Parent last name is required.";
        if (email.isEmpty()) return "Parent email is required.";
        if (!EMAIL_PATTERN.matcher(email).matches()) return "Please enter a valid parent email address.";
        if (childEmail.isEmpty()) return "Child's student email is required.";
        if (!EMAIL_PATTERN.matcher(childEmail).matches()) return "Please enter a valid child email address.";
        if (!RELATIONSHIPS.contains(relationship)) return "Please select a valid relationship.";
        if (password == null || password.isBlank()) return "Password is required.";
        if (password.length() < 8) return "Password must contain at least 8 characters.";
        if (!password.equals(confirmPassword)) return "Passwords do not match.";
        if (email.equals(childEmail)) return "Parent email and child email cannot be the same.";

        try (Connection connection = DBUtil.getConnection()) {
            connection.setAutoCommit(false);

            try {
                if (userDAO.emailExists(connection, email)) {
                    connection.rollback();
                    return "An account already exists with this parent email.";
                }

                User student = userDAO.findActiveStudentByEmail(connection, childEmail);

                if (student == null) {
                    connection.rollback();
                    return "No active student account was found with that child email.";
                }

                User parent = new User(
                        firstName,
                        lastName,
                        email,
                        phone.isEmpty() ? null : phone,
                        PasswordUtil.hashPassword(password),
                        "PARENT"
                );
                parent.setStatus("ACTIVE");

                int parentId = userDAO.registerUser(connection, parent);

                if (parentId <= 0) {
                    connection.rollback();
                    return "Parent account could not be created.";
                }

                boolean linked = parentStudentDAO.createPendingLink(
                        connection,
                        parentId,
                        student.getUserId(),
                        relationship
                );

                if (!linked) {
                    connection.rollback();
                    return "Parent account could not be linked to the student.";
                }

                connection.commit();
                return null;

            } catch (SQLException e) {
                connection.rollback();
                throw e;
            } catch (RuntimeException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim();
    }

    private String normalizeEmail(String value) {
        return normalize(value).toLowerCase();
    }
}
