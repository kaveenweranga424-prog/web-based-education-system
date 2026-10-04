package servlet;

import model.Invoice;
import model.Payment;
import service.FeeService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;

/**
 * Administrative Staff (and Admin): view outstanding balances and record payments.
 */
@WebServlet("/staff/payments")
public class PaymentServlet extends HttpServlet {

    private FeeService feeService;

    @Override
    public void init() {
        feeService = new FeeService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isStaffOrAdmin(request)) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        try {
            List<Invoice> outstanding = feeService.findOutstandingInvoices();
            List<Payment> recentPayments = feeService.findAllPayments();

            request.setAttribute("outstanding", outstanding);
            request.setAttribute("recentPayments", recentPayments);

            request.getRequestDispatcher("/staff/record-payment.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("/staff/record-payment.jsp").forward(request, response);
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
        if ("delete".equals(action)) {
            try {
                int paymentId = Integer.parseInt(request.getParameter("paymentId"));
                feeService.deletePayment(paymentId);
                response.sendRedirect(request.getContextPath() + "/staff/payments");
                return;
            } catch (Exception e) {
                e.printStackTrace();
                response.sendRedirect(request.getContextPath() + "/staff/payments");
                return;
            }
        } else if ("update".equals(action)) {
            try {
                int paymentId = Integer.parseInt(request.getParameter("paymentId"));
                BigDecimal amountPaid = new BigDecimal(request.getParameter("amountPaid"));
                String paymentMethod = request.getParameter("paymentMethod");
                String error = feeService.updatePayment(paymentId, amountPaid, paymentMethod);
                if (error != null) {
                    request.setAttribute("errorMessage", error);
                    request.setAttribute("outstanding", feeService.findOutstandingInvoices());
                    request.setAttribute("recentPayments", feeService.findAllPayments());
                    request.getRequestDispatcher("/staff/record-payment.jsp").forward(request, response);
                    return;
                }
                response.sendRedirect(request.getContextPath() + "/staff/payments");
                return;
            } catch (Exception e) {
                e.printStackTrace();
                response.sendRedirect(request.getContextPath() + "/staff/payments");
                return;
            }
        }

        try {
            int invoiceId = Integer.parseInt(request.getParameter("invoiceId"));
            BigDecimal amountPaid = new BigDecimal(request.getParameter("amountPaid"));
            String paymentMethod = request.getParameter("paymentMethod");

            int[] outPaymentId = new int[1];
            String errorMessage = feeService.recordPayment(invoiceId, amountPaid, paymentMethod, staffId, outPaymentId);

            if (errorMessage != null) {
                request.setAttribute("errorMessage", errorMessage);
                request.setAttribute("outstanding", feeService.findOutstandingInvoices());
                request.setAttribute("recentPayments", feeService.findAllPayments());
                request.getRequestDispatcher("/staff/record-payment.jsp").forward(request, response);
                return;
            }

            // Straight to the printable receipt after a successful payment
            response.sendRedirect(request.getContextPath() + "/staff/receipt?paymentId=" + outPaymentId[0]);

        } catch (NumberFormatException e) {
            request.setAttribute("errorMessage", "Please enter a valid payment amount.");
            response.sendRedirect(request.getContextPath() + "/staff/payments");
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            response.sendRedirect(request.getContextPath() + "/staff/payments");
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