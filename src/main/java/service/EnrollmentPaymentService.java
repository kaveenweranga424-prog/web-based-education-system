package service;

import dao.ClassDAO;
import dao.EnrollmentDAO;
import dao.InvoiceDAO;
import dao.PaymentDAO;
import model.BankSlipPayment;
import model.DemoCardPayment;
import model.Enrollment;
import model.Invoice;
import model.Payment;
import util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;

public class EnrollmentPaymentService {
    private final EnrollmentDAO enrollmentDAO = new EnrollmentDAO();
    private final InvoiceDAO invoiceDAO = new InvoiceDAO();
    private final PaymentDAO paymentDAO = new PaymentDAO();
    private final ClassDAO classDAO = new ClassDAO();
    private final NotificationService notificationService = new NotificationService();

    public PaymentPreparation prepareDemoPayment(int enrollmentId, int studentId) throws SQLException {
        Enrollment enrollment = enrollmentDAO.findById(enrollmentId);
        if (enrollment == null || enrollment.getStudentId() != studentId) {
            return new PaymentPreparation("Enrollment request was not found.", null, null, null);
        }
        if (!"PENDING_PAYMENT".equalsIgnoreCase(enrollment.getStatus())) {
            return new PaymentPreparation("This request is not waiting for payment.", null, null, null);
        }

        Invoice invoice = invoiceDAO.findByEnrollment(enrollmentId);
        if (invoice == null || invoice.getAmount() == null) {
            return new PaymentPreparation("Invoice was not found.", null, null, null);
        }

        model.Class classItem = classDAO.findById(enrollment.getClassId());
        if (classItem == null) {
            return new PaymentPreparation("Class data was not found.", null, null, null);
        }

        return new PaymentPreparation(null, enrollment, invoice, classItem);
    }

    public String validateDemoCard(DemoCardPayment card) {
        if (card == null || card.cardHolderName() == null || card.cardHolderName().isBlank()) {
            return "Card holder name is required.";
        }
        if (card.cardHolderName().trim().length() > 120) {
            return "Card holder name is too long.";
        }

        String digits = normalizeCardNumber(card.cardNumber());
        if (!digits.matches("\\d{13,19}")) {
            return "Enter a valid card number.";
        }

        String normalizedExpiry = DemoCardPayment.normalizeExpiry(card.expiry());
        if (normalizedExpiry.isEmpty()) {
            return "Enter a valid expiry date.";
        }
        try {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MM/yy");
            YearMonth expiry = YearMonth.parse(normalizedExpiry, formatter);
            if (expiry.isBefore(YearMonth.now())) {
                return "Card expiry date has passed.";
            }
        } catch (DateTimeParseException e) {
            return "Enter a valid expiry date.";
        }

        if (card.cvv() == null || !card.cvv().trim().matches("\\d{3,4}")) {
            return "Enter a valid CVV.";
        }
        return null;
    }

    public static String maskCard(String cardNumber) {
        String digits = normalizeCardNumber(cardNumber);
        if (digits.length() < 4) return "****";
        return "**** **** **** " + digits.substring(digits.length() - 4);
    }

    private static String normalizeCardNumber(String value) {
        return value == null ? "" : value.replaceAll("[^0-9]", "");
    }

