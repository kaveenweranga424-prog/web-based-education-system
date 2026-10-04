package servlet;

import model.TimetableSlot;
import model.TutorProfile;
import model.Class;
import service.ClassService;
import service.TimetableService;
import service.TutorService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Admin-only: build and view the master (clash-free) timetable.
 */
@WebServlet("/admin/timetable")
public class TimetableServlet extends HttpServlet {

    private TimetableService timetableService;
    private ClassService classService;
    private TutorService tutorService;

    @Override
    public void init() {
        timetableService = new TimetableService();
        classService = new ClassService();
        tutorService = new TutorService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            List<TimetableSlot> slots = timetableService.findAll();
            List<Class> classes = classService.findAll();
            List<TutorProfile> tutors = tutorService.findAll();

            request.setAttribute("slots", slots);
            request.setAttribute("classes", classes);
            request.setAttribute("tutors", tutors);

            request.getRequestDispatcher("/admin/timetable.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("/admin/timetable.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");

        try {
            if ("cancel".equals(action)) {
                int slotId = Integer.parseInt(request.getParameter("slotId"));
                timetableService.cancelSlot(slotId);
                response.sendRedirect(request.getContextPath() + "/admin/timetable");
                return;
            }

            if ("acceptSuggestion".equals(action)) {
                int slotId = Integer.parseInt(request.getParameter("slotId"));
                String error = timetableService.acceptSuggestionByAdmin(slotId);
                if (error != null) {
                    request.setAttribute("errorMessage", error);
                    forwardWithData(request, response);
                    return;
                }
                response.sendRedirect(request.getContextPath() + "/admin/timetable");
                return;
            }

            String classIdStr = request.getParameter("classId");
            String tutorIdStr = request.getParameter("tutorId");
            String dayOfWeek = request.getParameter("dayOfWeek");
            String startTime = request.getParameter("startTime");
            String endTime = request.getParameter("endTime");
            String room = request.getParameter("room");

            if (classIdStr == null || classIdStr.isBlank() || tutorIdStr == null || tutorIdStr.isBlank()) {
                preserveFormAttributes(request, classIdStr, tutorIdStr, dayOfWeek, startTime, endTime, room);
                request.setAttribute("errorMessage", "Please select both a class and a tutor.");
                forwardWithData(request, response);
                return;
            }

            int classId = Integer.parseInt(classIdStr);
            int tutorId = Integer.parseInt(tutorIdStr);

            String errorMessage = timetableService.createSlot(
                    classId,
                    tutorId,
                    dayOfWeek,
                    startTime,
                    endTime,
                    room
            );

            if (errorMessage != null) {
                preserveFormAttributes(request, classIdStr, tutorIdStr, dayOfWeek, startTime, endTime, room);
                request.setAttribute("errorMessage", errorMessage);
                forwardWithData(request, response);
                return;
            }

            response.sendRedirect(request.getContextPath() + "/admin/timetable");

        } catch (NumberFormatException e) {
            preserveFormAttributes(request, request.getParameter("classId"), request.getParameter("tutorId"),
                    request.getParameter("dayOfWeek"), request.getParameter("startTime"),
                    request.getParameter("endTime"), request.getParameter("room"));
            request.setAttribute("errorMessage", "Invalid class or tutor selection.");
            forwardWithData(request, response);
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            forwardWithData(request, response);
        }
    }

    private void preserveFormAttributes(HttpServletRequest request, String classId, String tutorId,
                                        String day, String startTime, String endTime, String room) {
        request.setAttribute("selectedClassId", classId);
        request.setAttribute("selectedTutorId", tutorId);
        request.setAttribute("selectedDay", day);
        request.setAttribute("selectedStartTime", startTime);
        request.setAttribute("selectedEndTime", endTime);
        request.setAttribute("selectedRoom", room);
    }

    private void forwardWithData(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            request.setAttribute("slots", timetableService.findAll());
            request.setAttribute("classes", classService.findAll());
            request.setAttribute("tutors", tutorService.findAll());
        } catch (SQLException ex) {
            ex.printStackTrace();
        }
        request.getRequestDispatcher("/admin/timetable.jsp").forward(request, response);
    }
}