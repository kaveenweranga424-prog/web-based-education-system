package observer;

import dao.ClassDAO;
import dao.EnrollmentDAO;
import model.Class;
import model.ClassMaterial;
import model.Enrollment;
import service.NotificationService;

import java.sql.SQLException;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Concrete Observer (Observer Pattern).
 * Listens for new class material uploads and notifies all students
 * actively enrolled in the corresponding class via the existing
 * NotificationService.
 */
public class StudentMaterialObserver implements MaterialObserver {

    private final EnrollmentDAO enrollmentDAO;
    private final NotificationService notificationService;
    private final ClassDAO classDAO;

    public StudentMaterialObserver() {
        this(new EnrollmentDAO(), new NotificationService(), new ClassDAO());
    }

    public StudentMaterialObserver(EnrollmentDAO enrollmentDAO,
                                   NotificationService notificationService,
                                   ClassDAO classDAO) {
        this.enrollmentDAO = enrollmentDAO;
        this.notificationService = notificationService;
        this.classDAO = classDAO;
    }

    @Override
    public void update(ClassMaterial material) {
        if (material == null || material.getClassId() <= 0) {
            return;
        }

        try {
            int classId = material.getClassId();

            // Retrieve class details to format a descriptive notification message
            Class classObj = classDAO.findById(classId);
            String className;
            Integer tutorId = null;

            if (classObj != null) {
                tutorId = classObj.getTutorId();
                String subject = classObj.getSubject() != null ? classObj.getSubject().trim() : "Class";
                String batch = classObj.getBatch() != null ? classObj.getBatch().trim() : "";
                className = batch.isEmpty() ? subject : subject + " (" + batch + ")";
            } else {
                className = "Class #" + classId;
            }

            // Retrieve actively enrolled students for this class
            List<Enrollment> enrollments = enrollmentDAO.findByClass(classId);
            if (enrollments == null || enrollments.isEmpty()) {
                return;
            }

            // Deduplicate student IDs to ensure no duplicate notifications are dispatched
            Set<Integer> uniqueStudentIds = new HashSet<>();
            for (Enrollment enrollment : enrollments) {
                if (enrollment != null && enrollment.getStudentId() > 0) {
                    uniqueStudentIds.add(enrollment.getStudentId());
                }
            }

            String title = "New Material: " + material.getTitle();
            String message = "New material '" + material.getTitle() + "' has been uploaded for " + className + ".";

            // Dispatch notification to every actively enrolled student
            for (int studentId : uniqueStudentIds) {
                try {
                    notificationService.notifyUser(
                            studentId,
                            title,
                            message,
                            "ANNOUNCEMENT",
                            classId,
                            tutorId
                    );
                } catch (SQLException e) {
                    System.err.println("[StudentMaterialObserver] Failed to send notification to student "
                            + studentId + ": " + e.getMessage());
                }
            }
        } catch (SQLException e) {
            System.err.println("[StudentMaterialObserver] Error during observer execution: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
