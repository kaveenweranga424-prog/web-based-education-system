package service;

import dao.*;
import model.Enrollment;
import model.Invoice;
import model.Payment;
import util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.SQLException;
import java.util.List;
import java.util.Set;

public class FeeService {
    private final InvoiceDAO invoiceDAO=new InvoiceDAO();
    private final PaymentDAO paymentDAO=new PaymentDAO();
    private final EnrollmentDAO enrollmentDAO=new EnrollmentDAO();
    private final ParentStudentDAO parentStudentDAO=new ParentStudentDAO();
    private final NotificationService notificationService=new NotificationService();
    private static final Set<String> VALID_METHODS=Set.of("CASH","BANK_TRANSFER","CARD","ONLINE","OTHER");

    public String generateInvoice(int enrollmentId, BigDecimal amount, Date dueDate, int createdBy)throws SQLException{
        if(amount==null||amount.signum()<=0)return "Invoice amount must be greater than zero.";
        if(dueDate==null)return "Due date is required.";
        if(invoiceDAO.existsForEnrollment(enrollmentId))return "An active invoice already exists for this enrollment.";
        int id=invoiceDAO.createInvoice(enrollmentId,amount,dueDate,createdBy);
        if(id<=0)return "Failed to generate the invoice.";
        Integer studentId=enrollmentDAO.findStudentIdByEnrollment(enrollmentId);
        if(studentId!=null){
            Invoice inv=invoiceDAO.findById(id);
            notificationService.notifyStudentAndParents(studentId,"New fee invoice",
                    "An invoice of "+amount+" for "+(inv!=null?inv.getSubject()+" ("+inv.getBatch()+")":"your class")+" is due by "+dueDate+".",
                    "FEE",inv!=null?inv.getClassId():null);
        }
        return null;
    }

    public boolean cancelInvoice(int id)throws SQLException{return invoiceDAO.cancelInvoice(id);}

    public String recordPayment(int invoiceId,BigDecimal amountPaid,String paymentMethod,int receivedBy,int[] outPaymentId)throws SQLException{
        if(amountPaid==null||amountPaid.signum()<=0)return "Payment amount must be greater than zero.";
        if(paymentMethod==null||!VALID_METHODS.contains(paymentMethod.trim().toUpperCase()))return "Please select a valid payment method.";
        try(Connection c=DBUtil.getConnection()){
            c.setAutoCommit(false);
            try{
                Invoice inv=invoiceDAO.findById(c,invoiceId);
                if(inv==null){c.rollback();return "Invoice not found.";}
                if("PAID".equalsIgnoreCase(inv.getStatus())){c.rollback();return "This invoice is already fully paid.";}
                if("CANCELLED".equalsIgnoreCase(inv.getStatus())){c.rollback();return "This invoice has been cancelled.";}
                BigDecimal total=inv.getAmountPaid().add(amountPaid);
                if(total.compareTo(inv.getAmount())>0){c.rollback();return "Payment amount exceeds the outstanding balance of "+inv.getBalance()+".";}
                int id=paymentDAO.recordPayment(c,invoiceId,amountPaid,paymentMethod.trim().toUpperCase(),receivedBy);
                if(id<=0){c.rollback();return "Failed to record payment.";}
                invoiceDAO.updateStatus(c,invoiceId,total.compareTo(inv.getAmount())==0?"PAID":"PARTIAL");
                c.commit();outPaymentId[0]=id;return null;
            }catch(SQLException e){c.rollback();throw e;}
        }
    }

    public String deletePayment(int paymentId) throws SQLException {
        try (Connection c = DBUtil.getConnection()) {
            c.setAutoCommit(false);
            try {
                Payment p = paymentDAO.findById(c, paymentId, true);
                if (p == null) { c.rollback(); return "Payment record not found."; }
                Invoice inv = invoiceDAO.findById(c, p.getInvoiceId());
                if (!paymentDAO.deletePayment(c, paymentId)) {
                    c.rollback(); return "Failed to delete payment record.";
                }
                if (inv != null) {
                    BigDecimal remainingPaid = inv.getAmountPaid().subtract(p.getAmountPaid());
                    if (remainingPaid.compareTo(BigDecimal.ZERO) < 0) remainingPaid = BigDecimal.ZERO;
                    String newStatus = remainingPaid.compareTo(BigDecimal.ZERO) == 0 ? "UNPAID" : "PARTIAL";
                    invoiceDAO.updateStatus(c, inv.getInvoiceId(), newStatus);
                }
                c.commit();
                return null;
            } catch (SQLException e) {
                c.rollback(); throw e;
            }
        }
    }

    public String updatePayment(int paymentId, BigDecimal newAmount, String paymentMethod) throws SQLException {
        if (newAmount == null || newAmount.signum() <= 0) return "Payment amount must be greater than zero.";
        if (paymentMethod == null || !VALID_METHODS.contains(paymentMethod.trim().toUpperCase())) return "Invalid payment method.";
        try (Connection c = DBUtil.getConnection()) {
            c.setAutoCommit(false);
            try {
                Payment p = paymentDAO.findById(c, paymentId, true);
                if (p == null) { c.rollback(); return "Payment record not found."; }
                Invoice inv = invoiceDAO.findById(c, p.getInvoiceId());
                if (inv == null) { c.rollback(); return "Associated invoice not found."; }
                BigDecimal newTotal = inv.getAmountPaid().subtract(p.getAmountPaid()).add(newAmount);
                if (newTotal.compareTo(inv.getAmount()) > 0) {
                    c.rollback(); return "New amount exceeds the invoice total.";
                }
                if (!paymentDAO.updatePaymentRecord(c, paymentId, newAmount, paymentMethod.trim().toUpperCase())) {
                    c.rollback(); return "Failed to update payment record.";
                }
                String newStatus = newTotal.compareTo(inv.getAmount()) == 0 ? "PAID" : (newTotal.compareTo(BigDecimal.ZERO) == 0 ? "UNPAID" : "PARTIAL");
                invoiceDAO.updateStatus(c, inv.getInvoiceId(), newStatus);
                c.commit();
                return null;
            } catch (SQLException e) {
                c.rollback(); throw e;
            }
        }
    }

    public Invoice findInvoiceById(int id)throws SQLException{return invoiceDAO.findById(id);}
    public List<Invoice> findAllInvoices()throws SQLException{return invoiceDAO.findAll();}
    public List<Invoice> findOutstandingInvoices()throws SQLException{return invoiceDAO.findOutstanding();}
    public List<Invoice> findInvoicesByStudent(int id)throws SQLException{return invoiceDAO.findByStudent(id);}
    public List<Payment> findPaymentsByInvoice(int id)throws SQLException{return paymentDAO.findByInvoice(id);}
    public List<Payment> findPaymentsByStudent(int id)throws SQLException{return paymentDAO.findByStudent(id);}
    public List<Payment> findAllPayments()throws SQLException{return paymentDAO.findAll();}
    public Payment findPaymentById(int id)throws SQLException{return paymentDAO.findById(id);}
    public boolean paymentBelongsToStudent(int paymentId,int studentId)throws SQLException{
        Payment p=paymentDAO.findById(paymentId);return p!=null&&p.getStudentId()==studentId;
    }
    public boolean parentCanViewStudent(int parentId,int studentId)throws SQLException{
        return parentStudentDAO.findActiveStudentIdsForParent(parentId).contains(studentId);
    }
    public List<Enrollment> findAllActiveEnrollmentsForInvoicing()throws SQLException{return enrollmentDAO.findByClass(-1);}
}
