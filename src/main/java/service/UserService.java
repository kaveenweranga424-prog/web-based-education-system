package service;

import dao.UserDAO;
import model.User;
import util.PasswordUtil;

import java.sql.SQLException;
import java.util.Set;
import java.util.regex.Pattern;

public class UserService {

    private final UserDAO userDAO;

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile(
                    "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$"
            );

    /*
     * Public registration roles.
     *
     * Admin/Staff/Tutor accounts should normally
     * be created by administration later.
     */
    private static final Set<String>
            PUBLIC_REGISTRATION_ROLES =
            Set.of(
                    "STUDENT"
            );

    public UserService() {

        this.userDAO =
                new UserDAO();
    }


    public String registerUser(
            User user,
            String confirmPassword
    ) throws SQLException {

        /*
         * First name validation
         */
        if (user.getFirstName() == null ||
                user.getFirstName().isBlank()) {

            return "First name is required.";
        }

        if (user.getFirstName().length() > 100) {

            return "First name is too long.";
        }


        /*
         * Last name validation
         */
        if (user.getLastName() == null ||
                user.getLastName().isBlank()) {

            return "Last name is required.";
        }

        if (user.getLastName().length() > 100) {

            return "Last name is too long.";
        }


        /*
         * Email validation
         */
        if (user.getEmail() == null ||
                user.getEmail().isBlank()) {

            return "Email is required.";
        }

        user.setEmail(
                user.getEmail()
                        .trim()
                        .toLowerCase()
        );

        if (!EMAIL_PATTERN
                .matcher(user.getEmail())
                .matches()) {

            return "Please enter a valid email address.";
        }


        /*
         * Duplicate email validation
         */
        if (userDAO.emailExists(
                user.getEmail()
        )) {

            return "An account with this email already exists.";
        }


        /*
         * Password validation
         */
        if (user.getPassword() == null ||
                user.getPassword().isBlank()) {

            return "Password is required.";
        }

        if (user.getPassword().length() < 8) {

            return "Password must contain at least 8 characters.";
        }

        if (!user.getPassword()
                .equals(confirmPassword)) {

            return "Passwords do not match.";
        }


        /*
         * Role validation
         */
        if (user.getRole() == null) {

            return "Please select a role.";
        }

        String role =
                user.getRole()
                        .trim()
                        .toUpperCase();

        if (!PUBLIC_REGISTRATION_ROLES
                .contains(role)) {

            return "Invalid registration role.";
        }

        user.setRole(role);


        /*
         * Hash password
         */
        String hashedPassword =
                PasswordUtil.hashPassword(
                        user.getPassword()
                );

        user.setPassword(
                hashedPassword
        );

        user.setStatus(
                "ACTIVE"
        );


        boolean success =
                userDAO.registerUser(
                        user
                );

        if (!success) {

            return "Registration failed. Please try again.";
        }

        return null;
    }


    /*
     * Login authentication
     */
    public User authenticate(
            String email,
            String password
    ) throws SQLException {

        if (email == null ||
                password == null ||
                email.isBlank() ||
                password.isBlank()) {

            return null;
        }

        email =
                email.trim()
                        .toLowerCase();

        User user =
                userDAO.findByEmail(
                        email
                );

        if (user == null) {

            return null;
        }


        /*
         * Prevent inactive account login
         */
        if (!"ACTIVE".equalsIgnoreCase(
                user.getStatus()
        )) {

            return null;
        }


        /*
         * BCrypt password comparison
         */
        boolean passwordCorrect =
                PasswordUtil.checkPassword(
                        password,
                        user.getPassword()
                );

        if (!passwordCorrect) {

            return null;
        }

        return user;
    }

    /**
     * Changes a user's password after validating current password and new password rules.
     * Returns an error message if validation fails, or null on success.
     */
    public String changePassword(int userId, String currentPassword, String newPassword, String confirmPassword) throws SQLException {
        if (currentPassword == null || currentPassword.isBlank()) {
            return "Current password is required.";
        }
        if (newPassword == null || newPassword.isBlank()) {
            return "New password is required.";
        }
        if (newPassword.length() < 8) {
            return "New password must be at least 8 characters long.";
        }
        if (!newPassword.equals(confirmPassword)) {
            return "New passwords do not match.";
        }

        User user = userDAO.findById(userId);
        if (user == null) {
            return "User not found.";
        }

        if (!PasswordUtil.checkPassword(currentPassword, user.getPassword())) {
            return "Current password is incorrect.";
        }

        if (PasswordUtil.checkPassword(newPassword, user.getPassword())) {
            return "New password cannot be the same as your current password.";
        }

        String hashed = PasswordUtil.hashPassword(newPassword);
        boolean updated = userDAO.updatePassword(userId, hashed);
        if (!updated) {
            return "Failed to update password. Please try again.";
        }

        return null;
    }

    public User findById(int userId) throws SQLException {
        return userDAO.findById(userId);
    }

    public String updateProfile(int userId, String firstName, String lastName, String email, String phone) throws SQLException {
        if (firstName == null || firstName.isBlank()) {
            return "First name is required.";
        }
        if (firstName.trim().length() > 100) {
            return "First name is too long.";
        }
        if (lastName == null || lastName.isBlank()) {
            return "Last name is required.";
        }
        if (lastName.trim().length() > 100) {
            return "Last name is too long.";
        }
        if (email == null || email.isBlank()) {
            return "Email is required.";
        }
        email = email.trim().toLowerCase();
        if (!EMAIL_PATTERN.matcher(email).matches()) {
            return "Please enter a valid email address.";
        }

        User existing = userDAO.findByEmail(email);
        if (existing != null && existing.getUserId() != userId) {
            return "An account with this email address already exists.";
        }

        if (phone != null && phone.trim().length() > 20) {
            return "Phone number is too long (max 20 characters).";
        }

        boolean updated = userDAO.updateUser(userId, firstName.trim(), lastName.trim(), email, phone != null && !phone.isBlank() ? phone.trim() : null);
        if (!updated) {
            return "Failed to update profile. Please try again.";
        }

        return null;
    }
}