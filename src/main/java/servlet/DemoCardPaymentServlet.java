package servlet;

import model.BankSlipPayment;
import service.EnrollmentPaymentService;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.sql.SQLException;
import java.util.UUID;

@WebServlet("/student/payment")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 10 * 1024 * 1024,
        maxRequestSize = 15 * 1024 * 1024
)
public class DemoCardPaymentServlet extends HttpServlet {
    private EnrollmentPaymentService paymentService;

    @Override
    public void init() {
        paymentService = new EnrollmentPaymentService();
    }

    private HttpSession requireStudent(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return null;
        }
        if (!"STUDENT".equalsIgnoreCase(String.valueOf(session.getAttribute("userRole")))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return null;
        }
        return session;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = requireStudent(request, response);
        if (session == null) return;
        try {
            int enrollmentId = Integer.parseInt(request.getParameter("enrollmentId"));
            int studentId = ((Number) session.getAttribute("userId")).intValue();
            String userName = String.valueOf(session.getAttribute("userName") != null ? session.getAttribute("userName") : "");
            renderForm(request, response, enrollmentId, studentId, null, userName, "Commercial Bank", "", "");
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = requireStudent(request, response);
        if (session == null) return;
        request.setCharacterEncoding("UTF-8");
        try {
            int enrollmentId = Integer.parseInt(request.getParameter("enrollmentId"));
            int studentId = ((Number) session.getAttribute("userId")).intValue();

            String depositorName = request.getParameter("depositorName");
            String bankName = request.getParameter("bankName");
            String branchName = request.getParameter("branchName");
            String referenceNumber = request.getParameter("referenceNumber");

            Part slipPart = null;
            try {
                slipPart = request.getPart("slipFile");
            } catch (Exception ignored) {}

            if (depositorName == null || depositorName.isBlank()) {
                renderForm(request, response, enrollmentId, studentId, "Depositor / Student name is required.", depositorName, bankName, branchName, referenceNumber);
                return;
            }
            if (bankName == null || bankName.isBlank()) {
                renderForm(request, response, enrollmentId, studentId, "Bank name is required.", depositorName, bankName, branchName, referenceNumber);
                return;
            }
            if (referenceNumber == null || referenceNumber.isBlank()) {
                renderForm(request, response, enrollmentId, studentId, "Reference number / Slip number is required.", depositorName, bankName, branchName, referenceNumber);
                return;
            }
            if (slipPart == null || slipPart.getSize() <= 0) {
                renderForm(request, response, enrollmentId, studentId, "Please select and upload your bank deposit slip or transfer receipt.", depositorName, bankName, branchName, referenceNumber);
                return;
            }

            String slipPath = saveSlipFile(request, slipPart);
            if (slipPath == null) {
                renderForm(request, response, enrollmentId, studentId, "Invalid file format. Only JPG, PNG, WEBP, or PDF files up to 10MB are accepted.", depositorName, bankName, branchName, referenceNumber);
                return;
            }

            BankSlipPayment slip = new BankSlipPayment(depositorName.trim(), bankName.trim(), branchName, referenceNumber.trim(), slipPath);
            EnrollmentPaymentService.SubmissionResult result = paymentService.submitSlipPayment(enrollmentId, studentId, slip);

            if (result.error() != null) {
                renderForm(request, response, enrollmentId, studentId, result.error(), depositorName, bankName, branchName, referenceNumber);
                return;
            }
            session.setAttribute("flashSuccess", "Bank slip submitted successfully! Your class enrollment is waiting for Admin approval.");
            response.sendRedirect(request.getContextPath() + "/student/receipt?paymentId=" + result.paymentId() + "&fromPayment=true");
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    private String saveSlipFile(HttpServletRequest request, Part part) throws IOException {
        if (part == null || part.getSize() <= 0) return null;
        String submitted = part.getSubmittedFileName();
        if (submitted == null || submitted.isBlank()) return null;

        String ext = "";
        int dot = submitted.lastIndexOf('.');
        if (dot >= 0) ext = submitted.substring(dot).toLowerCase();

        if (!ext.equals(".jpg") && !ext.equals(".jpeg") && !ext.equals(".png") && !ext.equals(".webp") && !ext.equals(".pdf")) {
            return null;
        }

        String uniqueName = "slip_" + System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 8) + ext;
        String webappSubdir = "uploads" + File.separator + "slips";
        String realPath = request.getServletContext().getRealPath("/" + webappSubdir);
        File uploadDir = (realPath != null) ? new File(realPath) : new File("src/main/webapp/" + webappSubdir);
        if (!uploadDir.exists()) uploadDir.mkdirs();

        File targetFile = new File(uploadDir, uniqueName);
        try (InputStream in = part.getInputStream(); OutputStream out = new FileOutputStream(targetFile)) {
            in.transferTo(out);
        }

        try {
            File srcDir = new File("C:/Users/New/Desktop/project SE/TutionManegment/src/main/webapp/uploads/slips");
            if (!srcDir.getCanonicalPath().equalsIgnoreCase(uploadDir.getCanonicalPath())) {
                srcDir.mkdirs();
                File srcFile = new File(srcDir, uniqueName);
                Files.copy(targetFile.toPath(), srcFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (Exception ignored) {}

        return "uploads/slips/" + uniqueName;
    }

    private void renderForm(HttpServletRequest request, HttpServletResponse response,
                            int enrollmentId, int studentId, String error,
                            String depositorName, String bankName, String branchName, String referenceNumber)
            throws SQLException, ServletException, IOException {
        EnrollmentPaymentService.PaymentPreparation prep =
                paymentService.prepareDemoPayment(enrollmentId, studentId);
        if (prep.error() != null) {
            request.getSession().setAttribute("flashError", prep.error());
            if (prep.enrollment() != null) {
                response.sendRedirect(request.getContextPath() + "/enroll?classId=" + prep.enrollment().getClassId());
            } else {
                response.sendRedirect(request.getContextPath() + "/classes");
            }
            return;
        }
        request.setAttribute("enrollment", prep.enrollment());
        request.setAttribute("invoice", prep.invoice());
        request.setAttribute("classItem", prep.classItem());
        request.setAttribute("paymentError", error);
        request.setAttribute("depositorName", depositorName == null ? "" : depositorName);
        request.setAttribute("bankName", bankName == null ? "Commercial Bank" : bankName);
        request.setAttribute("branchName", branchName == null ? "" : branchName);
        request.setAttribute("referenceNumber", referenceNumber == null ? "" : referenceNumber);
        request.getRequestDispatcher("/student/demo-card-payment.jsp").forward(request, response);
    }
}
