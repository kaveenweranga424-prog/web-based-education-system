package servlet;

import service.ParentRegistrationService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/register-parent")
public class ParentRegisterServlet extends HttpServlet {

    private ParentRegistrationService parentRegistrationService;

    @Override
    public void init() {
        parentRegistrationService = new ParentRegistrationService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/register-parent.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String firstName = request.getParameter("firstName");
        String lastName = request.getParameter("lastName");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String childEmail = request.getParameter("childEmail");
        String relationship = request.getParameter("relationship");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");

        try {
            String error = parentRegistrationService.registerParent(
                    firstName,
                    lastName,
                    email,
                    phone,
                    childEmail,
                    relationship,
                    password,
                    confirmPassword
            );

            if (error != null) {
                request.setAttribute("errorMessage", error);
                keepValues(request, firstName, lastName, email, phone, childEmail, relationship);
                request.getRequestDispatcher("/register-parent.jsp").forward(request, response);
                return;
            }

            response.sendRedirect(request.getContextPath() + "/login.jsp?registered=true");

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            keepValues(request, firstName, lastName, email, phone, childEmail, relationship);
            request.getRequestDispatcher("/register-parent.jsp").forward(request, response);
        }
    }

    private void keepValues(
            HttpServletRequest request,
            String firstName,
            String lastName,
            String email,
            String phone,
            String childEmail,
            String relationship
    ) {
        request.setAttribute("firstName", firstName);
        request.setAttribute("lastName", lastName);
        request.setAttribute("email", email);
        request.setAttribute("phone", phone);
        request.setAttribute("childEmail", childEmail);
        request.setAttribute("relationship", relationship);
    }
}
