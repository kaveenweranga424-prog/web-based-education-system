package scratch;

import dao.ClassDAO;
import model.Class;
import service.ClassService;
import util.DatabaseInitializer;
import util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.List;

public class TestOnlineMeetingLink {

    public static void main(String[] args) {
        System.out.println("=== Testing Online Class / Zoom Meeting Link Feature ===");

        try {
            // 1. Run database initialization and schema migration
            System.out.println("\n1. Initializing database and running schema migrations...");
            DatabaseInitializer.initializeDatabase();

            // Verify column exists in database
            try (Connection conn = DBUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                         "SELECT COL_LENGTH('dbo.classes', 'meeting_link') AS col_len")) {
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next() && rs.getObject("col_len") != null) {
                        System.out.println("✔ Verified: 'meeting_link' column exists in dbo.classes.");
                    } else {
                        throw new RuntimeException("Column meeting_link was not found in dbo.classes!");
                    }
                }
            }

            ClassDAO classDAO = new ClassDAO();
            ClassService classService = new ClassService();

            // Find an active class that has an assigned tutor
            List<Class> classes = classDAO.findAll();
            Class testClass = null;
            for (Class c : classes) {
                if (c.getTutorId() != null && "ACTIVE".equalsIgnoreCase(c.getStatus())) {
                    testClass = c;
                    break;
                }
            }

            if (testClass == null) {
                System.out.println("No existing class with tutor found, creating a test class...");
                // Find a tutor user
                int tutorId = -1;
                try (Connection conn = DBUtil.getConnection();
                     PreparedStatement ps = conn.prepareStatement("SELECT TOP 1 user_id FROM dbo.users WHERE role = 'TUTOR'")) {
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) tutorId = rs.getInt(1);
                    }
                }
                if (tutorId == -1) {
                    System.out.println("No tutor found in database, creating temporary test tutor...");
                    try (Connection conn = DBUtil.getConnection();
                         PreparedStatement ps = conn.prepareStatement(
                                 "INSERT INTO dbo.users (email, password_hash, first_name, last_name, role) VALUES ('test_tutor@classora.com', 'dummy', 'Test', 'Tutor', 'TUTOR')",
                                 PreparedStatement.RETURN_GENERATED_KEYS)) {
                        ps.executeUpdate();
                        try (ResultSet rs = ps.getGeneratedKeys()) {
                            if (rs.next()) tutorId = rs.getInt(1);
                        }
                    }
                }

                String err = classService.createClass("Science", "Grade 10 Test", String.valueOf(tutorId), "2500", null, "WEEKDAY");
                if (err != null) {
                    throw new RuntimeException("Could not create test class: " + err);
                }
                List<Class> found = classDAO.search("Science", null, "Grade 10 Test (Weekday)", "WEEKDAY");
                testClass = found.get(0);
            }

            int classId = testClass.getClassId();
            int tutorId = testClass.getTutorId();
            System.out.println("\nTesting with Class ID: " + classId + " ('" + testClass.getSubject() + " - " + testClass.getBatch() + "'), Tutor ID: " + tutorId);

            // 2. Test updating meeting link as unauthorized tutor (tutorId + 9999)
            System.out.println("\n2. Testing security check (unauthorized tutor)...");
            String unauthorizedErr = classService.updateMeetingLink(classId, tutorId + 9999, "https://zoom.us/j/123456789");
            if (unauthorizedErr != null && unauthorizedErr.contains("not authorized")) {
                System.out.println("✔ Security check passed: Unauthorized tutor was correctly blocked.");
            } else {
                throw new RuntimeException("Security check failed! Response: " + unauthorizedErr);
            }

            // 3. Test updating meeting link with valid Zoom link
            System.out.println("\n3. Testing setting valid meeting link...");
            String zoomUrl = "https://us02web.zoom.us/j/81234567890?pwd=testpassword123";
            String updateErr = classService.updateMeetingLink(classId, tutorId, zoomUrl);
            if (updateErr == null) {
                System.out.println("✔ Update succeeded without errors.");
            } else {
                throw new RuntimeException("Failed to update meeting link: " + updateErr);
            }

            // 4. Verify in ClassDAO.findById
            System.out.println("\n4. Verifying stored meeting link in ClassDAO.findById...");
            Class reloaded = classDAO.findById(classId);
            if (reloaded != null && zoomUrl.equals(reloaded.getMeetingLink())) {
                System.out.println("✔ Verified stored link: " + reloaded.getMeetingLink());
                System.out.println("✔ hasMeetingLink(): " + reloaded.hasMeetingLink());
            } else {
                throw new RuntimeException("Meeting link mismatch! Found: " + (reloaded != null ? reloaded.getMeetingLink() : "null"));
            }

            // 5. Test auto-prefixing http/https if omitted by tutor
            System.out.println("\n5. Testing automatic https:// prefixing when protocol is omitted...");
            String rawUrl = "meet.google.com/abc-defg-hij";
            updateErr = classService.updateMeetingLink(classId, tutorId, rawUrl);
            if (updateErr == null) {
                reloaded = classDAO.findById(classId);
                if (reloaded != null && ("https://" + rawUrl).equals(reloaded.getMeetingLink())) {
                    System.out.println("✔ Automatically prefixed with https://: " + reloaded.getMeetingLink());
                } else {
                    throw new RuntimeException("Prefixing failed! Found: " + (reloaded != null ? reloaded.getMeetingLink() : "null"));
                }
            } else {
                throw new RuntimeException("Failed to update raw URL: " + updateErr);
            }

            // 6. Test clearing meeting link
            System.out.println("\n6. Testing clearing meeting link (empty string)...");
            updateErr = classService.updateMeetingLink(classId, tutorId, "");
            if (updateErr == null) {
                reloaded = classDAO.findById(classId);
                if (reloaded != null && (reloaded.getMeetingLink() == null || reloaded.getMeetingLink().isBlank())) {
                    System.out.println("✔ Meeting link successfully cleared: " + reloaded.getMeetingLink());
                    System.out.println("✔ hasMeetingLink(): " + reloaded.hasMeetingLink());
                } else {
                    throw new RuntimeException("Clearing failed! Link is still: " + reloaded.getMeetingLink());
                }
            } else {
                throw new RuntimeException("Failed to clear meeting link: " + updateErr);
            }

            System.out.println("\n=======================================================");
            System.out.println("🎉 ALL TESTS PASSED SUCCESSFULLY! FEATURE IS FULLY WORKING.");
            System.out.println("=======================================================");

        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }
}
