package servlet;

import model.Class;
import service.ClassService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Browse/search/filter the class catalogue. Available to any logged-in user.
 */
@WebServlet("/classes")
public class ClassCatalogueServlet extends HttpServlet {

    private ClassService classService;

    @Override
    public void init() {
        classService = new ClassService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String subject = request.getParameter("subject");
        String tutorName = request.getParameter("tutorName");
        String batch = request.getParameter("batch");
        String classType = request.getParameter("classType");

        try {
            List<Class> classes = classService.search(subject, tutorName, batch, classType);

            request.setAttribute("classes", classes);
            request.setAttribute("subject", subject);
            request.setAttribute("tutorName", tutorName);
            request.setAttribute("batch", batch);
            request.setAttribute("classType", classType);

            request.getRequestDispatcher("/class-catalogue.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("/class-catalogue.jsp").forward(request, response);
        }
    }
}