package servlet;

import model.Class;
import model.Enrollment;
import model.Invoice;
import service.ClassService;
import service.EnrollmentService;
import service.FeeService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Date;
import java.sql.SQLException;
import java.util.List;

/**
 * Administrative Staff (and Admin): generate and cancel fee invoices.
 */
@WebServlet("/staff/invoices")
public class InvoiceServlet extends HttpServlet {

    private FeeService feeService;
    private ClassService classService;
    private EnrollmentService enrollmentService;

    @Override
    public void init() {
        feeService = new FeeService();
        classService = new ClassService();
        enrollmentService = new EnrollmentService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isStaffOrAdmin(request)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        try {
            List<Invoice> invoices = feeService.findAllInvoices();
            List<Class> classes = classService.findAll();

            request.setAttribute("invoices", invoices);
            request.setAttribute("classes", classes);

            String classIdParam = request.getParameter("classId");

            if (classIdParam != null && !classIdParam.isBlank()) {
                int classId = Integer.parseInt(classIdParam);
                List<Enrollment> enrollments = enrollmentService.findByClass(classId);
                request.setAttribute("enrollments", enrollments);
                request.setAttribute("selectedClassId", classId);
            }

            request.getRequestDispatcher("/staff/manage-invoices.jsp").forward(request, response);

        } catch (SQLException | NumberFormatException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("/staff/manage-invoices.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isStaffOrAdmin(request)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        int staffId = (int) session.getAttribute("userId");

        String action = request.getParameter("action");

        try {
            if ("cancel".equals(action)) {
                int invoiceId = Integer.parseInt(request.getParameter("invoiceId"));
                feeService.cancelInvoice(invoiceId);
                response.sendRedirect(request.getContextPath() + "/staff/invoices");
                return;
            }

            int enrollmentId = Integer.parseInt(request.getParameter("enrollmentId"));
            BigDecimal amount = new BigDecimal(request.getParameter("amount"));
            Date dueDate = Date.valueOf(request.getParameter("dueDate"));

            String errorMessage = feeService.generateInvoice(enrollmentId, amount, dueDate, staffId);

            if (errorMessage != null) {
                request.setAttribute("errorMessage", errorMessage);
                request.setAttribute("invoices", feeService.findAllInvoices());
                request.setAttribute("classes", classService.findAll());
                request.getRequestDispatcher("/staff/manage-invoices.jsp").forward(request, response);
                return;
            }

            response.sendRedirect(request.getContextPath() + "/staff/invoices");

        } catch (IllegalArgumentException e) {
            request.setAttribute("errorMessage", "Please check the amount and due date.");
            response.sendRedirect(request.getContextPath() + "/staff/invoices");
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            response.sendRedirect(request.getContextPath() + "/staff/invoices");
        }
    }

    private boolean isStaffOrAdmin(HttpServletRequest request) {
        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userRole") == null) {
            return false;
        }

        String role = String.valueOf(session.getAttribute("userRole"));
        return "ADMIN".equalsIgnoreCase(role);
    }
}