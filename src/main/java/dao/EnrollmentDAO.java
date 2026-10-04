package dao;

import model.Enrollment;
import util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class EnrollmentDAO {

    private static final String SELECT_JOIN = """
            SELECT e.enrollment_id, e.class_id, e.student_id, e.status, e.enrolled_at,
                   c.subject, c.batch,
                   u.first_name, u.last_name
            FROM dbo.enrollments e
            JOIN dbo.classes c ON c.class_id = e.class_id
            JOIN dbo.users u ON u.user_id = e.student_id
            """;

    public boolean isEnrolled(int classId, int studentId) throws SQLException {
        String sql = "SELECT COUNT(*) AS cnt FROM dbo.enrollments WHERE class_id=? AND student_id=? AND status='ACTIVE'";
        try (Connection c=DBUtil.getConnection(); PreparedStatement s=c.prepareStatement(sql)) {
            s.setInt(1,classId); s.setInt(2,studentId);
            try(ResultSet r=s.executeQuery()){ return r.next() && r.getInt("cnt")>0; }
        }
    }

    /** Legacy direct-enroll helper retained for administrative/manual code paths. */
    public int enroll(int classId, int studentId) throws SQLException {
        String sql="INSERT INTO dbo.enrollments(class_id,student_id,status,enrolled_at) VALUES(?,?,'ACTIVE',GETDATE())";
        try(Connection c=DBUtil.getConnection(); PreparedStatement s=c.prepareStatement(sql,Statement.RETURN_GENERATED_KEYS)){
            s.setInt(1,classId); s.setInt(2,studentId);
            if(s.executeUpdate()>0){ try(ResultSet k=s.getGeneratedKeys()){ if(k.next()) return k.getInt(1); } }
        }
        return -1;
    }

    public int createRequest(int classId, int studentId) throws SQLException {
        try(Connection c=DBUtil.getConnection()) { return createRequest(c,classId,studentId); }
    }

    public int createRequest(Connection c, int classId, int studentId) throws SQLException {
        String sql="INSERT INTO dbo.enrollments(class_id,student_id,status,enrolled_at) VALUES(?,?,'PENDING_PAYMENT',GETDATE())";
        try(PreparedStatement s=c.prepareStatement(sql,Statement.RETURN_GENERATED_KEYS)){
            s.setInt(1,classId); s.setInt(2,studentId);
            if(s.executeUpdate()>0){ try(ResultSet k=s.getGeneratedKeys()){ if(k.next()) return k.getInt(1); } }
        }
        return -1;
    }

    public Enrollment findById(int enrollmentId) throws SQLException {
        try(Connection c=DBUtil.getConnection()){ return findById(c,enrollmentId); }
    }

    public Enrollment findById(Connection c,int enrollmentId) throws SQLException {
        String sql=SELECT_JOIN+" WHERE e.enrollment_id=?";
        try(PreparedStatement s=c.prepareStatement(sql)){
            s.setInt(1,enrollmentId);
            try(ResultSet r=s.executeQuery()){ return r.next()?mapEnrollment(r):null; }
        }
    }

    public Enrollment findAnyByClassAndStudent(int classId,int studentId) throws SQLException {
        String sql=SELECT_JOIN+" WHERE e.class_id=? AND e.student_id=?";
        try(Connection c=DBUtil.getConnection(); PreparedStatement s=c.prepareStatement(sql)){
            s.setInt(1,classId); s.setInt(2,studentId);
            try(ResultSet r=s.executeQuery()){ return r.next()?mapEnrollment(r):null; }
        }
    }

    public boolean updateStatus(Connection c,int enrollmentId,String expected,String next) throws SQLException {
        String sql="UPDATE dbo.enrollments SET status=? WHERE enrollment_id=? AND status=?";
        try(PreparedStatement s=c.prepareStatement(sql)){
            s.setString(1,next); s.setInt(2,enrollmentId); s.setString(3,expected);
            return s.executeUpdate()>0;
        }
    }

    public boolean updateStatusAndEnrolledAt(Connection c,int enrollmentId,String expected,String next) throws SQLException {
        String sql="UPDATE dbo.enrollments SET status=?, enrolled_at=GETDATE() WHERE enrollment_id=? AND status=?";
        try(PreparedStatement s=c.prepareStatement(sql)){
            s.setString(1,next); s.setInt(2,enrollmentId); s.setString(3,expected);
            return s.executeUpdate()>0;
        }
    }

    public boolean cancelEnrollment(int enrollmentId) throws SQLException {
        String sql="UPDATE dbo.enrollments SET status='CANCELLED' WHERE enrollment_id=?";
        try(Connection c=DBUtil.getConnection(); PreparedStatement s=c.prepareStatement(sql)){
            s.setInt(1,enrollmentId); return s.executeUpdate()>0;
        }
    }

    public List<Enrollment> findByStudent(int studentId) throws SQLException {
        return findByStudentAndStatus(studentId,"ACTIVE");
    }

    public List<Enrollment> findRequestsByStudent(int studentId) throws SQLException {
        String sql=SELECT_JOIN+"""
             WHERE e.student_id=? AND e.status <> 'ACTIVE'
             ORDER BY e.enrolled_at DESC
             """;
        List<Enrollment> out=new ArrayList<>();
        try(Connection c=DBUtil.getConnection(); PreparedStatement s=c.prepareStatement(sql)){
            s.setInt(1,studentId);
            try(ResultSet r=s.executeQuery()){ while(r.next()) out.add(mapEnrollment(r)); }
        }
        return out;
    }

    private List<Enrollment> findByStudentAndStatus(int studentId,String status) throws SQLException {
        String sql=SELECT_JOIN+" WHERE e.student_id=? AND e.status=? ORDER BY e.enrolled_at DESC";
        List<Enrollment> out=new ArrayList<>();
        try(Connection c=DBUtil.getConnection(); PreparedStatement s=c.prepareStatement(sql)){
            s.setInt(1,studentId); s.setString(2,status);
            try(ResultSet r=s.executeQuery()){ while(r.next()) out.add(mapEnrollment(r)); }
        }
        return out;
    }

    public List<Enrollment> findByClass(int classId) throws SQLException {
        String extra=classId<0 ? " WHERE e.status='ACTIVE' " : " WHERE e.class_id=? AND e.status='ACTIVE' ";
        String sql=SELECT_JOIN+extra+" ORDER BY u.first_name,u.last_name";
        List<Enrollment> out=new ArrayList<>();
        try(Connection c=DBUtil.getConnection(); PreparedStatement s=c.prepareStatement(sql)){
            if(classId>=0) s.setInt(1,classId);
            try(ResultSet r=s.executeQuery()){ while(r.next()) out.add(mapEnrollment(r)); }
        }
        return out;
    }

    public Integer findStudentIdByEnrollment(int enrollmentId) throws SQLException {
        String sql="SELECT student_id FROM dbo.enrollments WHERE enrollment_id=?";
        try(Connection c=DBUtil.getConnection(); PreparedStatement s=c.prepareStatement(sql)){
            s.setInt(1,enrollmentId);
            try(ResultSet r=s.executeQuery()){ return r.next()?r.getInt(1):null; }
        }
    }

    private Enrollment mapEnrollment(ResultSet r) throws SQLException {
        Enrollment e=new Enrollment();
        e.setEnrollmentId(r.getInt("enrollment_id"));
        e.setClassId(r.getInt("class_id"));
        e.setStudentId(r.getInt("student_id"));
        e.setStatus(r.getString("status"));
        e.setEnrolledAt(r.getTimestamp("enrolled_at"));
        e.setSubject(r.getString("subject"));
        e.setBatch(r.getString("batch"));
        try {
            String first=r.getString("first_name"), last=r.getString("last_name");
            if(first!=null) e.setStudentName(first+" "+(last==null?"":last));
        } catch(SQLException ignored){}
        return e;
    }
}