    public SubmissionResult submitSlipPayment(int enrollmentId, int studentId, BankSlipPayment slip) throws SQLException {
        if (slip == null || !slip.isValid()) {
            return new SubmissionResult("Please provide depositor name, bank name, reference number, and a valid slip file.", -1);
        }
        if (slip.depositorName().length() > 120) {
            return new SubmissionResult("Depositor name is too long.", -1);
        }
        if (slip.referenceNumber().length() > 100) {
            return new SubmissionResult("Reference number is too long.", -1);
        }

        int paymentId;
        int notifyClassId;
        try (Connection c = DBUtil.getConnection()) {
            c.setAutoCommit(false);
            try {
                Enrollment enrollment = enrollmentDAO.findById(c, enrollmentId);
                if (enrollment == null || enrollment.getStudentId() != studentId) {
                    c.rollback();
                    return new SubmissionResult("Enrollment request was not found.", -1);
                }
                if (!"PENDING_PAYMENT".equalsIgnoreCase(enrollment.getStatus())) {
                    c.rollback();
                    return new SubmissionResult("This request is not waiting for payment.", -1);
                }

                Invoice invoice = invoiceDAO.findByEnrollment(c, enrollmentId);
                if (invoice == null || invoice.getAmount() == null || invoice.getAmount().signum() <= 0) {
                    c.rollback();
                    return new SubmissionResult("Invoice was not found.", -1);
                }

                Payment existing = paymentDAO.findByEnrollment(c, enrollmentId);
                if (existing != null && ("DEMO_SUBMITTED".equalsIgnoreCase(existing.getGatewayStatus())
                        || "SLIP_SUBMITTED".equalsIgnoreCase(existing.getGatewayStatus())
                        || "SUCCESS".equalsIgnoreCase(existing.getGatewayStatus()))) {
                    c.rollback();
                    return new SubmissionResult("A payment slip has already been submitted for this request.", existing.getPaymentId());
                }

                paymentId = paymentDAO.createSlipPayment(
                        c,
                        invoice.getInvoiceId(),
                        invoice.getAmount(),
                        slip.depositorName(),
                        slip.bankName(),
                        slip.branchName(),
                        slip.referenceNumber(),
                        slip.slipPath()
                );
                if (paymentId <= 0) {
                    c.rollback();
                    return new SubmissionResult("Could not submit the payment slip.", -1);
                }

                if (!enrollmentDAO.updateStatus(c, enrollmentId, "PENDING_PAYMENT", "PAID_PENDING_ADMIN")) {
                    c.rollback();
                    return new SubmissionResult("Enrollment status changed. Refresh and try again.", -1);
                }
                invoiceDAO.updateStatus(c, invoice.getInvoiceId(), "PAID");
                notifyClassId = enrollment.getClassId();
                c.commit();
            } catch (SQLException e) {
                c.rollback();
                throw e;
            }
        }

        notificationService.notifyStudentAndParents(
                studentId,
                "Payment slip submitted",
                "Your bank payment slip was submitted and is waiting for admin approval.",
                "PAYMENT",
                notifyClassId
        );
        notificationService.notifyAdmins(
                "Payment Slip Pending Approval",
                "A new bank payment slip was uploaded and is waiting for your review in Enrollment Approvals.",
                "PAYMENT",
                notifyClassId
        );
        return new SubmissionResult(null, paymentId);
    }

    public SubmissionResult submitDemoPayment(int enrollmentId, int studentId, DemoCardPayment card) throws SQLException {
        String validationError = validateDemoCard(card);
        if (validationError != null) return new SubmissionResult(validationError, -1);

        int paymentId;
        int notifyClassId;
        try (Connection c = DBUtil.getConnection()) {
            c.setAutoCommit(false);
            try {
                Enrollment enrollment = enrollmentDAO.findById(c, enrollmentId);
                if (enrollment == null || enrollment.getStudentId() != studentId) {
                    c.rollback();
                    return new SubmissionResult("Enrollment request was not found.", -1);
                }
                if (!"PENDING_PAYMENT".equalsIgnoreCase(enrollment.getStatus())) {
                    c.rollback();
                    return new SubmissionResult("This request is not waiting for payment.", -1);
                }

                Invoice invoice = invoiceDAO.findByEnrollment(c, enrollmentId);
                if (invoice == null || invoice.getAmount() == null || invoice.getAmount().signum() <= 0) {
                    c.rollback();
                    return new SubmissionResult("Invoice was not found.", -1);
                }

                Payment existing = paymentDAO.findByEnrollment(c, enrollmentId);
                if (existing != null && ("DEMO_SUBMITTED".equalsIgnoreCase(existing.getGatewayStatus())
                        || "SUCCESS".equalsIgnoreCase(existing.getGatewayStatus()))) {
                    c.rollback();
                    return new SubmissionResult("A payment has already been submitted for this request.", existing.getPaymentId());
                }

                String reference = "DEMO-" + enrollmentId + "-" + System.currentTimeMillis();
                paymentId = paymentDAO.createDemoCardPayment(
                        c,
                        invoice.getInvoiceId(),
                        invoice.getAmount(),
                        card.cardHolderName().trim(),
                        maskCard(card.cardNumber()),
                        reference
                );
                if (paymentId <= 0) {
                    c.rollback();
                    return new SubmissionResult("Could not submit the payment.", -1);
                }

                if (!enrollmentDAO.updateStatus(c, enrollmentId, "PENDING_PAYMENT", "PAID_PENDING_ADMIN")) {
                    c.rollback();
                    return new SubmissionResult("Enrollment status changed. Refresh and try again.", -1);
                }
                invoiceDAO.updateStatus(c, invoice.getInvoiceId(), "PAID");
                notifyClassId = enrollment.getClassId();
                c.commit();
            } catch (SQLException e) {
                c.rollback();
                throw e;
            }
        }

        notificationService.notifyStudentAndParents(
                studentId,
                "Payment submitted",
                "Your card payment was submitted and is waiting for admin approval.",
                "PAYMENT",
                notifyClassId
        );
        notificationService.notifyAdmins(
                "Payment Pending Approval",
                "A new card payment was submitted and is waiting for your approval in Enrollment Approvals.",
                "PAYMENT",
                notifyClassId
        );
        return new SubmissionResult(null, paymentId);
    }

