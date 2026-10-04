package servlet;

import dao.ParentStudentDAO;
import model.ExamResult;
import service.ResultService;

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
 * Student/Parent: read-only view of exam results / result sheet.
 */
@WebServlet("/results")
public class ResultViewServlet extends HttpServlet {

    private ResultService resultService;
    private ParentStudentDAO parentStudentDAO;

    @Override
    public void init() {
        resultService = new ResultService();
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
            int studentId;

            if ("STUDENT".equalsIgnoreCase(role)) {
                studentId = userId;
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

                if (childIds.isEmpty()) {
                    request.getRequestDispatcher("/results.jsp").forward(request, response);
                    return;
                }

                studentId = childIds.get(0);
                String requested = request.getParameter("studentId");
                if (requested != null && !requested.isBlank()) {
                    try {
                        int rId = Integer.parseInt(requested);
                        if (childIds.contains(rId)) studentId = rId;
                    } catch (NumberFormatException ignored) {}
                }
                request.setAttribute("selectedStudentId", studentId);
            } else {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }

            List<ExamResult> results = resultService.getResultsByStudent(studentId);
            request.setAttribute("results", results);

            request.getRequestDispatcher("/results.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("/results.jsp").forward(request, response);
        }
    }
}