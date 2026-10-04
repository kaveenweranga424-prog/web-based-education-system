package dao;

import model.Invoice;
import util.DBUtil;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class InvoiceDAO {
    private static final String PAID_SUM = """
        SELECT invoice_id,
               SUM(CASE
                     WHEN gateway_order_id IS NULL THEN amount_paid
                     WHEN gateway_status IN ('SUCCESS','DEMO_SUBMITTED') THEN amount_paid
                     ELSE 0
                   END) AS total_paid
        FROM dbo.payments
        GROUP BY invoice_id
        """;

    private static final String BASE_SELECT = """
            SELECT i.invoice_id, i.enrollment_id, i.amount, i.due_date, i.status,
                   i.created_by, i.created_at,
                   e.class_id, e.student_id,
                   c.subject, c.batch,
                   u.first_name, u.last_name,
                   COALESCE(p.total_paid,0) AS amount_paid
            FROM dbo.invoices i
            JOIN dbo.enrollments e ON e.enrollment_id=i.enrollment_id
            JOIN dbo.classes c ON c.class_id=e.class_id
            JOIN dbo.users u ON u.user_id=e.student_id
            LEFT JOIN (""" + PAID_SUM + ") p ON p.invoice_id=i.invoice_id ";

    public boolean existsForEnrollment(int enrollmentId) throws SQLException {
        String sql="SELECT COUNT(*) FROM dbo.invoices WHERE enrollment_id=? AND status<>'CANCELLED'";
        try(Connection c=DBUtil.getConnection(); PreparedStatement s=c.prepareStatement(sql)){
            s.setInt(1,enrollmentId); try(ResultSet r=s.executeQuery()){ return r.next()&&r.getInt(1)>0; }
        }
    }

    public int createInvoice(int enrollmentId,BigDecimal amount,Date dueDate,int createdBy)throws SQLException{
        try(Connection c=DBUtil.getConnection()){ return createInvoice(c,enrollmentId,amount,dueDate,createdBy); }
    }

    public int createInvoice(Connection c,int enrollmentId,BigDecimal amount,Date dueDate,int createdBy)throws SQLException{
        String sql="INSERT INTO dbo.invoices(enrollment_id,amount,due_date,status,created_by) VALUES(?,?,?,'UNPAID',?)";
        try(PreparedStatement s=c.prepareStatement(sql,Statement.RETURN_GENERATED_KEYS)){
            s.setInt(1,enrollmentId); s.setBigDecimal(2,amount); s.setDate(3,dueDate); s.setInt(4,createdBy);
            if(s.executeUpdate()>0){ try(ResultSet k=s.getGeneratedKeys()){ if(k.next()) return k.getInt(1); } }
        }
        return -1;
    }

    public boolean cancelInvoice(int invoiceId)throws SQLException{
        try(Connection c=DBUtil.getConnection(); PreparedStatement s=c.prepareStatement("UPDATE dbo.invoices SET status='CANCELLED' WHERE invoice_id=?")){
            s.setInt(1,invoiceId); return s.executeUpdate()>0;
        }
    }

    public boolean updateStatus(Connection c,int invoiceId,String status)throws SQLException{
        try(PreparedStatement s=c.prepareStatement("UPDATE dbo.invoices SET status=? WHERE invoice_id=?")){
            s.setString(1,status); s.setInt(2,invoiceId); return s.executeUpdate()>0;
        }
    }

    public Invoice findById(int id)throws SQLException{ try(Connection c=DBUtil.getConnection()){ return findById(c,id); } }
    public Invoice findById(Connection c,int id)throws SQLException{
        try(PreparedStatement s=c.prepareStatement(BASE_SELECT+" WHERE i.invoice_id=?")){
            s.setInt(1,id); try(ResultSet r=s.executeQuery()){ return r.next()?map(r):null; }
        }
    }

    public Invoice findByEnrollment(int enrollmentId)throws SQLException{
        try(Connection c=DBUtil.getConnection()){ return findByEnrollment(c,enrollmentId); }
    }
    public Invoice findByEnrollment(Connection c,int enrollmentId)throws SQLException{
        try(PreparedStatement s=c.prepareStatement(BASE_SELECT+" WHERE i.enrollment_id=? AND i.status<>'CANCELLED'")){
            s.setInt(1,enrollmentId); try(ResultSet r=s.executeQuery()){ return r.next()?map(r):null; }
        }
    }

    public List<Invoice> findAll()throws SQLException{ return list(BASE_SELECT+" WHERE i.status<>'CANCELLED' ORDER BY i.due_date DESC",null); }
    public List<Invoice> findByStudent(int studentId)throws SQLException{ return list(BASE_SELECT+" WHERE e.student_id=? AND i.status<>'CANCELLED' ORDER BY i.due_date DESC",studentId); }
    public List<Invoice> findOutstanding()throws SQLException{ return list(BASE_SELECT+" WHERE i.status IN('UNPAID','PARTIAL') AND e.status='ACTIVE' ORDER BY i.due_date",null); }

    private List<Invoice> list(String sql,Integer param)throws SQLException{
        List<Invoice> out=new ArrayList<>();
        try(Connection c=DBUtil.getConnection(); PreparedStatement s=c.prepareStatement(sql)){
            if(param!=null) s.setInt(1,param);
            try(ResultSet r=s.executeQuery()){ while(r.next()) out.add(map(r)); }
        }
        return out;
    }

    private Invoice map(ResultSet r)throws SQLException{
        Invoice i=new Invoice();
        i.setInvoiceId(r.getInt("invoice_id")); i.setEnrollmentId(r.getInt("enrollment_id"));
        i.setClassId(r.getInt("class_id")); i.setStudentId(r.getInt("student_id"));
        i.setSubject(r.getString("subject")); i.setBatch(r.getString("batch"));
        i.setStudentName(r.getString("first_name")+" "+r.getString("last_name"));
        i.setAmount(r.getBigDecimal("amount")); i.setDueDate(r.getDate("due_date"));
        i.setStatus(r.getString("status")); i.setCreatedBy(r.getInt("created_by")); i.setCreatedAt(r.getTimestamp("created_at"));
        BigDecimal paid=r.getBigDecimal("amount_paid"); if(paid==null) paid=BigDecimal.ZERO;
        i.setAmountPaid(paid); i.setBalance(i.getAmount().subtract(paid));
        return i;
    }
}
