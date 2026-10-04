package service;

import dao.ClassDAO;
import dao.EnrollmentDAO;
import dao.InvoiceDAO;
import model.Class;
import model.Enrollment;
import util.DBUtil;

import java.sql.Connection;
import java.sql.Date;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;

public class EnrollmentService {
    private final EnrollmentDAO enrollmentDAO;
    private final ClassDAO classDAO;
    private final InvoiceDAO invoiceDAO;

    public EnrollmentService() {
        this(new EnrollmentDAO(), new ClassDAO(), new InvoiceDAO());
    }

    public EnrollmentService(EnrollmentDAO enrollmentDAO, ClassDAO classDAO, InvoiceDAO invoiceDAO) {
        this.enrollmentDAO = enrollmentDAO;
        this.classDAO = classDAO;
        this.invoiceDAO = invoiceDAO;
    }

    /** Legacy helper kept for administrative/manual code paths. */
    public String enrollStudent(int classId, int studentId) throws SQLException {
        Class c = classDAO.findById(classId);
        if (c == null || !"ACTIVE".equalsIgnoreCase(c.getStatus())) return "This class is not available for enrollment.";
        if (enrollmentDAO.findAnyByClassAndStudent(classId, studentId) != null) return "A request already exists for this class.";
        return enrollmentDAO.enroll(classId, studentId) > 0 ? null : "Enrollment failed. Please try again.";
    }

    public RequestResult requestEnrollment(int classId, int studentId) throws SQLException {
        Class c = classDAO.findById(classId);
        if (c == null || !"ACTIVE".equalsIgnoreCase(c.getStatus())) {
            return new RequestResult("This class is not available for enrollment.", -1, -1);
        }
        if (c.getFee() == null || c.getFee().signum() <= 0) {
            return new RequestResult("This class does not have a valid fee.", -1, -1);
        }

        Enrollment existing = enrollmentDAO.findAnyByClassAndStudent(classId, studentId);
        if (existing != null) {
            String msg = "ACTIVE".equalsIgnoreCase(existing.getStatus())
                    ? "You are already enrolled in this class."
                    : "You already have an enrollment request for this class.";
            return new RequestResult(msg, existing.getEnrollmentId(), -1);
        }

        try (Connection connection = DBUtil.getConnection()) {
            connection.setAutoCommit(false);
            try {
                int enrollmentId = enrollmentDAO.createRequest(connection, classId, studentId);
                if (enrollmentId <= 0) {
                    connection.rollback();
                    return new RequestResult("Could not create enrollment request.", -1, -1);
                }
                int invoiceId = invoiceDAO.createInvoice(
                        connection, enrollmentId, c.getFee(), Date.valueOf(LocalDate.now()), studentId);
                if (invoiceId <= 0) {
                    connection.rollback();
                    return new RequestResult("Could not create class invoice.", -1, -1);
                }
                connection.commit();
                return new RequestResult(null, enrollmentId, invoiceId);
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            }
        }
    }

    public boolean cancelEnrollment(int enrollmentId) throws SQLException { return enrollmentDAO.cancelEnrollment(enrollmentId); }
    public List<Enrollment> findByStudent(int studentId) throws SQLException { return enrollmentDAO.findByStudent(studentId); }
    public List<Enrollment> findRequestsByStudent(int studentId) throws SQLException { return enrollmentDAO.findRequestsByStudent(studentId); }
    public List<Enrollment> findByClass(int classId) throws SQLException { return enrollmentDAO.findByClass(classId); }
    public Enrollment findAnyByClassAndStudent(int classId, int studentId) throws SQLException {
        return enrollmentDAO.findAnyByClassAndStudent(classId, studentId);
    }
    public boolean isActive(int classId, int studentId) throws SQLException { return enrollmentDAO.isEnrolled(classId, studentId); }

    public record RequestResult(String error, int enrollmentId, int invoiceId) {}
}
