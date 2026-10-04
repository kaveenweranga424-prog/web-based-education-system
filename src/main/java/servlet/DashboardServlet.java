package servlet;

import model.User;
import service.DashboardService;
import service.UserService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {
    private DashboardService dashboardService;
    private UserService userService;

    @Override
    public void init() {
        dashboardService = new DashboardService();
        userService = new UserService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null || session.getAttribute("userRole") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        int userId = ((Number) session.getAttribute("userId")).intValue();
        String role = String.valueOf(session.getAttribute("userRole")).trim().toUpperCase();
        String jsp;

        try {
            User currentUser = userService.findById(userId);
            request.setAttribute("currentUser", currentUser);

            Map<String, Object> dashboardData;
            switch (role) {
                case "ADMIN":
                    dashboardData = dashboardService.getAdminDashboard();
                    jsp = "/dashboard-admin.jsp";
                    break;
                case "TUTOR":
                    dashboardData = dashboardService.getTutorDashboard(userId);
                    jsp = "/dashboard-tutor.jsp";
                    break;
                case "STUDENT":
                    dashboardData = dashboardService.getStudentDashboard(userId);
                    jsp = "/dashboard-student.jsp";
                    break;
                case "PARENT":
                    dashboardData = dashboardService.getParentDashboard(userId, parseStudentId(request));
                    jsp = "/dashboard-parent.jsp";
                    break;
                default:
                    session.invalidate();
                    response.sendRedirect(request.getContextPath() + "/login");
                    return;
            }
            request.setAttribute("dashboardData", dashboardData);
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("dashboardError", "Dashboard data could not be loaded from the database.");
            request.setAttribute("dashboardData", new LinkedHashMap<String, Object>());
            jsp = jspForRole(role);
        }

        request.getRequestDispatcher(jsp).forward(request, response);
    }

    private Integer parseStudentId(HttpServletRequest request) {
        String value = request.getParameter("studentId");
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Integer.valueOf(value);
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    private String jspForRole(String role) {
        switch (role) {
            case "ADMIN": return "/dashboard-admin.jsp";
            case "TUTOR": return "/dashboard-tutor.jsp";
            case "STUDENT": return "/dashboard-student.jsp";
            case "PARENT": return "/dashboard-parent.jsp";
            default: return "/login.jsp";
        }
    }
}
