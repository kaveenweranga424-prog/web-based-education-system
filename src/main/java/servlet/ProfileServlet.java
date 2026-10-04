package servlet;

import model.User;
import service.UserService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/profile")
public class ProfileServlet extends HttpServlet {

    private UserService userService;

    @Override
    public void init() {
        userService = new UserService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"success\":false,\"error\":\"Not logged in\"}");
            return;
        }

        int userId = ((Number) session.getAttribute("userId")).intValue();

        try {
            User user = userService.findById(userId);
            if (user == null) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"success\":false,\"error\":\"User not found\"}");
                return;
            }

            response.setContentType("application/json;charset=UTF-8");
            String json = String.format(
                    "{\"success\":true,\"userId\":%d,\"firstName\":\"%s\",\"lastName\":\"%s\",\"fullName\":\"%s\",\"email\":\"%s\",\"phone\":\"%s\",\"role\":\"%s\"}",
                    user.getUserId(),
                    escapeJson(user.getFirstName()),
                    escapeJson(user.getLastName()),
                    escapeJson(user.getFullName()),
                    escapeJson(user.getEmail()),
                    escapeJson(user.getPhone() != null ? user.getPhone() : ""),
                    escapeJson(user.getRole())
            );
            response.getWriter().write(json);

        } catch (SQLException e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"success\":false,\"error\":\"Database error: " + escapeJson(e.getMessage()) + "\"}");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            if (isAjax(request)) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"success\":false,\"error\":\"Not authenticated\"}");
                return;
            }
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        request.setCharacterEncoding("UTF-8");
        int userId = ((Number) session.getAttribute("userId")).intValue();
        String action = request.getParameter("action");
        if (action == null || action.isBlank()) {
            action = "updateProfile";
        }

        boolean ajax = isAjax(request);

        try {
            if ("changePassword".equalsIgnoreCase(action)) {
                String currentPassword = request.getParameter("currentPassword");
                String newPassword = request.getParameter("newPassword");
                String confirmPassword = request.getParameter("confirmPassword");

                String error = userService.changePassword(userId, currentPassword, newPassword, confirmPassword);
                if (error != null) {
                    if (ajax) {
                        response.setContentType("application/json;charset=UTF-8");
                        response.getWriter().write("{\"success\":false,\"error\":\"" + escapeJson(error) + "\"}");
                        return;
                    }
                    session.setAttribute("flashError", error);
                } else {
                    if (ajax) {
                        response.setContentType("application/json;charset=UTF-8");
                        response.getWriter().write("{\"success\":true,\"message\":\"Password has been changed successfully!\"}");
                        return;
                    }
                    session.setAttribute("flashSuccess", "Your password has been changed successfully.");
                }
            } else {
                // Update profile info
                String firstName = request.getParameter("firstName");
                String lastName = request.getParameter("lastName");
                String email = request.getParameter("email");
                String phone = request.getParameter("phone");

                String error = userService.updateProfile(userId, firstName, lastName, email, phone);
                if (error != null) {
                    if (ajax) {
                        response.setContentType("application/json;charset=UTF-8");
                        response.getWriter().write("{\"success\":false,\"error\":\"" + escapeJson(error) + "\"}");
                        return;
                    }
                    session.setAttribute("flashError", error);
                } else {
                    String fullName = (firstName.trim() + " " + lastName.trim()).trim();
                    session.setAttribute("userName", fullName);
                    session.setAttribute("userEmail", email.trim().toLowerCase());

                    if (ajax) {
                        response.setContentType("application/json;charset=UTF-8");
                        response.getWriter().write("{\"success\":true,\"message\":\"Profile updated successfully!\",\"userName\":\"" + escapeJson(fullName) + "\",\"userEmail\":\"" + escapeJson(email.trim().toLowerCase()) + "\"}");
                        return;
                    }
                    session.setAttribute("flashSuccess", "Profile updated successfully.");
                }
            }

            String redirect = request.getParameter("redirectUrl");
            if (redirect == null || redirect.isBlank()) {
                redirect = request.getContextPath() + "/dashboard";
            }
            response.sendRedirect(redirect);

        } catch (SQLException e) {
            e.printStackTrace();
            if (ajax) {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"success\":false,\"error\":\"Database error: " + escapeJson(e.getMessage()) + "\"}");
                return;
            }
            session.setAttribute("flashError", "Database error occurred while updating profile.");
            response.sendRedirect(request.getContextPath() + "/dashboard");
        }
    }

    private boolean isAjax(HttpServletRequest request) {
        String xrw = request.getHeader("X-Requested-With");
        String accept = request.getHeader("Accept");
        String ajaxParam = request.getParameter("ajax");
        return "XMLHttpRequest".equalsIgnoreCase(xrw)
                || (accept != null && accept.contains("application/json"))
                || "true".equalsIgnoreCase(ajaxParam);
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\b", "\\b")
                .replace("\f", "\\f")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
