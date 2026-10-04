package servlet;

import service.TimetableService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Handles actions by tutors on their assigned timetable slots:
 * 1. Confirming an assigned slot
 * 2. Suggesting an alternative time slot
 */
@WebServlet("/tutor/timetable-action")
public class TutorTimetableActionServlet extends HttpServlet {

    private TimetableService timetableService;

    @Override
    public void init() {
        timetableService = new TimetableService();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String role = String.valueOf(session.getAttribute("userRole"));
        if (!"TUTOR".equalsIgnoreCase(role) && !"ADMIN".equalsIgnoreCase(role)) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        int tutorId = ((Number) session.getAttribute("userId")).intValue();
        String action = request.getParameter("action");
        String slotIdStr = request.getParameter("slotId");

        if (slotIdStr == null || slotIdStr.isBlank()) {
            session.setAttribute("flashError", "Invalid timetable slot ID.");
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        try {
            int slotId = Integer.parseInt(slotIdStr);

            if ("confirm".equalsIgnoreCase(action)) {
                String error = timetableService.confirmSlotByTutor(slotId, tutorId);
                if (error != null) {
                    session.setAttribute("flashError", error);
                } else {
                    session.setAttribute("flashSuccess", "Class time slot has been successfully confirmed!");
                }

            } else if ("suggest".equalsIgnoreCase(action)) {
                String day = request.getParameter("suggestedDay");
                String start = request.getParameter("suggestedStartTime");
                String end = request.getParameter("suggestedEndTime");
                String note = request.getParameter("tutorNote");

                String error = timetableService.suggestAlternativeTime(slotId, tutorId, day, start, end, note);
                if (error != null) {
                    session.setAttribute("flashError", error);
                } else {
                    session.setAttribute("flashSuccess", "Your alternative time suggestion has been sent to the administrator.");
                }

            } else {
                session.setAttribute("flashError", "Unrecognized timetable action.");
            }

        } catch (NumberFormatException e) {
            session.setAttribute("flashError", "Invalid slot identifier.");
        } catch (SQLException e) {
            e.printStackTrace();
            session.setAttribute("flashError", "Database error occurred while processing timetable action.");
        }

        response.sendRedirect(request.getContextPath() + "/dashboard");
    }
}
