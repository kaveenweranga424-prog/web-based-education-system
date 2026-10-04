package test;

import util.DBUtil;
import java.sql.*;

public class CheckStaffNotifications {
    public static void main(String[] args) {
        try (Connection c = DBUtil.getConnection();
             Statement s = c.createStatement()) {
            
            System.out.println("--- Staff Users ---");
            try (ResultSet rs = s.executeQuery("SELECT user_id, first_name, last_name, email, role, status FROM dbo.users WHERE role = 'STAFF'")) {
                while (rs.next()) {
                    System.out.println("User ID: " + rs.getInt("user_id") + " | Name: " + rs.getString("first_name") + " " + rs.getString("last_name") + " | Email: " + rs.getString("email") + " | Status: " + rs.getString("status"));
                }
            }

            System.out.println("\n--- Notifications for Staff ---");
            try (ResultSet rs = s.executeQuery(
                    "SELECT n.notification_id, n.recipient_id, n.title, n.message, n.type, n.is_read, n.created_at, u.role " +
                    "FROM dbo.notifications n " +
                    "JOIN dbo.users u ON u.user_id = n.recipient_id " +
                    "WHERE u.role = 'STAFF' ORDER BY n.created_at DESC")) {
                boolean found = false;
                while (rs.next()) {
                    found = true;
                    System.out.println("#" + rs.getInt("notification_id") + " | To: " + rs.getInt("recipient_id") +
                                       " | Type: " + rs.getString("type") + " | Title: " + rs.getString("title") +
                                       " | Msg: " + rs.getString("message") + " | Read: " + rs.getBoolean("is_read"));
                }
                if (!found) {
                    System.out.println("No notifications found for staff!");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
