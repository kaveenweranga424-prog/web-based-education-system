package dao;

import util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Read-only dashboard queries. Dashboard pages use this DAO so every number and
 * table row comes from SQL Server rather than hardcoded JSP/JavaScript data.
 */
public class DashboardDAO {

    public Map<String, Object> loadAdminDashboard() throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            Map<String, Object> data = new LinkedHashMap<>();

            data.put("summary", queryOne(connection, """
                    SELECT
                        (SELECT COUNT(*) FROM dbo.users WHERE role = 'STUDENT' AND status = 'ACTIVE') AS totalStudents,
                        (SELECT COUNT(*) FROM dbo.users WHERE role = 'TUTOR' AND status = 'ACTIVE') AS activeTutors,
                        (SELECT COUNT(*) FROM dbo.classes WHERE status = 'ACTIVE') AS activeClasses,
                        (SELECT COUNT(DISTINCT subject) FROM dbo.classes WHERE status = 'ACTIVE') AS activeSubjects,
                        COALESCE((SELECT SUM(amount) FROM dbo.invoices
                                  WHERE status <> 'CANCELLED'
                                    AND YEAR(created_at) = YEAR(GETDATE())
                                    AND MONTH(created_at) = MONTH(GETDATE())), 0) AS monthlyBilled,
                        COALESCE((SELECT SUM(CASE WHEN gateway_order_id IS NULL OR gateway_status IN ('SUCCESS','DEMO_SUBMITTED') THEN amount_paid ELSE 0 END)
                                  FROM dbo.payments
                                  WHERE YEAR(payment_date) = YEAR(GETDATE())
                                    AND MONTH(payment_date) = MONTH(GETDATE())), 0) AS monthlyRevenue,
                        COALESCE((SELECT SUM(i.amount - COALESCE(p.total_paid, 0))
                                  FROM dbo.invoices i
                                  LEFT JOIN (SELECT invoice_id, SUM(CASE
                                   WHEN gateway_order_id IS NULL THEN amount_paid
                                   WHEN gateway_status IN ('SUCCESS','DEMO_SUBMITTED') THEN amount_paid
                                   ELSE 0 END) AS total_paid
                                             FROM dbo.payments GROUP BY invoice_id) p
                                    ON p.invoice_id = i.invoice_id
                                  WHERE i.status IN ('UNPAID', 'PARTIAL')), 0) AS outstandingBalance,
                        (SELECT COUNT(*) FROM dbo.invoices
                         WHERE status IN ('UNPAID', 'PARTIAL') AND due_date < CAST(GETDATE() AS DATE)) AS overdueInvoices,
                        (SELECT COUNT(*) FROM dbo.classes
                         WHERE status = 'ACTIVE' AND tutor_id IS NULL) AS unassignedClasses,
                        (SELECT COUNT(*) FROM dbo.payments p
                         JOIN dbo.invoices i ON i.invoice_id = p.invoice_id
                         JOIN dbo.enrollments e ON e.enrollment_id = i.enrollment_id
                         WHERE p.gateway_status IN ('DEMO_SUBMITTED','SUCCESS')
                           AND p.admin_status = 'PENDING'
                           AND e.status IN ('PAID_PENDING_ADMIN','STAFF_CONFIRMED')) AS pendingApprovals
                    """));

            data.put("enrollmentByBatch", queryList(connection, """
                    SELECT c.batch, COUNT(DISTINCT e.student_id) AS studentCount
                    FROM dbo.classes c
                    LEFT JOIN dbo.enrollments e
                      ON e.class_id = c.class_id AND e.status = 'ACTIVE'
                    WHERE c.status = 'ACTIVE'
                    GROUP BY c.batch
                    ORDER BY c.batch
                    """));

            data.put("classes", queryList(connection, """
                    SELECT TOP 100
                        c.class_id AS classId, c.subject, c.batch, c.fee, c.status,
                        c.image_path AS imagePath,
                        c.tutor_id AS tutorId,
                        COALESCE(t.first_name + ' ' + t.last_name, 'Unassigned') AS tutorName,
                        COUNT(DISTINCT CASE WHEN e.status = 'ACTIVE' THEN e.student_id END) AS studentCount
                    FROM dbo.classes c
                    LEFT JOIN dbo.users t ON t.user_id = c.tutor_id
                    LEFT JOIN dbo.enrollments e ON e.class_id = c.class_id
                    WHERE c.status = 'ACTIVE'
                    GROUP BY c.class_id, c.subject, c.batch, c.fee, c.status, c.image_path,
                             c.tutor_id, t.first_name, t.last_name
                    ORDER BY c.subject, c.batch
                    """));

