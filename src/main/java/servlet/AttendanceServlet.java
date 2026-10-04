package servlet;

import dao.ParentStudentDAO;
import model.Attendance;
import model.Class;
import service.AttendanceService;
import service.ClassService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Date;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;

/**
 * GET:
 *  - TUTOR: shows own classes + a date-based roster to mark attendance
 *  - ADMIN: same as tutor, but for any class (correction access)
 *  - STUDENT: shows own attendance history
 *  - PARENT: shows their linked child's attendance history
 *
 * POST: TUTOR (own class only) or ADMIN saves attendance for the roster.
 */
@WebServlet("/attendance")
public class AttendanceServlet extends HttpServlet {

    private AttendanceService attendanceService;
    private ClassService classService;
    private ParentStudentDAO parentStudentDAO;

    @Override
    public void init() {
        attendanceService = new AttendanceService();
        classService = new ClassService();
        parentStudentDAO = new ParentStudentDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String role = String.valueOf(session.getAttribute("userRole"));
        int userId = (int) session.getAttribute("userId");

        try {
            if ("TUTOR".equalsIgnoreCase(role) || "ADMIN".equalsIgnoreCase(role)) {

                if (session.getAttribute("errorMessage") != null) {
                    request.setAttribute("errorMessage", session.getAttribute("errorMessage"));
                    session.removeAttribute("errorMessage");
                }
                if (session.getAttribute("successMessage") != null) {
                    request.setAttribute("successMessage", session.getAttribute("successMessage"));
                    session.removeAttribute("successMessage");
                }

                List<Class> classes = "ADMIN".equalsIgnoreCase(role)
                        ? classService.findAll()
                        : classService.findByTutor(userId);

                request.setAttribute("classes", classes);

                String classIdParam = request.getParameter("classId");
                String dateParam = request.getParameter("date");

                LocalDate today = LocalDate.now();
                LocalDate sessionLocalDate = today;

                if (dateParam != null && !dateParam.isBlank()) {
                    try {
                        LocalDate parsed = LocalDate.parse(dateParam);
                        if (parsed.isAfter(today)) {
                            request.setAttribute("errorMessage", "Cannot mark attendance for future dates (" + parsed + "). Showing today's date.");
                            sessionLocalDate = today;
                        } else {
                            sessionLocalDate = parsed;
                        }
                    } catch (Exception e) {
                        sessionLocalDate = today;
                    }
                }

                Date sessionDate = Date.valueOf(sessionLocalDate);
                request.setAttribute("selectedDate", sessionLocalDate.toString());
                request.setAttribute("maxDate", today.toString());

                if (classIdParam != null && !classIdParam.isBlank()) {
                    int classId = Integer.parseInt(classIdParam);
                    List<Attendance> roster = attendanceService.getRoster(classId, sessionDate);

                    request.setAttribute("roster", roster);
                    request.setAttribute("selectedClassId", classId);
                }

                request.getRequestDispatcher("/mark-attendance.jsp").forward(request, response);

            } else if ("STUDENT".equalsIgnoreCase(role)) {

                List<Attendance> history = attendanceService.getHistoryByStudent(userId);
                request.setAttribute("history", history);
                request.getRequestDispatcher("/attendance-history.jsp").forward(request, response);

            } else if ("PARENT".equalsIgnoreCase(role)) {

                List<Integer> childIds = parentStudentDAO.findActiveStudentIdsForParent(userId);
                request.setAttribute("childIds", childIds);

                dao.UserDAO userDAO = new dao.UserDAO();
                List<model.User> linkedChildren = new java.util.ArrayList<>();
                for (Integer cId : childIds) {
                    model.User u = userDAO.findById(cId);
                    if (u != null) linkedChildren.add(u);
                }
                request.setAttribute("linkedChildren", linkedChildren);

                if (!childIds.isEmpty()) {
                    int studentId = childIds.get(0);
                    String requested = request.getParameter("studentId");
                    if (requested != null && !requested.isBlank()) {
                        try {
                            int rId = Integer.parseInt(requested);
                            if (childIds.contains(rId)) studentId = rId;
                        } catch (NumberFormatException ignored) {}
                    }
                    request.setAttribute("selectedStudentId", studentId);
                    List<Attendance> history = attendanceService.getHistoryByStudent(studentId);
                    request.setAttribute("history", history);
                }

                request.getRequestDispatcher("/attendance-history.jsp").forward(request, response);

            } else {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
            }

        } catch (IllegalArgumentException e) {
            request.setAttribute("errorMessage", "Invalid class or date.");
            request.getRequestDispatcher("/mark-attendance.jsp").forward(request, response);
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("/mark-attendance.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String role = String.valueOf(session.getAttribute("userRole"));

        if (!"TUTOR".equalsIgnoreCase(role) && !"ADMIN".equalsIgnoreCase(role)) {
            response.sendRedirect(request.getContextPath() + "/attendance");
            return;
        }

        String action = request.getParameter("action");
        if ("delete".equals(action)) {
            try {
                int attendanceId = Integer.parseInt(request.getParameter("attendanceId"));
                attendanceService.deleteAttendance(attendanceId);
                String returnUrl = request.getParameter("returnUrl");
                if (returnUrl != null && !returnUrl.isBlank()) {
                    response.sendRedirect(returnUrl);
                    return;
                }
                response.sendRedirect(request.getContextPath() + "/attendance");
                return;
            } catch (Exception e) {
                e.printStackTrace();
                response.sendRedirect(request.getContextPath() + "/attendance");
                return;
            }
        }

        int markedByUserId = (int) session.getAttribute("userId");
        boolean isAdmin = "ADMIN".equalsIgnoreCase(role);

        try {
            int classId = Integer.parseInt(request.getParameter("classId"));
            String sessionDateStr = request.getParameter("sessionDate");
            LocalDate today = LocalDate.now();
            LocalDate sessionLocalDate;

            try {
                sessionLocalDate = (sessionDateStr != null && !sessionDateStr.isBlank())
                        ? LocalDate.parse(sessionDateStr)
                        : today;
            } catch (Exception e) {
                session.setAttribute("errorMessage", "Invalid session date.");
                response.sendRedirect(request.getContextPath() + "/attendance?classId=" + classId);
                return;
            }

            if (sessionLocalDate.isAfter(today)) {
                session.setAttribute("errorMessage", "Cannot mark attendance for future dates (" + sessionLocalDate + "). Attendance can only be recorded for today or past sessions.");
                response.sendRedirect(request.getContextPath() + "/attendance?classId=" + classId + "&date=" + today);
                return;
            }

            Date sessionDate = Date.valueOf(sessionLocalDate);

            String[] studentIds = request.getParameterValues("studentId");
            String[] statuses = request.getParameterValues("status");
            String[] remarksArr = request.getParameterValues("remarks");

            String firstError = null;

            if (studentIds != null) {
                for (int i = 0; i < studentIds.length; i++) {
                    int studentId = Integer.parseInt(studentIds[i]);
                    String status = statuses[i];
                    String remarks = (remarksArr != null && i < remarksArr.length) ? remarksArr[i] : null;

                    String error = attendanceService.markAttendance(
                            classId, studentId, sessionDate, status, remarks, markedByUserId, isAdmin
                    );

                    if (error != null && firstError == null) {
                        firstError = error;
                    }
                }
            }

            if (firstError != null) {
                session.setAttribute("errorMessage", firstError);
            } else {
                session.setAttribute("successMessage", "Attendance successfully saved for " + sessionDate + ".");
            }

            response.sendRedirect(request.getContextPath()
                    + "/attendance?classId=" + classId + "&date=" + sessionDate);

        }  catch (IllegalArgumentException e) {
            session.setAttribute("errorMessage", "Invalid input parameters.");
            response.sendRedirect(request.getContextPath() + "/attendance");

        }  catch (SQLException e) {
            e.printStackTrace();
            session.setAttribute("errorMessage", "Database error occurred while saving attendance.");
            response.sendRedirect(request.getContextPath() + "/attendance");
        }
    }
}