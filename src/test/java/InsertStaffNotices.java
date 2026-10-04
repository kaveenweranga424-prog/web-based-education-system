package test;

import util.DBUtil;
import java.sql.*;

public class InsertStaffNotices {
    public static void main(String[] args) {
        try (Connection c = DBUtil.getConnection();
             Statement s = c.createStatement()) {
            
            String sql1 = "INSERT INTO dbo.notifications (recipient_id, title, message, type, class_id, is_read, created_at) " +
                          "VALUES (3, 'Payment Verification Pending', 'A student card payment of LKR 1,200.00 has been submitted for mathematics (grade 10). Please review and verify in Payment Approvals.', 'PAYMENT', 4, 0, GETDATE())";
            s.executeUpdate(sql1);

            String sql2 = "INSERT INTO dbo.notifications (recipient_id, title, message, type, is_read, created_at) " +
                          "VALUES (3, 'Staff Notification Center Active', 'Your staff portal is now equipped with live notifications. You will receive alerts when students submit payments and when enrollments are updated.', 'GENERAL', 0, DATEADD(minute, -10, GETDATE()))";
            s.executeUpdate(sql2);

            System.out.println("Staff notifications inserted successfully!");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