            data.put("students", queryList(connection, """
                    SELECT TOP 100
                        u.user_id AS studentId,
                        u.first_name + ' ' + u.last_name AS studentName,
                        u.email, u.phone, u.status,
                        COUNT(DISTINCT CASE WHEN e.status = 'ACTIVE' THEN e.class_id END) AS classCount,
                        COALESCE(a.attendanceRate, 0) AS attendanceRate,
                        COALESCE(f.outstandingBalance, 0) AS outstandingBalance
                    FROM dbo.users u
                    LEFT JOIN dbo.enrollments e ON e.student_id = u.user_id
                    LEFT JOIN (
                        SELECT student_id,
                               CAST(100.0 * SUM(CASE WHEN status IN ('PRESENT','LATE') THEN 1 ELSE 0 END)
                                    / NULLIF(COUNT(*), 0) AS DECIMAL(6,2)) AS attendanceRate
                        FROM dbo.attendance
                        GROUP BY student_id
                    ) a ON a.student_id = u.user_id
                    LEFT JOIN (
                        SELECT e2.student_id,
                               SUM(i.amount - COALESCE(p.total_paid, 0)) AS outstandingBalance
                        FROM dbo.invoices i
                        JOIN dbo.enrollments e2 ON e2.enrollment_id = i.enrollment_id
                        LEFT JOIN (SELECT invoice_id, SUM(CASE
                                   WHEN gateway_order_id IS NULL THEN amount_paid
                                   WHEN gateway_status IN ('SUCCESS','DEMO_SUBMITTED') THEN amount_paid
                                   ELSE 0 END) AS total_paid
                                   FROM dbo.payments GROUP BY invoice_id) p
                          ON p.invoice_id = i.invoice_id
                        WHERE i.status IN ('UNPAID','PARTIAL')
                        GROUP BY e2.student_id
                    ) f ON f.student_id = u.user_id
                    WHERE u.role = 'STUDENT'
                    GROUP BY u.user_id, u.first_name, u.last_name, u.email, u.phone, u.status,
                             a.attendanceRate, f.outstandingBalance
                    ORDER BY u.first_name, u.last_name
                    """));

            data.put("tutors", queryList(connection, """
                    SELECT
                        u.user_id AS tutorId,
                        u.first_name + ' ' + u.last_name AS tutorName,
                        u.email, u.phone, u.status,
                        tp.specialization,
                        COUNT(DISTINCT CASE WHEN c.status = 'ACTIVE' THEN c.class_id END) AS classCount,
                        COUNT(DISTINCT CASE WHEN e.status = 'ACTIVE' THEN e.student_id END) AS studentCount
                    FROM dbo.users u
                    LEFT JOIN dbo.tutor_profiles tp ON tp.user_id = u.user_id
                    LEFT JOIN dbo.classes c ON c.tutor_id = u.user_id
                    LEFT JOIN dbo.enrollments e ON e.class_id = c.class_id
                    WHERE u.role = 'TUTOR'
                    GROUP BY u.user_id, u.first_name, u.last_name, u.email, u.phone,
                             u.status, tp.specialization
                    ORDER BY u.first_name, u.last_name
                    """));

            data.put("timetable", queryList(connection, """
                    SELECT TOP 100
                        s.slot_id AS slotId, s.day_of_week AS dayOfWeek,
                        s.start_time AS startTime, s.end_time AS endTime, s.room,
                        c.class_id AS classId, c.subject, c.batch,
                        u.first_name + ' ' + u.last_name AS tutorName
                    FROM dbo.timetable_slots s
                    JOIN dbo.classes c ON c.class_id = s.class_id
                    JOIN dbo.users u ON u.user_id = s.tutor_id
                    WHERE s.status = 'ACTIVE' AND c.status = 'ACTIVE'
                    ORDER BY CASE s.day_of_week
                        WHEN 'MON' THEN 1 WHEN 'TUE' THEN 2 WHEN 'WED' THEN 3
                        WHEN 'THU' THEN 4 WHEN 'FRI' THEN 5 WHEN 'SAT' THEN 6 WHEN 'SUN' THEN 7 END,
                        s.start_time
                    """));

