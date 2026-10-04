package service;

import dao.EnrollmentDAO;
import dao.NotificationDAO;
import dao.ParentStudentDAO;
import dao.UserDAO;
import model.Enrollment;
import model.Notification;

import java.sql.SQLException;
import java.util.List;
import java.util.Set;

public class NotificationService {

    private final NotificationDAO notificationDAO = new NotificationDAO();
    private final ParentStudentDAO parentStudentDAO = new ParentStudentDAO();
    private final EnrollmentDAO enrollmentDAO = new EnrollmentDAO();
    private final UserDAO userDAO = new UserDAO();

    private static final Set<String> VALID_TYPES =
            Set.of("ATTENDANCE", "FEE", "RESULT", "ANNOUNCEMENT", "GENERAL", "PAYMENT", "ENROLLMENT");

    /**
     * Sends a single notification to one user. createdBy is null for system-generated
     * notifications (attendance/fee/result triggers), or the sender's user ID for
     * manually created announcements.
     */
    public void notifyUser(int recipientId, String title, String message, String type,
                           Integer classId, Integer createdBy) throws SQLException {

        String safeType = VALID_TYPES.contains(type) ? type : "GENERAL";
        notificationDAO.insert(recipientId, title, message, safeType, classId, createdBy);
    }

    /**
     * Notifies a student and, if linked, their active parent(s). Used by the
     * Attendance, Fee and Result modules' trigger points — system-generated,
     * so createdBy is always null here.
     */
    public void notifyStudentAndParents(int studentId, String title, String message,
                                        String type, Integer classId) throws SQLException {

        notifyUser(studentId, title, message, type, classId, null);

        List<Integer> parentIds = parentStudentDAO.findActiveParentIdsForStudent(studentId);

        for (Integer parentId : parentIds) {
            notifyUser(parentId, title, message, type, classId, null);
        }
    }

    public void notifyStaff(String title, String message, String type, Integer classId) throws SQLException {
        // Staff role removed; redirect staff notifications to administrators
        notifyAdmins(title, message, type, classId);
    }

    public void notifyAdmins(String title, String message, String type, Integer classId) throws SQLException {
        List<Integer> adminIds = userDAO.findActiveUserIdsByRole("ADMIN");
        for (Integer adminId : adminIds) {
            notifyUser(adminId, title, message, type, classId, null);
        }
    }

    /**
     * Admin/Tutor sends a manual announcement to every actively enrolled student
     * in a class (and their linked parents). Returns an error message, or null on success.
     */
    public String sendClassAnnouncement(int classId, String title, String message, int senderId) throws SQLException {

        String error = validateAnnouncement(title, message);
        if (error != null) {
            return error;
        }

        List<Enrollment> enrollments = enrollmentDAO.findByClass(classId);

        if (enrollments.isEmpty()) {
            return "This class has no enrolled students to notify.";
        }

        for (Enrollment enrollment : enrollments) {
            notifyUser(enrollment.getStudentId(), title, message, "ANNOUNCEMENT", classId, senderId);

            List<Integer> parentIds = parentStudentDAO.findActiveParentIdsForStudent(enrollment.getStudentId());
            for (Integer parentId : parentIds) {
                notifyUser(parentId, title, message, "ANNOUNCEMENT", classId, senderId);
            }
        }

        return null;
    }

    /**
     * Admin broadcasts to every active user of one role (e.g. all students, all tutors).
     */
    public String sendBroadcast(String role, String title, String message, int senderId) throws SQLException {

        String error = validateAnnouncement(title, message);
        if (error != null) {
            return error;
        }

        List<Integer> recipientIds = userDAO.findActiveUserIdsByRole(role.toUpperCase());

        if (recipientIds.isEmpty()) {
            return "No active users found for that role.";
        }

        for (Integer recipientId : recipientIds) {
            notifyUser(recipientId, title, message, "ANNOUNCEMENT", null, senderId);
        }

        return null;
    }

    public List<Notification> findByUser(int userId, String role) throws SQLException {
        return notificationDAO.findByUser(userId, role);
    }

    public List<Notification> findByRecipient(int recipientId) throws SQLException {
        return notificationDAO.findByRecipient(recipientId);
    }

    public int countUnread(int userId, String role) throws SQLException {
        return notificationDAO.countUnread(userId, role);
    }

    public int countUnread(int recipientId) throws SQLException {
        return notificationDAO.countUnread(recipientId);
    }

    public boolean markRead(int notificationId, int userId, String role) throws SQLException {
        return notificationDAO.markRead(notificationId, userId, role);
    }

    public boolean markRead(int notificationId, int recipientId) throws SQLException {
        return notificationDAO.markRead(notificationId, recipientId);
    }

    public boolean markAllRead(int userId, String role) throws SQLException {
        return notificationDAO.markAllRead(userId, role);
    }

    public boolean markAllRead(int recipientId) throws SQLException {
        return notificationDAO.markAllRead(recipientId);
    }

    public List<Notification> findLogByClass(int classId) throws SQLException {
        return notificationDAO.findByClass(classId);
    }

    public boolean deleteNotification(int notificationId) throws SQLException {
        return notificationDAO.deleteNotification(notificationId);
    }

    public List<Notification> findBySender(int senderId) throws SQLException {
        return notificationDAO.findByCreatedBy(senderId);
    }

    private String validateAnnouncement(String title, String message) {
        if (title == null || title.isBlank()) {
            return "Title is required.";
        }

        if (title.length() > 200) {
            return "Title is too long.";
        }

        if (message == null || message.isBlank()) {
            return "Message is required.";
        }

        if (message.length() > 1000) {
            return "Message is too long (max 1000 characters).";
        }

        return null;
    }
}