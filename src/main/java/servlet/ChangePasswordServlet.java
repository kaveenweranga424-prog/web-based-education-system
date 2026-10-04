package servlet;

import service.UserService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Handles password changes for logged-in users (Tutors, Admins, etc.).
 */
@WebServlet("/change-password")
public class ChangePasswordServlet extends HttpServlet {

    private UserService userService;

    @Override
    public void init() {
        userService = new UserService();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        int userId = ((Number) session.getAttribute("userId")).intValue();
        String currentPassword = request.getParameter("currentPassword");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");
        String redirectUrl = request.getParameter("redirectUrl");

        if (redirectUrl == null || redirectUrl.isBlank()) {
            redirectUrl = request.getContextPath() + "/dashboard";
        }

        try {
            String error = userService.changePassword(userId, currentPassword, newPassword, confirmPassword);
            if (error != null) {
                session.setAttribute("flashError", error);
            } else {
                session.setAttribute("flashSuccess", "Your password has been changed successfully.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            session.setAttribute("flashError", "Database error occurred while changing password. Please try again.");
        }

        response.sendRedirect(redirectUrl);
    }
}
