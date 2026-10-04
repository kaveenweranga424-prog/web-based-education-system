package servlet;

import service.ClassService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Handles updating the Online Meeting Link (Zoom / Google Meet) for a class by its assigned tutor.
 */
@WebServlet("/tutor/class-link")
public class TutorClassLinkServlet extends HttpServlet {

    private ClassService classService;

    @Override
    public void init() {
        classService = new ClassService();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String role = String.valueOf(session.getAttribute("userRole"));
        if (!"TUTOR".equalsIgnoreCase(role)) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        int tutorId = ((Number) session.getAttribute("userId")).intValue();
        String classIdParam = request.getParameter("classId");
        String meetingLink = request.getParameter("meetingLink");

        if (classIdParam == null || classIdParam.isBlank()) {
            session.setAttribute("flashError", "Class identifier is required.");
            response.sendRedirect(request.getContextPath() + "/dashboard?view=classes");
            return;
        }

        try {
            int classId = Integer.parseInt(classIdParam.trim());
            String error = classService.updateMeetingLink(classId, tutorId, meetingLink);

            if (error != null) {
                session.setAttribute("flashError", error);
            } else {
                if (meetingLink != null && !meetingLink.trim().isEmpty()) {
                    session.setAttribute("flashSuccess", "Online class meeting link updated successfully.");
                } else {
                    session.setAttribute("flashSuccess", "Online class meeting link removed.");
                }
            }
        } catch (NumberFormatException e) {
            session.setAttribute("flashError", "Invalid class ID.");
        } catch (SQLException e) {
            e.printStackTrace();
            session.setAttribute("flashError", "Database error occurred while updating the meeting link.");
        }

        response.sendRedirect(request.getContextPath() + "/dashboard?view=classes");
    }
}
