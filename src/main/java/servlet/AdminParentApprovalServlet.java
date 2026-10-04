package servlet;

import dao.ParentStudentDAO;
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
import java.util.Map;

@WebServlet("/admin/parent-approvals")
public class AdminParentApprovalServlet extends HttpServlet {

    private ParentStudentDAO parentStudentDAO;
    private NotificationService notificationService;

    @Override
    public void init() {
        parentStudentDAO = new ParentStudentDAO();
        notificationService = new NotificationService();
    }

    private boolean ensureAdmin(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return false;
        }
        String role = String.valueOf(session.getAttribute("userRole"));
        if (!"ADMIN".equalsIgnoreCase(role)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied. Admin role required.");
            return false;
        }
        return true;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!ensureAdmin(request, response)) return;

        try {
            List<Map<String, Object>> pendingLinks = parentStudentDAO.findPendingLinks();
            request.setAttribute("pendingLinks", pendingLinks);
            request.getRequestDispatcher("/admin/parent-approvals.jsp").forward(request, response);
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error loading pending parent requests.");
            request.getRequestDispatcher("/admin/parent-approvals.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!ensureAdmin(request, response)) return;

        try {
            int parentStudentId = Integer.parseInt(request.getParameter("parentStudentId"));
            String action = request.getParameter("action");

            Map<String, Object> link = parentStudentDAO.findLinkById(parentStudentId);
            if (link == null) {
                response.sendRedirect(request.getContextPath() + "/admin/parent-approvals");
                return;
            }

            int parentUserId = (int) link.get("parentUserId");
            int studentUserId = (int) link.get("studentUserId");
            String studentName = (String) link.get("studentName");
            String parentName = (String) link.get("parentName");

            if ("approve".equalsIgnoreCase(action)) {
                parentStudentDAO.updateLinkStatus(parentStudentId, "ACTIVE");
                notificationService.notifyUser(parentUserId, "Parent Account Approved",
                        "Your request to link your account to student " + studentName + " has been approved by admin.",
                        "GENERAL", null, null);
                notificationService.notifyUser(studentUserId, "Parent Linked",
                        parentName + " has been linked as your parent/guardian in Classora.",
                        "GENERAL", null, null);
            } else if ("reject".equalsIgnoreCase(action)) {
                parentStudentDAO.updateLinkStatus(parentStudentId, "REJECTED");
                notificationService.notifyUser(parentUserId, "Parent Account Rejected",
                        "Your request to link your account to student " + studentName + " was declined by admin.",
                        "GENERAL", null, null);
            }

            response.sendRedirect(request.getContextPath() + "/admin/parent-approvals?updated=true");
        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/admin/parent-approvals");
        }
    }
}
