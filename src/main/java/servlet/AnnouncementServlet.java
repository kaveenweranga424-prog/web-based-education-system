package servlet;

import model.Class;
import service.ClassService;
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
 * Tutor: send an announcement to one of their own classes.
 * Admin: send an announcement to any class, or broadcast to a whole role.
 */
@WebServlet("/announcements")
public class AnnouncementServlet extends HttpServlet {

    private NotificationService notificationService;
    private ClassService classService;

    @Override
    public void init() {
        notificationService = new NotificationService();
        classService = new ClassService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || !canAccess(session)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String role = String.valueOf(session.getAttribute("userRole"));
        int userId = (int) session.getAttribute("userId");
        boolean isAdmin = "ADMIN".equalsIgnoreCase(role);

        try {
            List<Class> classes = isAdmin ? classService.findAll() : classService.findByTutor(userId);
            request.setAttribute("classes", classes);
            request.setAttribute("isAdmin", isAdmin);
            try {
                request.setAttribute("sentHistory", notificationService.findBySender(userId));
            } catch (Exception ignored) {}

            request.getRequestDispatcher("/send-announcement.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("/send-announcement.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || !canAccess(session)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String role = String.valueOf(session.getAttribute("userRole"));
        int userId = (int) session.getAttribute("userId");
        boolean isAdmin = "ADMIN".equalsIgnoreCase(role);

        String title = request.getParameter("title");
        String message = request.getParameter("message");
        String scope = request.getParameter("scope"); // "class" or "broadcast" (broadcast: admin only)

        try {
            String errorMessage;

            if (isAdmin && "broadcast".equals(scope)) {
                String targetRole = request.getParameter("targetRole");
                errorMessage = notificationService.sendBroadcast(targetRole, title, message, userId);

            } else {
                int classId = Integer.parseInt(request.getParameter("classId"));

                if (!isAdmin) {
                    // tutor may only announce to their own class
                    var classItem = classService.findById(classId);
                    if (classItem == null || classItem.getTutorId() == null || classItem.getTutorId() != userId) {
                        request.setAttribute("errorMessage", "You are not assigned to this class.");
                        request.setAttribute("classes", classService.findByTutor(userId));
                        request.setAttribute("isAdmin", false);
                        request.getRequestDispatcher("/send-announcement.jsp").forward(request, response);
                        return;
                    }
                }

                errorMessage = notificationService.sendClassAnnouncement(classId, title, message, userId);
            }

            if (errorMessage != null) {
                request.setAttribute("errorMessage", errorMessage);
                request.setAttribute("classes", isAdmin ? classService.findAll() : classService.findByTutor(userId));
                request.setAttribute("isAdmin", isAdmin);
                request.getRequestDispatcher("/send-announcement.jsp").forward(request, response);
                return;
            }

            response.sendRedirect(request.getContextPath() + "/announcements?sent=1");

        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            response.sendRedirect(request.getContextPath() + "/announcements");
        }
    }

    private boolean canAccess(HttpSession session) {
        String role = String.valueOf(session.getAttribute("userRole"));
        return "TUTOR".equalsIgnoreCase(role) || "ADMIN".equalsIgnoreCase(role);
    }
}