package dao;

import model.Payment;
import util.DBUtil;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PaymentDAO {
    private static final String BASE_SELECT = """
        SELECT p.payment_id,p.invoice_id,p.amount_paid,p.payment_method,p.payment_date,p.received_by,
               p.card_holder_name,p.gateway_order_id,p.gateway_payment_id,p.gateway_status,p.gateway_method,p.masked_card_no,
               p.staff_status,p.staff_note,p.confirmed_by,p.confirmed_at,
               p.admin_status,p.admin_note,p.approved_by,p.approved_at,
               p.slip_path,p.bank_name,p.branch_name,
               e.student_id,e.class_id,c.subject,c.batch,
               su.first_name AS student_first,su.last_name AS student_last,
               ru.first_name AS receiver_first,ru.last_name AS receiver_last,
               cu.first_name AS confirmer_first,cu.last_name AS confirmer_last,
               au.first_name AS approver_first,au.last_name AS approver_last
        FROM dbo.payments p
        JOIN dbo.invoices i ON i.invoice_id=p.invoice_id
        JOIN dbo.enrollments e ON e.enrollment_id=i.enrollment_id
        JOIN dbo.classes c ON c.class_id=e.class_id
        JOIN dbo.users su ON su.user_id=e.student_id
        LEFT JOIN dbo.users ru ON ru.user_id=p.received_by
        LEFT JOIN dbo.users cu ON cu.user_id=p.confirmed_by
        LEFT JOIN dbo.users au ON au.user_id=p.approved_by
        """;

    public int recordPayment(Connection c,int invoiceId,BigDecimal amount,String method,int receivedBy)throws SQLException{
        String sql="""
            INSERT INTO dbo.payments(invoice_id,amount_paid,payment_method,payment_date,received_by,
                                     gateway_status,staff_status,admin_status)
            VALUES(?,?,?,GETDATE(),?,'SUCCESS','CONFIRMED','APPROVED')
            """;
        try(PreparedStatement s=c.prepareStatement(sql,Statement.RETURN_GENERATED_KEYS)){
            s.setInt(1,invoiceId); s.setBigDecimal(2,amount); s.setString(3,method); s.setInt(4,receivedBy);
            if(s.executeUpdate()>0){ try(ResultSet k=s.getGeneratedKeys()){ if(k.next()) return k.getInt(1); } }
        }
        return -1;
    }

    public int createDemoCardPayment(Connection c,int invoiceId,BigDecimal amount,String cardHolderName,
                                     String maskedCardNo,String reference)throws SQLException{
        String sql="""
            INSERT INTO dbo.payments(invoice_id,amount_paid,payment_method,payment_date,received_by,
                                     card_holder_name,gateway_order_id,gateway_status,gateway_method,masked_card_no,
                                     staff_status,admin_status)
            VALUES(?,?,'CARD',GETDATE(),NULL,?,?,'DEMO_SUBMITTED',NULL,?,'CONFIRMED','PENDING')
            """;
        try(PreparedStatement s=c.prepareStatement(sql,Statement.RETURN_GENERATED_KEYS)){
            s.setInt(1,invoiceId);
            s.setBigDecimal(2,amount);
            s.setString(3,cardHolderName);
            s.setString(4,reference);
            s.setString(5,maskedCardNo);
            if(s.executeUpdate()>0){ try(ResultSet k=s.getGeneratedKeys()){ if(k.next()) return k.getInt(1); } }
        }
        return -1;
    }

    public int createSlipPayment(Connection c, int invoiceId, BigDecimal amount, String payerName,
                                 String bankName, String branchName, String reference, String slipPath) throws SQLException {
        String sql = """
            INSERT INTO dbo.payments(invoice_id, amount_paid, payment_method, payment_date, received_by,
                                     card_holder_name, gateway_order_id, gateway_status, gateway_method, masked_card_no,
                                     staff_status, admin_status, slip_path, bank_name, branch_name)
            VALUES(?, ?, 'BANK_TRANSFER', GETDATE(), NULL, ?, ?, 'DEMO_SUBMITTED', 'SLIP_UPLOAD', NULL,
                   'CONFIRMED', 'PENDING', ?, ?, ?)
            """;
        try (PreparedStatement s = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            s.setInt(1, invoiceId);
            s.setBigDecimal(2, amount);
            s.setString(3, payerName != null ? payerName.trim() : null);
            s.setString(4, reference != null ? reference.trim() : null);
            s.setString(5, slipPath != null ? slipPath.trim() : null);
            s.setString(6, bankName != null ? bankName.trim() : null);
            s.setString(7, branchName != null ? branchName.trim() : null);
            if (s.executeUpdate() > 0) {
                try (ResultSet k = s.getGeneratedKeys()) {
                    if (k.next()) return k.getInt(1);
                }
            }
        }
        return -1;
    }

    public Payment findById(int id)throws SQLException{ try(Connection c=DBUtil.getConnection()){ return findById(c,id,false); } }
    public Payment findById(Connection c,int id,boolean forUpdate)throws SQLException{
        String sql=BASE_SELECT+" WHERE p.payment_id=?";
        try(PreparedStatement s=c.prepareStatement(sql)){ s.setInt(1,id); try(ResultSet r=s.executeQuery()){ return r.next()?map(r):null; } }
    }

    public Payment findByEnrollment(int enrollmentId)throws SQLException{
        try(Connection c=DBUtil.getConnection()){ return findByEnrollment(c,enrollmentId); }
    }

    public Payment findByEnrollment(Connection c,int enrollmentId)throws SQLException{
        String sql=BASE_SELECT+" WHERE i.enrollment_id=? ORDER BY p.payment_id DESC";
        try(PreparedStatement s=c.prepareStatement(sql)){
            s.setInt(1,enrollmentId); try(ResultSet r=s.executeQuery()){ return r.next()?map(r):null; }
        }
    }

    public boolean updateGatewayStatus(Connection c,int paymentId,String gatewayStatus)throws SQLException{
        try(PreparedStatement s=c.prepareStatement("UPDATE dbo.payments SET gateway_status=? WHERE payment_id=?")){
            s.setString(1,gatewayStatus); s.setInt(2,paymentId); return s.executeUpdate()>0;
        }
    }

    public boolean updateStaffDecision(Connection c,int paymentId,String status,String note,int staffId)throws SQLException{
        String sql="UPDATE dbo.payments SET staff_status=?,staff_note=?,confirmed_by=?,confirmed_at=GETDATE() WHERE payment_id=? AND staff_status='PENDING'";
        try(PreparedStatement s=c.prepareStatement(sql)){
            s.setString(1,status); s.setString(2,note); s.setInt(3,staffId); s.setInt(4,paymentId); return s.executeUpdate()>0;
        }
    }

    public boolean updateAdminDecision(Connection c,int paymentId,String status,String note,int adminId)throws SQLException{
        String sql="UPDATE dbo.payments SET admin_status=?,admin_note=?,approved_by=?,approved_at=GETDATE() WHERE payment_id=? AND admin_status='PENDING'";
        try(PreparedStatement s=c.prepareStatement(sql)){
            s.setString(1,status); s.setString(2,note); s.setInt(3,adminId); s.setInt(4,paymentId); return s.executeUpdate()>0;
        }
    }

    public List<Payment> findSuccessfulPendingStaff()throws SQLException{
        return list(BASE_SELECT+" WHERE p.gateway_status IN ('DEMO_SUBMITTED','SUCCESS') AND p.staff_status='PENDING' AND e.status='PAID_PENDING_STAFF' ORDER BY p.payment_date",null);
    }
    public List<Payment> findStaffConfirmedPendingAdmin()throws SQLException{
        return list(BASE_SELECT+" WHERE p.gateway_status IN ('DEMO_SUBMITTED','SUCCESS') AND p.admin_status='PENDING' AND e.status IN ('PAID_PENDING_ADMIN','STAFF_CONFIRMED') ORDER BY p.payment_date DESC",null);
    }
    public List<Payment> findPendingAdmin()throws SQLException{
        return findStaffConfirmedPendingAdmin();
    }

    public List<Payment> findByInvoice(int invoiceId)throws SQLException{ return list(BASE_SELECT+" WHERE p.invoice_id=? ORDER BY p.payment_id DESC",invoiceId); }
    public List<Payment> findByStudent(int studentId)throws SQLException{
        return list(BASE_SELECT+" WHERE e.student_id=? AND p.gateway_status IN ('SUCCESS','DEMO_SUBMITTED','CANCELLED') ORDER BY p.payment_id DESC",studentId);
    }
    public List<Payment> findAll()throws SQLException{ return list(BASE_SELECT+" ORDER BY p.payment_id DESC",null); }

    private List<Payment> list(String sql,Integer param)throws SQLException{
        List<Payment> out=new ArrayList<>();
        try(Connection c=DBUtil.getConnection();PreparedStatement s=c.prepareStatement(sql)){
            if(param!=null)s.setInt(1,param);
            try(ResultSet r=s.executeQuery()){while(r.next())out.add(map(r));}
        }
        return out;
    }

    private Payment map(ResultSet r)throws SQLException{
        Payment p=new Payment();
        p.setPaymentId(r.getInt("payment_id"));
        p.setInvoiceId(r.getInt("invoice_id"));
        p.setAmountPaid(r.getBigDecimal("amount_paid"));
        p.setPaymentMethod(r.getString("payment_method"));
        p.setPaymentDate(r.getTimestamp("payment_date"));
        int rb=r.getInt("received_by"); p.setReceivedBy(r.wasNull()?null:rb);
        p.setCardHolderName(r.getString("card_holder_name"));
        p.setGatewayOrderId(r.getString("gateway_order_id"));
        p.setGatewayPaymentId(r.getString("gateway_payment_id"));
        p.setGatewayStatus(r.getString("gateway_status"));
        p.setGatewayMethod(r.getString("gateway_method"));
        p.setMaskedCardNo(r.getString("masked_card_no"));
        p.setStaffStatus(r.getString("staff_status"));
        p.setStaffNote(r.getString("staff_note"));
        int cb=r.getInt("confirmed_by"); p.setConfirmedBy(r.wasNull()?null:cb);
        p.setConfirmedAt(r.getTimestamp("confirmed_at"));
        p.setAdminStatus(r.getString("admin_status"));
        p.setAdminNote(r.getString("admin_note"));
        int ab=r.getInt("approved_by"); p.setApprovedBy(r.wasNull()?null:ab);
        p.setApprovedAt(r.getTimestamp("approved_at"));
        p.setSlipPath(r.getString("slip_path"));
        p.setBankName(r.getString("bank_name"));
        p.setBranchName(r.getString("branch_name"));
        p.setStudentId(r.getInt("student_id"));
        p.setClassId(r.getInt("class_id"));
        p.setSubject(r.getString("subject"));
        p.setBatch(r.getString("batch"));
        p.setStudentName(name(r,"student_first","student_last"));
        p.setReceivedByName(name(r,"receiver_first","receiver_last"));
        p.setConfirmedByName(name(r,"confirmer_first","confirmer_last"));
        p.setApprovedByName(name(r,"approver_first","approver_last"));
        return p;
    }

    private String name(ResultSet r,String f,String l)throws SQLException{
        String first=r.getString(f),last=r.getString(l);
        if(first==null)return null;
        return (first+" "+(last==null?"":last)).trim();
    }

    public boolean deletePayment(Connection c, int paymentId) throws SQLException {
        try (PreparedStatement s = c.prepareStatement("DELETE FROM dbo.payments WHERE payment_id = ?")) {
            s.setInt(1, paymentId);
            return s.executeUpdate() > 0;
        }
    }

    public boolean updatePaymentRecord(Connection c, int paymentId, BigDecimal newAmount, String paymentMethod) throws SQLException {
        String sql = "UPDATE dbo.payments SET amount_paid = ?, payment_method = ? WHERE payment_id = ?";
        try (PreparedStatement s = c.prepareStatement(sql)) {
            s.setBigDecimal(1, newAmount);
            s.setString(2, paymentMethod);
            s.setInt(3, paymentId);
            return s.executeUpdate() > 0;
        }
    }
}
