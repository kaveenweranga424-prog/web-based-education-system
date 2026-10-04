package servlet;

import model.TutorProfile;
import model.User;
import service.TutorService;

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
 * Admin-only: create tutor accounts, manage tutor profiles, activate and deactivate tutors.
 */
@WebServlet("/admin/tutors")
public class TutorServlet extends HttpServlet {

    private TutorService tutorService;

    @Override
    public void init() {
        tutorService = new TutorService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!ensureAdmin(request, response)) {
            return;
        }

        try {
            String action = request.getParameter("action");
            if ("edit".equals(action) && request.getParameter("id") != null) {
                int userId = Integer.parseInt(request.getParameter("id"));
                TutorProfile editTutor = tutorService.findByUserId(userId);
                request.setAttribute("editTutor", editTutor);
            }

            List<TutorProfile> tutors = tutorService.findAll();
            List<User> unassigned = tutorService.findTutorUsersWithoutProfile();

            request.setAttribute("tutors", tutors);
            request.setAttribute("unassignedTutorUsers", unassigned);

            request.getRequestDispatcher("/admin/manage-tutors.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("/admin/manage-tutors.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!ensureAdmin(request, response)) {
            return;
        }

        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();

        String action = request.getParameter("action");

        try {
            if ("delete".equals(action) || "deactivate".equals(action)) {
                int userId = Integer.parseInt(request.getParameter("userId"));
                String errorMessage = tutorService.deleteTutor(userId);
                if (errorMessage != null) {
                    request.setAttribute("errorMessage", errorMessage);
                    request.setAttribute("tutors", tutorService.findAll());
                    request.setAttribute("unassignedTutorUsers", tutorService.findTutorUsersWithoutProfile());
                    request.getRequestDispatcher("/admin/manage-tutors.jsp").forward(request, response);
                    return;
                }
                response.sendRedirect(request.getContextPath() + "/admin/tutors");
                return;
            }

            String errorMessage;

            if ("update".equals(action) || "updateProfile".equals(action)) {
                int userId = Integer.parseInt(request.getParameter("userId"));

                errorMessage = tutorService.updateTutor(
                        userId,
                        request.getParameter("firstName"),
                        request.getParameter("lastName"),
                        request.getParameter("email"),
                        request.getParameter("phone"),
                        request.getParameter("specialization"),
                        request.getParameter("bio")
                );

            } else {
                // create new tutor account + profile
                String tutorEmail = request.getParameter("email");
                String tempPass = request.getParameter("temporaryPassword");

                errorMessage = tutorService.createTutor(
                        request.getParameter("firstName"),
                        request.getParameter("lastName"),
                        tutorEmail,
                        request.getParameter("phone"),
                        tempPass,
                        request.getParameter("specialization"),
                        request.getParameter("bio")
                );

                if (errorMessage == null) {
                    boolean mailLive = util.EmailService.isConfigured();
                    String msg = "Tutor account created successfully for " + tutorEmail + ". ";
                    if (mailLive) {
                        msg += "Credentials email sent to tutor's inbox.";
                    } else {
                        msg += "Live SMTP is not configured in email.properties (temporary password: " + tempPass + " was logged to server console).";
                    }
                    session.setAttribute("flashSuccess", msg);
                }
            }

            if (errorMessage != null) {
                request.setAttribute("errorMessage", errorMessage);
                request.setAttribute("tutors", tutorService.findAll());
                request.setAttribute("unassignedTutorUsers", tutorService.findTutorUsersWithoutProfile());
                request.getRequestDispatcher("/admin/manage-tutors.jsp").forward(request, response);
                return;
            }

            response.sendRedirect(request.getContextPath() + "/admin/tutors");

        } catch (SQLException | NumberFormatException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("/admin/manage-tutors.jsp").forward(request, response);
        }
    }

    private boolean ensureAdmin(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return false;
        }

        String role = String.valueOf(session.getAttribute("userRole"));
        if (!"ADMIN".equalsIgnoreCase(role)) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return false;
        }

        return true;
    }
}