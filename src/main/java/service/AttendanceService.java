package service;

import dao.AttendanceDAO;
import dao.ClassDAO;
import model.Attendance;
import model.Class;

import java.sql.Date;
import java.sql.SQLException;
import java.util.List;
import java.util.Set;
import service.NotificationService;

public class AttendanceService {

    private final AttendanceDAO attendanceDAO = new AttendanceDAO();
    private final ClassDAO classDAO = new ClassDAO();
    private final NotificationService notificationService = new NotificationService();


    private static final Set<String> VALID_STATUS = Set.of("PRESENT", "ABSENT", "LATE");

    public List<Attendance> getRoster(int classId, Date sessionDate) throws SQLException {
        return attendanceDAO.getRoster(classId, sessionDate);
    }

    /**
     * Marks/corrects attendance for one student. Returns an error message, or null on success.
     * markedByUserId must be the tutor assigned to the classItem, or an admin.
     */
    public String markAttendance(int classId, int studentId, Date sessionDate, String status,
                                 String remarks, int markedByUserId, boolean isAdmin) throws SQLException {

        if (status == null || !VALID_STATUS.contains(status.trim().toUpperCase())) {
            return "Invalid attendance status.";
        }

        if (sessionDate == null) {
            return "Session date is required.";
        }

        if (sessionDate.toLocalDate().isAfter(java.time.LocalDate.now())) {
            return "Cannot mark attendance for future dates. Attendance can only be recorded for today or past sessions.";
        }

        Class classItem = classDAO.findById(classId);

        if (classItem == null) {
            return "Class not found.";
        }

        if (!isAdmin && (classItem.getTutorId() == null || classItem.getTutorId() != markedByUserId)) {
            return "You are not assigned to this class.";
        }

        boolean saved = attendanceDAO.upsert(
                classId, studentId, sessionDate, status.trim().toUpperCase(), remarks, markedByUserId
        );

        if (!saved) {
            return "Failed to save attendance. Please try again.";
        }

        if ("ABSENT".equalsIgnoreCase(status.trim())) {
            String title = "Absence recorded";
            String message = classItem.getSubject() + " (" + classItem.getBatch()
                    + ") — marked absent on " + sessionDate + ".";

            notificationService.notifyStudentAndParents(
                    studentId, title, message, "ATTENDANCE", classId
            );
        }

        return null;
    }

    public List<Attendance> getHistoryByClass(int classId) throws SQLException {
        return attendanceDAO.findHistoryByClass(classId);
    }

    public List<Attendance> getHistoryByStudent(int studentId) throws SQLException {
        return attendanceDAO.findHistoryByStudent(studentId);
    }

    public boolean deleteAttendance(int attendanceId) throws SQLException {
        return attendanceDAO.deleteAttendance(attendanceId);
    }
}