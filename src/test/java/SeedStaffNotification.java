package test;

import util.DBUtil;
import java.sql.*;

public class SeedStaffNotification {
    public static void main(String[] args) {
        try (Connection c = DBUtil.getConnection();
             Statement s = c.createStatement()) {
            
            // Check if staff has any pending payment notification
            String sql = "SELECT p.payment_id, p.amount_paid, su.first_name + ' ' + su.last_name as student_name, " +
                         "c.class_id, c.subject, c.batch, staff.user_id as staff_id " +
                         "FROM dbo.payments p " +
                         "JOIN dbo.invoices i ON i.invoice_id = p.invoice_id " +
                         "JOIN dbo.enrollments e ON e.enrollment_id = i.enrollment_id " +
                         "JOIN dbo.classes c ON c.class_id = e.class_id " +
                         "JOIN dbo.users su ON su.user_id = e.student_id " +
                         "CROSS JOIN (SELECT user_id FROM dbo.users WHERE role = 'STAFF' AND status = 'ACTIVE') staff " +
                         "WHERE p.gateway_status IN ('DEMO_SUBMITTED','SUCCESS') " +
                         "  AND p.staff_status = 'PENDING' " +
                         "  AND e.status = 'PAID_PENDING_STAFF'";
            
            try (ResultSet rs = s.executeQuery(sql)) {
                while (rs.next()) {
                    int staffId = rs.getInt("staff_id");
                    int classId = rs.getInt("class_id");
                    String studentName = rs.getString("student_name");
                    String subject = rs.getString("subject");
                    String batch = rs.getString("batch");
                    String amount = rs.getString("amount_paid");
                    
                    String insertSql = "INSERT INTO dbo.notifications (recipient_id, title, message, type, class_id, is_read, created_at) " +
                                       "VALUES (?, ?, ?, 'PAYMENT', ?, 0, GETDATE())";
                    try (PreparedStatement ps = c.prepareStatement(insertSql)) {
                        ps.setInt(1, staffId);
                        ps.setString(2, "Payment Pending Confirmation");
                        ps.setString(3, "Card payment of LKR " + amount + " was submitted by " + studentName + " for " + subject + " - " + batch + ". Please review and confirm in Payment Approvals.");
                        ps.setInt(4, classId);
                        ps.executeUpdate();
                        System.out.println("Inserted notification for staff #" + staffId + " for payment of " + studentName);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
