package servlet;

import model.Notification;
import service.NotificationService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Any logged-in user: view their notification log and mark items as read.
 */
@WebServlet("/notifications")
public class NotificationServlet extends HttpServlet {

    private NotificationService notificationService;

    @Override
    public void init() {
        notificationService = new NotificationService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int userId = (int) session.getAttribute("userId");
        String role = session.getAttribute("userRole") != null ? String.valueOf(session.getAttribute("userRole")) : "STUDENT";
        String action = request.getParameter("action");

        if (action != null && !action.isBlank()) {
            handleAction(request, response, userId, role, action);
            return;
        }

        try {
            List<Notification> notifications = notificationService.findByUser(userId, role);
            request.setAttribute("notifications", notifications);

            request.getRequestDispatcher("/notifications.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("/notifications.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            if (isAjaxRequest(request)) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"success\":false,\"error\":\"Not authenticated\"}");
                return;
            }
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int userId = (int) session.getAttribute("userId");
        String role = session.getAttribute("userRole") != null ? String.valueOf(session.getAttribute("userRole")) : "STUDENT";
        String action = request.getParameter("action");

        handleAction(request, response, userId, role, action);
    }

    private void handleAction(HttpServletRequest request, HttpServletResponse response, int userId, String role, String action)
            throws IOException {

        boolean isAjax = isAjaxRequest(request);

        try {
            if ("markAllRead".equals(action)) {
                notificationService.markAllRead(userId, role);
            } else if ("delete".equals(action)) {
                String notifIdStr = request.getParameter("notificationId");
                if (notifIdStr != null && !notifIdStr.isBlank()) {
                    int notificationId = Integer.parseInt(notifIdStr.trim());
                    notificationService.deleteNotification(notificationId);
                }
            } else if ("markRead".equals(action)) {
                String notifIdStr = request.getParameter("notificationId");
                if (notifIdStr != null && !notifIdStr.isBlank()) {
                    int notificationId = Integer.parseInt(notifIdStr.trim());
                    notificationService.markRead(notificationId, userId, role);
                }
            }

            int unread = notificationService.countUnread(userId, role);

            if (isAjax) {
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"success\":true,\"unreadCount\":" + unread + "}");
                return;
            }

            String redirect = request.getParameter("redirect");
            if (redirect != null && !redirect.isBlank()) {
                response.sendRedirect(redirect);
                return;
            }

            String referer = request.getHeader("Referer");
            if (referer != null && !referer.isBlank()) {
                response.sendRedirect(referer);
                return;
            }

            response.sendRedirect(request.getContextPath() + "/notifications");

        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
            if (isAjax) {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"success\":false,\"error\":\"" + e.getMessage() + "\"}");
                return;
            }
            response.sendRedirect(request.getContextPath() + "/notifications");
        }
    }

    private boolean isAjaxRequest(HttpServletRequest request) {
        String xrw = request.getHeader("X-Requested-With");
        String accept = request.getHeader("Accept");
        String ajaxParam = request.getParameter("ajax");
        return "XMLHttpRequest".equalsIgnoreCase(xrw)
                || (accept != null && accept.contains("application/json"))
                || "true".equalsIgnoreCase(ajaxParam);
    }
}