    public String confirmByStaff(int paymentId, int staffId) throws SQLException {
        return staffDecision(paymentId, staffId, true, null);
    }

    public String cancelByStaff(int paymentId, int staffId, String reason) throws SQLException {
        if (reason == null || reason.isBlank()) return "A cancellation reason is required.";
        if (reason.length() > 500) return "Cancellation reason is too long.";
        return staffDecision(paymentId, staffId, false, reason.trim());
    }

    /** Backward-compatible alias for older servlet code. */
    public String rejectByStaff(int paymentId, int staffId, String reason) throws SQLException {
        return cancelByStaff(paymentId, staffId, reason);
    }

    private String staffDecision(int paymentId, int staffId, boolean confirm, String note) throws SQLException {
        int studentId;
        int classId;
        String nextEnrollment = confirm ? "STAFF_CONFIRMED" : "REJECTED";
        String staffStatus = confirm ? "CONFIRMED" : "CANCELLED";

        try (Connection c = DBUtil.getConnection()) {
            c.setAutoCommit(false);
            try {
                Payment payment = paymentDAO.findById(c, paymentId, true);
                if (payment == null) {
                    c.rollback();
                    return "Payment not found.";
                }
                Invoice invoice = invoiceDAO.findById(c, payment.getInvoiceId());
                Enrollment enrollment = invoice == null ? null : enrollmentDAO.findById(c, invoice.getEnrollmentId());
                boolean acceptedPayment = "DEMO_SUBMITTED".equalsIgnoreCase(payment.getGatewayStatus())
                        || "SUCCESS".equalsIgnoreCase(payment.getGatewayStatus());
                if (!acceptedPayment || !"PENDING".equalsIgnoreCase(payment.getStaffStatus())
                        || enrollment == null || !"PAID_PENDING_STAFF".equalsIgnoreCase(enrollment.getStatus())) {
                    c.rollback();
                    return "Payment is not waiting for staff confirmation.";
                }

                if (!paymentDAO.updateStaffDecision(c, paymentId, staffStatus, note, staffId)
                        || !enrollmentDAO.updateStatus(c, enrollment.getEnrollmentId(), "PAID_PENDING_STAFF", nextEnrollment)) {
                    c.rollback();
                    return "Payment status changed. Refresh and try again.";
                }
                if (!confirm) {
                    paymentDAO.updateGatewayStatus(c, paymentId, "CANCELLED");
                    invoiceDAO.updateStatus(c, invoice.getInvoiceId(), "CANCELLED");
                }
                studentId = enrollment.getStudentId();
                classId = enrollment.getClassId();
                c.commit();
            } catch (SQLException e) {
                c.rollback();
                throw e;
            }
        }

        notificationService.notifyStudentAndParents(
                studentId,
                confirm ? "Payment confirmed" : "Payment cancelled",
                confirm
                        ? "Your payment was confirmed by staff and is waiting for admin approval."
                        : "Your payment request was cancelled by staff. " + note,
                "PAYMENT",
                classId
        );
        if (confirm) {
            notificationService.notifyAdmins(
                    "Payment Confirmed - Enrollment Pending Approval",
                    "Staff confirmed payment #" + paymentId + ". Enrollment is waiting for your final approval.",
                    "ENROLLMENT",
                    classId
            );
        }
        return null;
    }

