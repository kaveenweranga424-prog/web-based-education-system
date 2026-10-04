package servlet;

import model.User;
import service.UserService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/register")
public class RegisterServlet
        extends HttpServlet {

    private UserService userService;

    @Override
    public void init() {

        userService =
                new UserService();
    }


    /*
     * Open registration page
     */
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        request.getRequestDispatcher(
                "/register.jsp"
        ).forward(
                request,
                response
        );
    }


    /*
     * Process registration
     */
    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        request.setCharacterEncoding(
                "UTF-8"
        );


        String firstName =
                request.getParameter(
                        "firstName"
                );

        String lastName =
                request.getParameter(
                        "lastName"
                );

        String email =
                request.getParameter(
                        "email"
                );

        String phone =
                request.getParameter(
                        "phone"
                );

        String password =
                request.getParameter(
                        "password"
                );

        String confirmPassword =
                request.getParameter(
                        "confirmPassword"
                );

        // Student registration is server-controlled.
        // Never trust a role value coming from the browser.
        String role = "STUDENT";


        User user =
                new User(
                        firstName,
                        lastName,
                        email,
                        phone,
                        password,
                        role
                );

        try {

            String validationError =
                    userService.registerUser(
                            user,
                            confirmPassword
                    );


            if (validationError != null) {

                request.setAttribute(
                        "errorMessage",
                        validationError
                );

                /*
                 * Keep entered data
                 */
                request.setAttribute(
                        "firstName",
                        firstName
                );

                request.setAttribute(
                        "lastName",
                        lastName
                );

                request.setAttribute(
                        "email",
                        email
                );

                request.setAttribute(
                        "phone",
                        phone
                );

                request.setAttribute(
                        "role",
                        role
                );


                request.getRequestDispatcher(
                        "/register.jsp"
                ).forward(
                        request,
                        response
                );

                return;
            }


            /*
             * Registration successful
             */
            response.sendRedirect(
                    request.getContextPath()
                            + "/login.jsp?registered=true"
            );


        } catch (SQLException e) {

            e.printStackTrace();

            request.setAttribute(
                    "errorMessage",
                    "Database error occurred. Please try again."
            );

            request.getRequestDispatcher(
                    "/register.jsp"
            ).forward(
                    request,
                    response
            );
        }
    }
}