            data.put("invoices", queryList(connection, invoiceListSql("", 50)));
            data.put("exams", queryList(connection, """
                    SELECT TOP 50
                        x.exam_id AS examId, x.exam_name AS examName, x.exam_date AS examDate,
                        x.max_marks AS maxMarks, x.status,
                        c.subject, c.batch,
                        COUNT(r.result_id) AS resultCount,
                        COUNT(DISTINCT CASE WHEN e.status = 'ACTIVE' THEN e.student_id END) AS enrolledCount
                    FROM dbo.exams x
                    JOIN dbo.classes c ON c.class_id = x.class_id
                    LEFT JOIN dbo.exam_results r ON r.exam_id = x.exam_id
                    LEFT JOIN dbo.enrollments e ON e.class_id = x.class_id
                    WHERE c.status = 'ACTIVE'
                    GROUP BY x.exam_id, x.exam_name, x.exam_date, x.max_marks, x.status,
                             c.subject, c.batch
                    ORDER BY x.exam_date DESC
                    """));
            data.put("notifications", queryList(connection, notificationSql("", 30)));
            return data;
        }
    }

    public Map<String, Object> loadTutorDashboard(int tutorId) throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            Map<String, Object> data = new LinkedHashMap<>();
            data.put("summary", queryOne(connection, """
                    SELECT
                        (SELECT COUNT(*) FROM dbo.classes
                         WHERE tutor_id = ? AND status = 'ACTIVE') AS classCount,
                        (SELECT COUNT(DISTINCT e.student_id)
                         FROM dbo.enrollments e
                         JOIN dbo.classes c ON c.class_id = e.class_id
                         WHERE c.tutor_id = ? AND c.status = 'ACTIVE' AND e.status = 'ACTIVE') AS studentCount,
                        COALESCE((SELECT CAST(100.0 * SUM(CASE WHEN a.status IN ('PRESENT','LATE') THEN 1 ELSE 0 END)
                                      / NULLIF(COUNT(*), 0) AS DECIMAL(6,2))
                                  FROM dbo.attendance a
                                  JOIN dbo.classes c ON c.class_id = a.class_id
                                  WHERE c.tutor_id = ?), 0) AS attendanceRate,
                        (SELECT COUNT(*) FROM dbo.class_materials m
                         JOIN dbo.classes c ON c.class_id = m.class_id
                         WHERE c.tutor_id = ?) AS materialCount,
                        (SELECT COUNT(*) FROM dbo.exams x
                         JOIN dbo.classes c ON c.class_id = x.class_id
                         WHERE c.tutor_id = ? AND x.status = 'SCHEDULED'
                           AND x.exam_date >= CAST(GETDATE() AS DATE)) AS upcomingExamCount,
                        (SELECT COUNT(*) FROM dbo.exam_mcq_submissions s
                         JOIN dbo.exams x ON x.exam_id = s.exam_id
                         JOIN dbo.classes c ON c.class_id = x.class_id
                         WHERE c.tutor_id = ? AND (s.status = 'PENDING' OR s.status IS NULL)) AS pendingReviewCount,
                        COALESCE((SELECT SUM(p.amount_paid)
                                  FROM dbo.payments p
                                  JOIN dbo.invoices i ON i.invoice_id = p.invoice_id
                                  JOIN dbo.enrollments e ON e.enrollment_id = i.enrollment_id
                                  JOIN dbo.classes c ON c.class_id = e.class_id
                                  WHERE c.tutor_id = ?
                                    AND YEAR(p.payment_date) = YEAR(GETDATE())
                                    AND MONTH(p.payment_date) = MONTH(GETDATE())), 0) AS monthlyCollected
                    """, tutorId, tutorId, tutorId, tutorId, tutorId, tutorId, tutorId));

            data.put("classes", queryList(connection, """
                    SELECT
                        c.class_id AS classId, c.subject, c.batch, c.fee, c.status,
                        c.image_path AS imagePath, c.class_type AS classType,
                        c.meeting_link AS meetingLink,
                        COUNT(DISTINCT CASE WHEN e.status = 'ACTIVE' THEN e.student_id END) AS studentCount,
                        COUNT(DISTINCT m.material_id) AS materialCount
                    FROM dbo.classes c
                    LEFT JOIN dbo.enrollments e ON e.class_id = c.class_id
                    LEFT JOIN dbo.class_materials m ON m.class_id = c.class_id
                    WHERE c.tutor_id = ? AND c.status = 'ACTIVE'
                    GROUP BY c.class_id, c.subject, c.batch, c.fee, c.status, c.image_path, c.class_type, c.meeting_link
                    ORDER BY c.status, c.subject, c.batch
                    """, tutorId));

            data.put("students", queryList(connection, """
                    SELECT
                        u.user_id AS studentId,
                        u.first_name + ' ' + u.last_name AS studentName,
                        u.email, u.phone,
                        COUNT(DISTINCT e.class_id) AS classCount,
                        COALESCE(a.attendanceRate, 0) AS attendanceRate
                    FROM dbo.users u
                    JOIN dbo.enrollments e ON e.student_id = u.user_id AND e.status = 'ACTIVE'
                    JOIN dbo.classes c ON c.class_id = e.class_id AND c.tutor_id = ?
                    LEFT JOIN (
                        SELECT a2.student_id,
                                CAST(100.0 * SUM(CASE WHEN a2.status IN ('PRESENT','LATE') THEN 1 ELSE 0 END)
                                     / NULLIF(COUNT(*), 0) AS DECIMAL(6,2)) AS attendanceRate
                        FROM dbo.attendance a2
                        JOIN dbo.classes c2 ON c2.class_id = a2.class_id
                        WHERE c2.tutor_id = ?
                        GROUP BY a2.student_id
                    ) a ON a.student_id = u.user_id
                    GROUP BY u.user_id, u.first_name, u.last_name, u.email, u.phone, a.attendanceRate
                    ORDER BY u.first_name, u.last_name
                    """, tutorId, tutorId));

            data.put("timetable", queryList(connection, """
                    SELECT s.slot_id AS slotId, s.day_of_week AS dayOfWeek,
                    s.start_time AS startTime, s.end_time AS endTime, s.room,
                           COALESCE(s.confirmation_status, 'CONFIRMED') AS confirmationStatus,
                           s.suggested_day AS suggestedDay,
                           s.suggested_start_time AS suggestedStartTime,
                           s.suggested_end_time AS suggestedEndTime,
                           s.tutor_note AS tutorNote,
                           c.class_id AS classId, c.subject, c.batch
                    FROM dbo.timetable_slots s
                    JOIN dbo.classes c ON c.class_id = s.class_id
                    WHERE s.tutor_id = ? AND s.status = 'ACTIVE' AND c.status = 'ACTIVE'
                    ORDER BY CASE s.day_of_week
                        WHEN 'MON' THEN 1 WHEN 'TUE' THEN 2 WHEN 'WED' THEN 3
                        WHEN 'THU' THEN 4 WHEN 'FRI' THEN 5 WHEN 'SAT' THEN 6 WHEN 'SUN' THEN 7 END,
                        s.start_time
                    """, tutorId));

            data.put("attendance", queryList(connection, """
                    SELECT TOP 100 a.attendance_id AS attendanceId, a.session_date AS sessionDate,
                           a.status, a.remarks,
                           c.subject, c.batch,
                           u.user_id AS studentId,
                           u.first_name + ' ' + u.last_name AS studentName
                    FROM dbo.attendance a
                    JOIN dbo.classes c ON c.class_id = a.class_id
                    JOIN dbo.users u ON u.user_id = a.student_id
                    WHERE c.tutor_id = ?
                    ORDER BY a.session_date DESC, c.subject, u.first_name
                    """, tutorId));

            data.put("pendingSubmissions", queryList(connection, """
                    SELECT s.submission_id AS submissionId,
                           s.exam_id AS examId,
                           x.exam_name AS examName,
                           c.subject, c.batch,
                           u.user_id AS studentId,
                           u.first_name + ' ' + u.last_name AS studentName,
                           s.score_obtained AS scoreObtained,
                           s.total_questions AS totalQuestions,
                           s.correct_answers AS correctAnswers,
                           s.submitted_at AS submittedAt,
                           s.status
                    FROM dbo.exam_mcq_submissions s
                    JOIN dbo.exams x ON x.exam_id = s.exam_id
                    JOIN dbo.classes c ON c.class_id = x.class_id
                    JOIN dbo.users u ON u.user_id = s.student_id
                    WHERE c.tutor_id = ? AND (s.status = 'PENDING' OR s.status IS NULL)
                    ORDER BY s.submitted_at DESC
                    """, tutorId));

            data.put("exams", queryList(connection, """
                    SELECT x.exam_id AS examId, x.exam_name AS examName, x.exam_date AS examDate,
                           x.max_marks AS maxMarks, x.status, c.subject, c.batch,
                           COUNT(DISTINCT r.result_id) AS resultCount,
                           COUNT(DISTINCT s.submission_id) AS submissionCount,
                           COUNT(DISTINCT CASE WHEN s.status = 'PENDING' OR s.status IS NULL THEN s.submission_id END) AS pendingReviewCount
                    FROM dbo.exams x
                    JOIN dbo.classes c ON c.class_id = x.class_id
                    LEFT JOIN dbo.exam_results r ON r.exam_id = x.exam_id
                    LEFT JOIN dbo.exam_mcq_submissions s ON s.exam_id = x.exam_id
                    WHERE c.tutor_id = ? AND c.status <> 'CANCELLED'
                    GROUP BY x.exam_id, x.exam_name, x.exam_date, x.max_marks, x.status,
                             c.subject, c.batch
                    ORDER BY x.exam_date DESC
                    """, tutorId));

            data.put("notifications", queryList(connection, notificationSql("WHERE n.recipient_id = ?", 30), tutorId));
            return data;
        }
    }

    public Map<String, Object> loadStudentDashboard(int studentId) throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            return loadStudentData(connection, studentId);
        }
    }

    public Map<String, Object> loadParentDashboard(int parentId, Integer requestedStudentId) throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            Map<String, Object> data = new LinkedHashMap<>();
            List<Map<String, Object>> children = queryList(connection, """
                    SELECT u.user_id AS studentId,
                           u.first_name + ' ' + u.last_name AS studentName,
                           u.email, u.phone, ps.relationship,
                           COUNT(DISTINCT CASE WHEN e.status = 'ACTIVE' AND c.status = 'ACTIVE' THEN e.class_id END) AS classCount
                    FROM dbo.parent_student ps
                    JOIN dbo.users u ON u.user_id = ps.student_user_id
                    LEFT JOIN dbo.enrollments e ON e.student_id = u.user_id
                    LEFT JOIN dbo.classes c ON c.class_id = e.class_id
                    WHERE ps.parent_user_id = ? AND ps.status = 'ACTIVE'
                    GROUP BY u.user_id, u.first_name, u.last_name, u.email, u.phone, ps.relationship
                    ORDER BY u.first_name, u.last_name
                    """, parentId);
            data.put("children", children);

            Integer selectedStudentId = null;
            if (requestedStudentId != null) {
                for (Map<String, Object> child : children) {
                    if (((Number) child.get("studentId")).intValue() == requestedStudentId) {
                        selectedStudentId = requestedStudentId;
                        break;
                    }
                }
            }
            if (selectedStudentId == null && !children.isEmpty()) {
                selectedStudentId = ((Number) children.get(0).get("studentId")).intValue();
            }

            data.put("selectedStudentId", selectedStudentId);
            if (selectedStudentId != null) {
                Map<String, Object> childData = loadStudentData(connection, selectedStudentId);
                data.putAll(childData);
                data.put("children", children);
                data.put("selectedStudentId", selectedStudentId);
                data.put("notifications", queryList(connection, notificationSql("WHERE (n.recipient_id = ? OR n.recipient_id = ?)", 50), parentId, selectedStudentId));
                @SuppressWarnings("unchecked")
                Map<String, Object> summaryMap = (Map<String, Object>) data.get("summary");
                if (summaryMap != null) {
                    Map<String, Object> unreadRow = queryOne(connection,
                        "SELECT COUNT(*) AS unreadNotifications FROM dbo.notifications WHERE (recipient_id = ? OR recipient_id = ?) AND is_read = 0",
                        parentId, selectedStudentId);
                    summaryMap.put("unreadNotifications", unreadRow.getOrDefault("unreadNotifications", 0));
                }
            } else {
                putEmptyStudentData(data);
                data.put("notifications", queryList(connection, notificationSql("WHERE n.recipient_id = ?", 50), parentId));
                @SuppressWarnings("unchecked")
                Map<String, Object> summaryMap = (Map<String, Object>) data.get("summary");
                if (summaryMap != null) {
                    Map<String, Object> unreadRow = queryOne(connection,
                        "SELECT COUNT(*) AS unreadNotifications FROM dbo.notifications WHERE recipient_id = ? AND is_read = 0", parentId);
                    summaryMap.put("unreadNotifications", unreadRow.getOrDefault("unreadNotifications", 0));
                }
            }
            return data;
        }
    }

    public Map<String, Object> loadStaffDashboard(int staffId) throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            Map<String, Object> data = new LinkedHashMap<>();
            data.put("summary", queryOne(connection, """
                    SELECT
                        (SELECT COUNT(*) FROM dbo.invoices
                         WHERE CAST(created_at AS DATE) = CAST(GETDATE() AS DATE)
                           AND status <> 'CANCELLED') AS invoicesToday,
                        (SELECT COUNT(*) FROM dbo.payments
                         WHERE CAST(payment_date AS DATE) = CAST(GETDATE() AS DATE)) AS paymentsToday,
                        COALESCE((SELECT SUM(CASE WHEN gateway_order_id IS NULL OR gateway_status IN ('SUCCESS','DEMO_SUBMITTED') THEN amount_paid ELSE 0 END)
                                  FROM dbo.payments
                                  WHERE CAST(payment_date AS DATE) = CAST(GETDATE() AS DATE)), 0) AS amountToday,
                        COALESCE((SELECT SUM(i.amount - COALESCE(p.total_paid, 0))
                                  FROM dbo.invoices i
                                  LEFT JOIN (SELECT invoice_id, SUM(CASE
                                   WHEN gateway_order_id IS NULL THEN amount_paid
                                   WHEN gateway_status IN ('SUCCESS','DEMO_SUBMITTED') THEN amount_paid
                                   ELSE 0 END) AS total_paid
                                             FROM dbo.payments GROUP BY invoice_id) p
                                    ON p.invoice_id = i.invoice_id
                                  WHERE i.status IN ('UNPAID','PARTIAL')), 0) AS outstandingBalance,
                        (SELECT COUNT(*) FROM dbo.invoices
                         WHERE status IN ('UNPAID','PARTIAL') AND due_date < CAST(GETDATE() AS DATE)) AS overdueInvoices,
                        (SELECT COUNT(*) FROM dbo.notifications
                         WHERE recipient_id = ? AND is_read = 0) AS unreadNotifications,
                        (SELECT COUNT(*) FROM dbo.payments p
                         JOIN dbo.invoices i ON i.invoice_id = p.invoice_id
                         JOIN dbo.enrollments e ON e.enrollment_id = i.enrollment_id
                         WHERE p.gateway_status IN ('DEMO_SUBMITTED','SUCCESS')
                           AND p.staff_status = 'PENDING'
                           AND e.status = 'PAID_PENDING_STAFF') AS pendingApprovals
                    """, staffId));
            data.put("invoices", queryList(connection, invoiceListSql("", 100)));
            data.put("payments", queryList(connection, """
                    SELECT TOP 100
                        p.payment_id AS paymentId, p.invoice_id AS invoiceId,
                        p.amount_paid AS amountPaid, p.payment_method AS paymentMethod,
                        p.payment_date AS paymentDate,
                        c.subject, c.batch,
                        su.first_name + ' ' + su.last_name AS studentName,
                        ru.first_name + ' ' + ru.last_name AS receivedByName
                    FROM dbo.payments p
                    JOIN dbo.invoices i ON i.invoice_id = p.invoice_id
                    JOIN dbo.enrollments e ON e.enrollment_id = i.enrollment_id
                    JOIN dbo.classes c ON c.class_id = e.class_id
                    JOIN dbo.users su ON su.user_id = e.student_id
                    LEFT JOIN dbo.users ru ON ru.user_id = p.received_by
                    WHERE p.gateway_order_id IS NULL OR p.gateway_status IN ('SUCCESS','DEMO_SUBMITTED')
                    ORDER BY p.payment_date DESC
                    """));
            data.put("notifications", queryList(connection, notificationSql("WHERE n.recipient_id = ?", 30), staffId));
            return data;
        }
    }

    private Map<String, Object> loadStudentData(Connection connection, int studentId) throws SQLException {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("student", queryOne(connection, """
                SELECT user_id AS studentId,
                       first_name + ' ' + last_name AS studentName,
                       first_name AS firstName, last_name AS lastName,
                       email, phone, status
                FROM dbo.users
                WHERE user_id = ? AND role = 'STUDENT'
                """, studentId));

        data.put("summary", queryOne(connection, """
                SELECT
                    (SELECT COUNT(*) FROM dbo.enrollments e
                     JOIN dbo.classes c ON c.class_id = e.class_id
                     WHERE e.student_id = ? AND e.status = 'ACTIVE' AND c.status = 'ACTIVE') AS classCount,
                    COALESCE((SELECT CAST(100.0 * SUM(CASE WHEN status IN ('PRESENT','LATE') THEN 1 ELSE 0 END)
                                      / NULLIF(COUNT(*), 0) AS DECIMAL(6,2))
                              FROM dbo.attendance WHERE student_id = ?), 0) AS attendanceRate,
                    COALESCE((SELECT SUM(i.amount - COALESCE(p.total_paid, 0))
                              FROM dbo.invoices i
                              JOIN dbo.enrollments e ON e.enrollment_id = i.enrollment_id
                              LEFT JOIN (SELECT invoice_id, SUM(CASE
                                   WHEN gateway_order_id IS NULL THEN amount_paid
                                   WHEN gateway_status IN ('SUCCESS','DEMO_SUBMITTED') THEN amount_paid
                                   ELSE 0 END) AS total_paid
                                         FROM dbo.payments GROUP BY invoice_id) p
                                ON p.invoice_id = i.invoice_id
                              WHERE e.student_id = ? AND i.status IN ('UNPAID','PARTIAL')), 0) AS outstandingBalance,
                    COALESCE((SELECT CAST(AVG(CASE WHEN x.max_marks > 0
                                                   THEN 100.0 * r.marks_obtained / x.max_marks END) AS DECIMAL(6,2))
                              FROM dbo.exam_results r
                              JOIN dbo.exams x ON x.exam_id = r.exam_id
                              WHERE r.student_id = ?), 0) AS resultAverage,
                    (SELECT COUNT(*) FROM dbo.notifications
                     WHERE recipient_id = ? AND is_read = 0) AS unreadNotifications,
                    (SELECT COUNT(*)
                     FROM dbo.exams x
                     JOIN dbo.enrollments e ON e.class_id = x.class_id
                     JOIN dbo.classes c ON c.class_id = e.class_id
                     WHERE e.student_id = ? AND e.status = 'ACTIVE' AND c.status = 'ACTIVE'
                       AND x.status = 'SCHEDULED' AND x.exam_date >= CAST(GETDATE() AS DATE)) AS upcomingExams
                """, studentId, studentId, studentId, studentId, studentId, studentId));

        data.put("classes", queryList(connection, """
                SELECT e.enrollment_id AS enrollmentId, c.class_id AS classId,
                       c.subject, c.batch, c.fee, c.status,
                       c.image_path AS imagePath, c.class_type AS classType,
                       c.meeting_link AS meetingLink,
                       COALESCE(t.first_name + ' ' + t.last_name, 'Unassigned') AS tutorName,
                       e.enrolled_at AS enrolledAt,
                       (SELECT TOP 1 s.day_of_week + ' ' + s.start_time + ' - ' + s.end_time
                        FROM dbo.timetable_slots s
                        WHERE s.class_id = c.class_id AND s.status = 'ACTIVE'
                        ORDER BY CASE s.day_of_week
                            WHEN 'MON' THEN 1 WHEN 'TUE' THEN 2 WHEN 'WED' THEN 3
                            WHEN 'THU' THEN 4 WHEN 'FRI' THEN 5 WHEN 'SAT' THEN 6 WHEN 'SUN' THEN 7 END,
                            s.start_time) AS classSchedule
                FROM dbo.enrollments e
                JOIN dbo.classes c ON c.class_id = e.class_id
                LEFT JOIN dbo.users t ON t.user_id = c.tutor_id
                WHERE e.student_id = ? AND e.status = 'ACTIVE' AND c.status = 'ACTIVE'
                ORDER BY c.subject, c.batch
                """, studentId));

        data.put("materials", queryList(connection, """
                SELECT m.material_id AS materialId, m.title, m.description,
                       m.file_path AS filePath, m.uploaded_at AS uploadedAt,
                       c.class_id AS classId, c.subject, c.batch
                FROM dbo.class_materials m
                JOIN dbo.classes c ON c.class_id = m.class_id
                JOIN dbo.enrollments e ON e.class_id = c.class_id
                WHERE e.student_id = ? AND e.status = 'ACTIVE' AND c.status = 'ACTIVE'
                ORDER BY m.uploaded_at DESC
                """, studentId));

        data.put("timetable", queryList(connection, """
                SELECT s.slot_id AS slotId, s.day_of_week AS dayOfWeek,
                       s.start_time AS startTime, s.end_time AS endTime, s.room,
                       c.subject, c.batch,
                       t.first_name + ' ' + t.last_name AS tutorName
                FROM dbo.timetable_slots s
                JOIN dbo.classes c ON c.class_id = s.class_id
                JOIN dbo.enrollments e ON e.class_id = c.class_id
                JOIN dbo.users t ON t.user_id = s.tutor_id
                WHERE e.student_id = ? AND e.status = 'ACTIVE' AND s.status = 'ACTIVE' AND c.status = 'ACTIVE'
                ORDER BY CASE s.day_of_week
                    WHEN 'MON' THEN 1 WHEN 'TUE' THEN 2 WHEN 'WED' THEN 3
                    WHEN 'THU' THEN 4 WHEN 'FRI' THEN 5 WHEN 'SAT' THEN 6 WHEN 'SUN' THEN 7 END,
                    s.start_time
                """, studentId));

        data.put("attendance", queryList(connection, """
                SELECT TOP 100 a.attendance_id AS attendanceId, a.session_date AS sessionDate,
                       a.status, a.remarks, c.subject, c.batch
                FROM dbo.attendance a
                JOIN dbo.classes c ON c.class_id = a.class_id
                WHERE a.student_id = ?
                ORDER BY a.session_date DESC, c.subject
                """, studentId));

        data.put("invoices", queryList(connection, invoiceListSql("WHERE e.student_id = ?", 100), studentId));
        data.put("payments", queryList(connection, """
                SELECT TOP 100 p.payment_id AS paymentId, p.invoice_id AS invoiceId,
                       p.amount_paid AS amountPaid, p.payment_method AS paymentMethod,
                       p.payment_date AS paymentDate, c.subject, c.batch
                FROM dbo.payments p
                JOIN dbo.invoices i ON i.invoice_id = p.invoice_id
                JOIN dbo.enrollments e ON e.enrollment_id = i.enrollment_id
                JOIN dbo.classes c ON c.class_id = e.class_id
                WHERE e.student_id = ?
                  AND (p.gateway_order_id IS NULL OR p.gateway_status IN ('SUCCESS','DEMO_SUBMITTED'))
                ORDER BY p.payment_date DESC
                """, studentId));

        data.put("results", queryList(connection, """
                SELECT r.result_id AS resultId, r.marks_obtained AS marksObtained, r.grade,
                       r.remarks, r.entered_at AS enteredAt,
                       x.exam_id AS examId, x.exam_name AS examName, x.exam_date AS examDate,
                       x.max_marks AS maxMarks,
                       c.subject, c.batch,
                       CASE WHEN EXISTS (
                           SELECT 1 FROM dbo.exam_mcq_submissions s
                           WHERE s.exam_id = x.exam_id AND s.student_id = r.student_id
                       ) OR EXISTS (
                           SELECT 1 FROM dbo.exam_mcq_questions q
                           WHERE q.exam_id = x.exam_id
                       ) THEN 1 ELSE 0 END AS hasQuiz
                FROM dbo.exam_results r
                JOIN dbo.exams x ON x.exam_id = r.exam_id
                JOIN dbo.classes c ON c.class_id = x.class_id
                WHERE r.student_id = ?
                ORDER BY x.exam_date DESC
                """, studentId));

        data.put("exams", queryList(connection, """
                SELECT DISTINCT x.exam_id AS examId, x.exam_name AS examName,
                       x.exam_date AS examDate, x.max_marks AS maxMarks, x.status,
                       c.subject, c.batch,
                       (SELECT COUNT(*) FROM dbo.exam_mcq_questions q WHERE q.exam_id = x.exam_id) AS questionCount,
                       CASE WHEN EXISTS (
                           SELECT 1 FROM dbo.exam_mcq_submissions s
                           WHERE s.exam_id = x.exam_id AND s.student_id = ?
                       ) THEN 1 ELSE 0 END AS hasSubmitted
                FROM dbo.exams x
                JOIN dbo.classes c ON c.class_id = x.class_id
                JOIN dbo.enrollments e ON e.class_id = x.class_id
                WHERE e.student_id = ? AND e.status = 'ACTIVE' AND c.status = 'ACTIVE'
                  AND x.status = 'SCHEDULED'
                  AND NOT EXISTS (
                      SELECT 1 FROM dbo.exam_results r
                      WHERE r.exam_id = x.exam_id AND r.student_id = ?
                  )
                ORDER BY x.exam_date ASC, x.exam_id ASC
                """, studentId, studentId, studentId));

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> examsList = (List<Map<String, Object>>) data.get("exams");
        @SuppressWarnings("unchecked")
        Map<String, Object> summaryMap = (Map<String, Object>) data.get("summary");
        if (summaryMap != null && examsList != null) {
            summaryMap.put("upcomingExams", examsList.size());
        }

        data.put("notifications", queryList(connection, notificationSql("WHERE n.recipient_id = ?", 50), studentId));
        return data;
    }

    private void putEmptyStudentData(Map<String, Object> data) {
        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("classCount", 0);
        summary.put("attendanceRate", 0);
        summary.put("outstandingBalance", 0);
        summary.put("resultAverage", 0);
        summary.put("unreadNotifications", 0);
        summary.put("upcomingExams", 0);
        data.put("student", new LinkedHashMap<String, Object>());
        data.put("summary", summary);
        for (String key : List.of("classes", "materials", "timetable", "attendance", "invoices",
                                  "payments", "results", "exams", "notifications")) {
            data.put(key, new ArrayList<Map<String, Object>>());
        }
    }

    private String invoiceListSql(String whereClause, int limit) {
        String where = whereClause == null || whereClause.isBlank()
                ? "WHERE i.status <> 'CANCELLED'"
                : whereClause + " AND i.status <> 'CANCELLED'";
        return """
                SELECT TOP %d
                    i.invoice_id AS invoiceId, i.amount, i.due_date AS dueDate, i.status,
                    e.enrollment_id AS enrollmentId, e.student_id AS studentId,
                    c.class_id AS classId, c.subject, c.batch,
                    u.first_name + ' ' + u.last_name AS studentName,
                    COALESCE(p.total_paid, 0) AS amountPaid,
                    i.amount - COALESCE(p.total_paid, 0) AS balance
                FROM dbo.invoices i
                JOIN dbo.enrollments e ON e.enrollment_id = i.enrollment_id
                JOIN dbo.classes c ON c.class_id = e.class_id
                JOIN dbo.users u ON u.user_id = e.student_id
                LEFT JOIN (SELECT invoice_id, SUM(CASE
                                   WHEN gateway_order_id IS NULL THEN amount_paid
                                   WHEN gateway_status IN ('SUCCESS','DEMO_SUBMITTED') THEN amount_paid
                                   ELSE 0 END) AS total_paid
                           FROM dbo.payments GROUP BY invoice_id) p
                  ON p.invoice_id = i.invoice_id
                %s
                ORDER BY i.due_date DESC, i.invoice_id DESC
                """.formatted(limit, where);
    }

    private String notificationSql(String whereClause, int limit) {
        String where = whereClause == null ? "" : whereClause;
        return """
                SELECT TOP %d
                    n.notification_id AS notificationId, n.recipient_id AS recipientId,
                    n.title, n.message, n.type, n.class_id AS classId,
                    n.is_read AS isRead, n.created_at AS createdAt,
                    COALESCE(c.subject, '') AS subject,
                    ru.first_name + ' ' + ru.last_name AS recipientName,
                    COALESCE(cu.first_name + ' ' + cu.last_name, 'System') AS createdByName
                FROM dbo.notifications n
                JOIN dbo.users ru ON ru.user_id = n.recipient_id
                LEFT JOIN dbo.classes c ON c.class_id = n.class_id
                LEFT JOIN dbo.users cu ON cu.user_id = n.created_by
                %s
                ORDER BY n.created_at DESC
                """.formatted(limit, where);
    }

    private Map<String, Object> queryOne(Connection connection, String sql, Object... params) throws SQLException {
        List<Map<String, Object>> rows = queryList(connection, sql, params);
        return rows.isEmpty() ? new LinkedHashMap<>() : rows.get(0);
    }

    private List<Map<String, Object>> queryList(Connection connection, String sql, Object... params) throws SQLException {
        List<Map<String, Object>> rows = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, params);
            try (ResultSet resultSet = statement.executeQuery()) {
                ResultSetMetaData meta = resultSet.getMetaData();
                int count = meta.getColumnCount();
                while (resultSet.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= count; i++) {
                        row.put(meta.getColumnLabel(i), resultSet.getObject(i));
                    }
                    rows.add(row);
                }
            }
        }
        return rows;
    }

    private void bind(PreparedStatement statement, Object... params) throws SQLException {
        for (int i = 0; i < params.length; i++) {
            statement.setObject(i + 1, params[i]);
        }
    }
}