    public String approveByAdmin(int paymentId, int adminId) throws SQLException {
        return adminDecision(paymentId, adminId, true, null);
    }

    public String rejectByAdmin(int paymentId, int adminId, String reason) throws SQLException {
        if (reason == null || reason.isBlank()) return "A rejection reason is required.";
        if (reason.length() > 500) return "Rejection reason is too long.";
        return adminDecision(paymentId, adminId, false, reason.trim());
    }

    private String adminDecision(int paymentId, int adminId, boolean approve, String note) throws SQLException {
        int studentId;
        int classId;
        try (Connection c = DBUtil.getConnection()) {
            c.setAutoCommit(false);
            try {
                Payment payment = paymentDAO.findById(c, paymentId, true);
                if (payment == null) {
                    c.rollback();
                    return "Payment not found.";
                }
                Invoice invoice = invoiceDAO.findById(c, payment.getInvoiceId());
                Enrollment enrollment = invoice == null ? null : enrollmentDAO.findById(c, invoice.getEnrollmentId());
                boolean acceptedPayment = "DEMO_SUBMITTED".equalsIgnoreCase(payment.getGatewayStatus())
                        || "SUCCESS".equalsIgnoreCase(payment.getGatewayStatus());
                boolean isPendingAdminStatus = "PAID_PENDING_ADMIN".equalsIgnoreCase(enrollment.getStatus())
                        || "STAFF_CONFIRMED".equalsIgnoreCase(enrollment.getStatus())
                        || "PAID_PENDING_STAFF".equalsIgnoreCase(enrollment.getStatus());
                if (!acceptedPayment || !"PENDING".equalsIgnoreCase(payment.getAdminStatus())
                        || enrollment == null || !isPendingAdminStatus) {
                    c.rollback();
                    return "Enrollment is not waiting for admin approval.";
                }

                String decision = approve ? "APPROVED" : "REJECTED";
                if (!paymentDAO.updateAdminDecision(c, paymentId, decision, note, adminId)) {
                    c.rollback();
                    return "Approval state changed. Refresh and try again.";
                }

                String currentStatus = enrollment.getStatus();
                boolean ok = approve
                        ? enrollmentDAO.updateStatusAndEnrolledAt(c, enrollment.getEnrollmentId(), currentStatus, "ACTIVE")
                        : enrollmentDAO.updateStatus(c, enrollment.getEnrollmentId(), currentStatus, "REJECTED");
                if (!ok) {
                    c.rollback();
                    return "Enrollment state changed. Refresh and try again.";
                }
                if (!approve) {
                    paymentDAO.updateGatewayStatus(c, paymentId, "CANCELLED");
                    invoiceDAO.updateStatus(c, invoice.getInvoiceId(), "CANCELLED");
                }

                studentId = enrollment.getStudentId();
                classId = enrollment.getClassId();
                c.commit();
            } catch (SQLException e) {
                c.rollback();
                throw e;
            }
        }

        notificationService.notifyStudentAndParents(
                studentId,
                approve ? "Enrollment approved" : "Enrollment rejected",
                approve
                        ? "Your enrollment is approved. You can now access the class and its materials."
                        : "Your enrollment request was rejected by admin. " + note,
                "ENROLLMENT",
                classId
        );
        return null;
    }

    public List<Payment> findPendingStaff() throws SQLException {
        return paymentDAO.findSuccessfulPendingStaff();
    }

    public List<Payment> findPendingAdmin() throws SQLException {
        return paymentDAO.findStaffConfirmedPendingAdmin();
    }

    public Payment findById(int paymentId) throws SQLException {
        return paymentDAO.findById(paymentId);
    }

    public record PaymentPreparation(String error, Enrollment enrollment, Invoice invoice, model.Class classItem) {}
    public record SubmissionResult(String error, int paymentId) {}
}
