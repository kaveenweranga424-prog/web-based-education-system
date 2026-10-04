package service;

import dao.TutorDAO;
import dao.UserDAO;
import model.TutorProfile;
import model.User;
import util.PasswordUtil;

import java.sql.SQLException;
import java.util.List;
import java.util.regex.Pattern;

public class TutorService {

    private final TutorDAO tutorDAO = new TutorDAO();
    private final UserDAO userDAO = new UserDAO();

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$");

    /**
     * Admin creates a new tutor account (user + profile) in one step.
     * Returns an error message, or null on success.
     */
    public String createTutor(String firstName, String lastName, String email, String phone,
                              String temporaryPassword, String specialization, String bio) throws SQLException {

        if (firstName == null || firstName.isBlank()) return "First name is required.";
        if (lastName == null || lastName.isBlank()) return "Last name is required.";
        if (email == null || email.isBlank()) return "Email is required.";

        email = email.trim().toLowerCase();

        if (!EMAIL_PATTERN.matcher(email).matches()) return "Please enter a valid email address.";
        if (userDAO.emailExists(email)) return "An account with this email already exists.";

        if (temporaryPassword == null || temporaryPassword.length() < 8) {
            return "Temporary password must contain at least 8 characters.";
        }

        User user = new User(firstName.trim(), lastName.trim(), email, phone,
                PasswordUtil.hashPassword(temporaryPassword), "TUTOR");
        user.setStatus("ACTIVE");

        boolean created = userDAO.registerUser(user);

        if (!created) {
            return "Failed to create the tutor account. Please try again.";
        }

        User savedUser = userDAO.findByEmail(email);

        TutorProfile profile = new TutorProfile();
        profile.setUserId(savedUser.getUserId());
        profile.setSpecialization(specialization);
        profile.setBio(bio);

        int profileId = tutorDAO.createProfile(profile);

        if (profileId <= 0) {
            return "Tutor account created, but the profile could not be saved.";
        }

        // Send welcome email with temporary password to the tutor's personal email
        util.EmailService.sendTutorCredentials(
                email,
                firstName.trim() + " " + lastName.trim(),
                temporaryPassword,
                null
        );

        return null;
    }

    public String updateProfile(int userId, String specialization, String bio) throws SQLException {
        TutorProfile existing = tutorDAO.findByUserId(userId);

        if (existing == null) {
            return "Tutor profile not found.";
        }

        existing.setSpecialization(specialization);
        existing.setBio(bio);

        boolean updated = tutorDAO.updateProfile(existing);

        if (!updated) {
            return "Failed to update the tutor profile.";
        }

        return null;
    }

    public String updateTutor(int userId, String firstName, String lastName, String email, String phone,
                              String specialization, String bio) throws SQLException {
        if (firstName == null || firstName.isBlank()) return "First name is required.";
        if (lastName == null || lastName.isBlank()) return "Last name is required.";
        if (email == null || email.isBlank()) return "Email is required.";

        email = email.trim().toLowerCase();
        if (!EMAIL_PATTERN.matcher(email).matches()) return "Please enter a valid email address.";

        User existingUser = userDAO.findByEmail(email);
        if (existingUser != null && existingUser.getUserId() != userId) {
            return "An account with this email already exists.";
        }

        userDAO.updateUser(userId, firstName.trim(), lastName.trim(), email, phone != null ? phone.trim() : null);

        TutorProfile profile = tutorDAO.findByUserId(userId);
        if (profile == null) {
            profile = new TutorProfile();
            profile.setUserId(userId);
            profile.setSpecialization(specialization);
            profile.setBio(bio);
            tutorDAO.createProfile(profile);
        } else {
            profile.setSpecialization(specialization);
            profile.setBio(bio);
            tutorDAO.updateProfile(profile);
        }

        return null;
    }

    public TutorProfile findByUserId(int userId) throws SQLException {
        return tutorDAO.findByUserId(userId);
    }

    public List<TutorProfile> findAll() throws SQLException {
        return tutorDAO.findAll();
    }

    public List<TutorProfile> findActiveTutors() throws SQLException {
        return tutorDAO.findActiveTutors();
    }

    public boolean updateTutorStatus(int userId, String status) throws SQLException {
        return userDAO.updateStatus(userId, status);
    }

    public List<User> findTutorUsersWithoutProfile() throws SQLException {
        return tutorDAO.findTutorUsersWithoutProfile();
    }

    public String deleteTutor(int userId) throws SQLException {
        TutorProfile profile = tutorDAO.findByUserId(userId);
        if (profile == null) {
            User user = userDAO.findById(userId);
            if (user == null || !"TUTOR".equalsIgnoreCase(user.getRole())) {
                return "Tutor not found.";
            }
        }
        boolean deleted = tutorDAO.deleteTutor(userId);
        if (!deleted) {
            return "Failed to delete tutor. Please ensure the user is a tutor.";
        }
        return null;
    }
}