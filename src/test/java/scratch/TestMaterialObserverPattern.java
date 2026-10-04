package scratch;

import dao.ClassDAO;
import dao.ClassMaterialDAO;
import dao.EnrollmentDAO;
import model.Class;
import model.ClassMaterial;
import model.Enrollment;
import observer.MaterialObserver;
import observer.StudentMaterialObserver;
import service.ClassMaterialService;
import util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class TestMaterialObserverPattern {

    public static void main(String[] args) {
        System.out.println("==================================================");
        System.out.println(" TESTING OBSERVER PATTERN: CLASS & MATERIAL MODULE ");
        System.out.println("==================================================");

        try {
            ClassDAO classDAO = new ClassDAO();
            EnrollmentDAO enrollmentDAO = new EnrollmentDAO();
            ClassMaterialDAO materialDAO = new ClassMaterialDAO();
            ClassMaterialService materialService = new ClassMaterialService();

            // 1. Verify Observer and Subject setup
            System.out.println("\n[STEP 1] Verifying Subject and Observer Registration...");
            if (materialService.getObservers().isEmpty()) {
                throw new IllegalStateException("FAIL: No observers registered in ClassMaterialService!");
            }
            boolean hasStudentObserver = false;
            for (MaterialObserver o : materialService.getObservers()) {
                if (o instanceof StudentMaterialObserver) {
                    hasStudentObserver = true;
                    break;
                }
            }
            if (!hasStudentObserver) {
                throw new IllegalStateException("FAIL: StudentMaterialObserver not found in ClassMaterialService!");
            }
            System.out.println("✔ PASS: StudentMaterialObserver is registered with ClassMaterialService (Concrete Subject).");

            // Also test custom observer add/remove
            final List<String> customObserverEvents = new ArrayList<>();
            MaterialObserver testObserver = new MaterialObserver() {
                @Override
                public void update(ClassMaterial material) {
                    customObserverEvents.add(material.getTitle());
                }
            };
            materialService.addObserver(testObserver);
            System.out.println("✔ PASS: Successfully attached custom test observer. Total observers: " + materialService.getObservers().size());

            // 2. Find an active class with enrolled students
            System.out.println("\n[STEP 2] Finding an active class with enrolled students...");
            int testClassId = 32; // English class
            Class testClass = classDAO.findById(testClassId);
            if (testClass == null) {
                // Fallback: search for any active class
                List<Class> activeClasses = classDAO.search("", "", "");
                if (activeClasses.isEmpty()) {
                    throw new IllegalStateException("FAIL: No active classes found in system!");
                }
                testClass = activeClasses.get(0);
                testClassId = testClass.getClassId();
            }
            System.out.println("Found class: ID=" + testClassId + ", Subject=" + testClass.getSubject() + ", Batch=" + testClass.getBatch());

            List<Enrollment> enrolledStudents = enrollmentDAO.findByClass(testClassId);
            System.out.println("Actively enrolled students count: " + enrolledStudents.size());
            for (Enrollment e : enrolledStudents) {
                System.out.println("  -> Enrolled Student ID: " + e.getStudentId() + " (" + e.getStudentName() + ")");
            }

            // 3. Test Material Upload Failure - Observer should NOT be triggered
            System.out.println("\n[STEP 3] Testing Material Upload Failure (Validation error)...");
            int beforeEvents = customObserverEvents.size();
            String validationError = materialService.addMaterial(testClassId, "", "Empty Title Test", "some/path.pdf");
            if (validationError == null) {
                throw new IllegalStateException("FAIL: addMaterial should have failed on empty title!");
            }
            if (customObserverEvents.size() != beforeEvents) {
                throw new IllegalStateException("FAIL: Observer was triggered even though upload failed!");
            }
            System.out.println("✔ PASS: Failed upload returned error ('" + validationError + "') and did NOT notify observers.");

            // 4. Test Successful Material Upload - Observer SHOULD be triggered
            System.out.println("\n[STEP 4] Testing Successful Material Upload & Student Notification...");
            String testMaterialTitle = "Observer Pattern Lecture Notes - Test " + System.currentTimeMillis();
            String testDescription = "Unit test verification notes for Observer Pattern";
            String testFilePath = "C:\\test\\notes.pdf";

            // Count existing notifications for this class before upload
            int notifCountBefore = countNotificationsForClass(testClassId);

            String uploadResult = materialService.addMaterial(testClassId, testMaterialTitle, testDescription, testFilePath);
            if (uploadResult != null) {
                throw new IllegalStateException("FAIL: Material upload failed with error: " + uploadResult);
            }
            System.out.println("✔ PASS: Material saved successfully via ClassMaterialService.addMaterial()");

            // Check that custom observer received event
            if (!customObserverEvents.contains(testMaterialTitle)) {
                throw new IllegalStateException("FAIL: Test observer did not receive the upload event!");
            }
            System.out.println("✔ PASS: Subject notified all observers including test observer.");

            // Verify notifications inserted into dbo.notifications for enrolled students
            int notifCountAfter = countNotificationsForClass(testClassId);
            int newNotifsCreated = notifCountAfter - notifCountBefore;
            System.out.println("✔ PASS: Notifications created in DB: " + newNotifsCreated);

            // Verify notification details
            verifyStudentNotification(testClassId, testMaterialTitle);

            // 5. Clean up test records
            System.out.println("\n[STEP 5] Cleaning up test material and test notification records...");
            cleanupTestRecords(testClassId, testMaterialTitle);
            materialService.removeObserver(testObserver);
            System.out.println("✔ PASS: Cleanup completed. Observers remaining: " + materialService.getObservers().size());

            System.out.println("\n==================================================");
            System.out.println(" ALL OBSERVER PATTERN VERIFICATION TESTS PASSED! ");
            System.out.println("==================================================");

        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("\n❌ TEST FAILED: " + e.getMessage());
            System.exit(1);
        }
    }

    private static int countNotificationsForClass(int classId) throws Exception {
        String sql = "SELECT COUNT(*) FROM dbo.notifications WHERE class_id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, classId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private static void verifyStudentNotification(int classId, String materialTitle) throws Exception {
        String sql = "SELECT notification_id, recipient_id, title, message, type, created_at FROM dbo.notifications WHERE class_id = ? AND title LIKE ? ORDER BY notification_id DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, classId);
            ps.setString(2, "%" + materialTitle + "%");
            try (ResultSet rs = ps.executeQuery()) {
                int found = 0;
                while (rs.next()) {
                    found++;
                    System.out.println("  ✔ Verified Notification Record:");
                    System.out.println("    - ID: " + rs.getInt("notification_id"));
                    System.out.println("    - Recipient (Student ID): " + rs.getInt("recipient_id"));
                    System.out.println("    - Title: " + rs.getString("title"));
                    System.out.println("    - Message: " + rs.getString("message"));
                    System.out.println("    - Type: " + rs.getString("type"));
                }
                if (found == 0) {
                    throw new IllegalStateException("FAIL: No notification record found matching title " + materialTitle);
                }
            }
        }
    }

    private static void cleanupTestRecords(int classId, String materialTitle) throws Exception {
        try (Connection conn = DBUtil.getConnection()) {
            // Delete test notifications
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM dbo.notifications WHERE class_id = ? AND title LIKE ?")) {
                ps.setInt(1, classId);
                ps.setString(2, "%" + materialTitle + "%");
                int d = ps.executeUpdate();
                System.out.println("  Cleaned up " + d + " test notification(s).");
            }

            // Delete test material
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM dbo.class_materials WHERE class_id = ? AND title = ?")) {
                ps.setInt(1, classId);
                ps.setString(2, materialTitle);
                int d = ps.executeUpdate();
                System.out.println("  Cleaned up " + d + " test material record(s).");
            }
        }
    }
}
