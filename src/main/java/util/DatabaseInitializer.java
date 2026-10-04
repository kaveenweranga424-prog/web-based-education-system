package util;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

public class DatabaseInitializer {

    public static void initializeDatabase() {
        System.out.println("Checking database...");

        if (!createDatabaseIfMissing()) {
            System.out.println("Database initialization stopped because the database could not be created/checked.");
            return;
        }

        createUsersTableIfMissing();
        createParentStudentTableIfMissing();
        createTutorProfilesTableIfMissing();
        createClassesTableIfMissing();
        createEnrollmentsTableIfMissing();
        createClassMaterialsTableIfMissing();
        createTimetableSlotsTableIfMissing();
        createAttendanceTableIfMissing();
        createInvoicesTableIfMissing();
        createPaymentsTableIfMissing();
        createExamsTableIfMissing();
        createExamResultsTableIfMissing();
        createExamMcqTablesIfMissing();
        createNotificationsTableIfMissing();
        migrateEnrollmentWorkflowSchema();
        migrateRemoveStaffRoleSchema();
        migratePaymentGatewaySchema();
        migrateNotificationTypes();
        migrateClassesImageSchema();
        migrateClassesMeetingLinkSchema();
        migrateTimetableSlotsConfirmationSchema();
        System.out.println("Database initialization completed.");
    }

    private static boolean createDatabaseIfMissing() {
        String databaseName = DBUtil.getDatabaseName();

        String sql =
                "IF DB_ID(N'" + databaseName + "') IS NULL " +
                        "BEGIN " +
                        "CREATE DATABASE [" + databaseName + "] " +
                        "END";

        try (Connection connection = DBUtil.getServerConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Database '" + databaseName + "' checked/created successfully!");
            return true;

        } catch (SQLException e) {
            System.out.println("Failed to create/check database!");
            e.printStackTrace();
            return false;
        }
    }

    private static void createUsersTableIfMissing() {
        String sql = """
                IF OBJECT_ID(N'dbo.users', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.users (
                        user_id INT IDENTITY(1,1) PRIMARY KEY,
                        first_name VARCHAR(100) NOT NULL,
                        last_name VARCHAR(100) NOT NULL,
                        email VARCHAR(150) NOT NULL UNIQUE,
                        phone VARCHAR(20) NULL,
                        password VARCHAR(255) NOT NULL,
                        role VARCHAR(20) NOT NULL,
                        status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
                        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
                        updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT CK_users_role CHECK (
                            role IN ('ADMIN', 'TUTOR', 'STUDENT', 'PARENT')
                        ),

                        CONSTRAINT CK_users_status CHECK (
                            status IN ('ACTIVE', 'INACTIVE')
                        )
                    );
                END
                """;

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Users table checked/created successfully!");

        } catch (SQLException e) {
            System.out.println("Failed to create/check users table!");
            e.printStackTrace();
        }
    }

    private static void createParentStudentTableIfMissing() {
        String sql = """
                IF OBJECT_ID(N'dbo.parent_student', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.parent_student (
                        parent_student_id INT IDENTITY(1,1) PRIMARY KEY,
                        parent_user_id INT NOT NULL,
                        student_user_id INT NOT NULL,
                        relationship VARCHAR(30) NULL,
                        status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
                        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_parent_student_parent
                            FOREIGN KEY (parent_user_id)
                            REFERENCES dbo.users(user_id),

                        CONSTRAINT FK_parent_student_student
                            FOREIGN KEY (student_user_id)
                            REFERENCES dbo.users(user_id),

                        CONSTRAINT UQ_parent_student
                            UNIQUE (parent_user_id, student_user_id),

                        CONSTRAINT CK_parent_student_status CHECK (
                            status IN ('PENDING', 'ACTIVE', 'REJECTED')
                        )
                    );
                END
                """;

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Parent-student table checked/created successfully!");

        } catch (SQLException e) {
            System.out.println("Failed to create/check parent_student table!");
            e.printStackTrace();
        }
    }

    private static void createTutorProfilesTableIfMissing() {
        String sql = """
                IF OBJECT_ID(N'dbo.tutor_profiles', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.tutor_profiles (
                        tutor_profile_id INT IDENTITY(1,1) PRIMARY KEY,
                        user_id INT NOT NULL UNIQUE,
                        specialization VARCHAR(150) NULL,
                        bio VARCHAR(1000) NULL,
                        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_tutor_profiles_user
                            FOREIGN KEY (user_id)
                            REFERENCES dbo.users(user_id)
                    );
                END
                """;

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Tutor profiles table checked/created successfully!");

        } catch (SQLException e) {
            System.out.println("Failed to create/check tutor_profiles table!");
            e.printStackTrace();
        }
    }

    private static void createClassesTableIfMissing() {
        String sql = """
                IF OBJECT_ID(N'dbo.classes', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.classes (
                        class_id INT IDENTITY(1,1) PRIMARY KEY,
                        subject VARCHAR(100) NOT NULL,
                        batch VARCHAR(50) NOT NULL,
                        tutor_id INT NULL,
                        fee DECIMAL(10,2) NOT NULL DEFAULT 0,
                        status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
                        image_path NVARCHAR(500) NULL,
                        class_type VARCHAR(20) NOT NULL DEFAULT 'WEEKDAY',
                        meeting_link VARCHAR(500) NULL,
                        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
                        updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_classes_tutor
                            FOREIGN KEY (tutor_id)
                            REFERENCES dbo.users(user_id),

                        CONSTRAINT CK_classes_status CHECK (
                            status IN ('ACTIVE', 'INACTIVE')
                        ),

                        CONSTRAINT CK_classes_class_type CHECK (
                            class_type IN ('WEEKDAY', 'WEEKEND')
                        )
                    );
                END
                """;

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Classes table checked/created successfully!");

        } catch (SQLException e) {
            System.out.println("Failed to create/check classes table!");
            e.printStackTrace();
        }
    }

    private static void createEnrollmentsTableIfMissing() {
        String sql = """
                IF OBJECT_ID(N'dbo.enrollments', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.enrollments (
                        enrollment_id INT IDENTITY(1,1) PRIMARY KEY,
                        class_id INT NOT NULL,
                        student_id INT NOT NULL,
                        status VARCHAR(30) NOT NULL DEFAULT 'PENDING_PAYMENT',
                        enrolled_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_enrollments_class FOREIGN KEY (class_id) REFERENCES dbo.classes(class_id),
                        CONSTRAINT FK_enrollments_student FOREIGN KEY (student_id) REFERENCES dbo.users(user_id),
                        CONSTRAINT UQ_enrollments UNIQUE (class_id, student_id),
                        CONSTRAINT CK_enrollments_status CHECK (
                            status IN ('PENDING_PAYMENT','PAID_PENDING_ADMIN','PAID_PENDING_STAFF','STAFF_CONFIRMED',
                                       'ACTIVE','REJECTED','CANCELLED')
                        )
                    );
                END
                """;
        executeSchema(sql, "Enrollments table checked/created successfully!");
    }

    private static void createAttendanceTableIfMissing() {
        String sql = """
                IF OBJECT_ID(N'dbo.attendance', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.attendance (
                        attendance_id INT IDENTITY(1,1) PRIMARY KEY,
                        class_id INT NOT NULL,
                        student_id INT NOT NULL,
                        session_date DATE NOT NULL,
                        status VARCHAR(10) NOT NULL,
                        remarks VARCHAR(500) NULL,
                        marked_by INT NOT NULL,
                        marked_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_attendance_class
                            FOREIGN KEY (class_id)
                            REFERENCES dbo.classes(class_id),

                        CONSTRAINT FK_attendance_student
                            FOREIGN KEY (student_id)
                            REFERENCES dbo.users(user_id),

                        CONSTRAINT FK_attendance_marked_by
                            FOREIGN KEY (marked_by)
                            REFERENCES dbo.users(user_id),

                        CONSTRAINT UQ_attendance_session
                            UNIQUE (class_id, student_id, session_date),

                        CONSTRAINT CK_attendance_status CHECK (
                            status IN ('PRESENT', 'ABSENT', 'LATE')
                        )
                    );
                END
                """;

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Attendance table checked/created successfully!");

        } catch (SQLException e) {
            System.out.println("Failed to create/check attendance table!");
            e.printStackTrace();
        }
    }
    private static void createInvoicesTableIfMissing() {
        String sql = """
                IF OBJECT_ID(N'dbo.invoices', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.invoices (
                        invoice_id INT IDENTITY(1,1) PRIMARY KEY,
                        enrollment_id INT NOT NULL,
                        amount DECIMAL(10,2) NOT NULL,
                        due_date DATE NOT NULL,
                        status VARCHAR(20) NOT NULL DEFAULT 'UNPAID',
                        created_by INT NOT NULL,
                        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_invoices_enrollment
                            FOREIGN KEY (enrollment_id)
                            REFERENCES dbo.enrollments(enrollment_id),

                        CONSTRAINT FK_invoices_created_by
                            FOREIGN KEY (created_by)
                            REFERENCES dbo.users(user_id),

                        CONSTRAINT CK_invoices_status CHECK (
                            status IN ('UNPAID', 'PARTIAL', 'PAID', 'CANCELLED')
                        )
                    );
                END
                """;

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Invoices table checked/created successfully!");

        } catch (SQLException e) {
            System.out.println("Failed to create/check invoices table!");
            e.printStackTrace();
        }
    }

    private static void createPaymentsTableIfMissing() {
        String sql = """
                IF OBJECT_ID(N'dbo.payments', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.payments (
                        payment_id INT IDENTITY(1,1) PRIMARY KEY,
                        invoice_id INT NOT NULL,
                        amount_paid DECIMAL(10,2) NOT NULL,
                        payment_method VARCHAR(30) NOT NULL,
                        payment_date DATETIME2 NULL,
                        received_by INT NULL,
                        gateway_order_id VARCHAR(100) NULL,
                        gateway_payment_id VARCHAR(100) NULL,
                        gateway_status VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',
                        gateway_method VARCHAR(30) NULL,
                        masked_card_no VARCHAR(40) NULL,
                        card_holder_name VARCHAR(120) NULL,
                        slip_path VARCHAR(255) NULL,
                        bank_name VARCHAR(100) NULL,
                        branch_name VARCHAR(100) NULL,
                        staff_status VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED',
                        staff_note VARCHAR(500) NULL,
                        confirmed_by INT NULL,
                        confirmed_at DATETIME2 NULL,
                        admin_status VARCHAR(20) NOT NULL DEFAULT 'APPROVED',
                        admin_note VARCHAR(500) NULL,
                        approved_by INT NULL,
                        approved_at DATETIME2 NULL,
                        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_payments_invoice FOREIGN KEY (invoice_id) REFERENCES dbo.invoices(invoice_id),
                        CONSTRAINT FK_payments_received_by FOREIGN KEY (received_by) REFERENCES dbo.users(user_id),
                        CONSTRAINT FK_payments_confirmed_by FOREIGN KEY (confirmed_by) REFERENCES dbo.users(user_id),
                        CONSTRAINT FK_payments_approved_by FOREIGN KEY (approved_by) REFERENCES dbo.users(user_id),
                        CONSTRAINT CK_payments_method CHECK (payment_method IN ('CASH','BANK_TRANSFER','CARD','ONLINE','OTHER')),
                        CONSTRAINT CK_payments_gateway_status CHECK (gateway_status IN ('INITIATED','SUCCESS','DEMO_SUBMITTED','PENDING','FAILED','CANCELLED','CHARGEDBACK')),
                        CONSTRAINT CK_payments_staff_status CHECK (staff_status IN ('PENDING','CONFIRMED','REJECTED','CANCELLED')),
                        CONSTRAINT CK_payments_admin_status CHECK (admin_status IN ('PENDING','APPROVED','REJECTED'))
                    );
                    CREATE UNIQUE INDEX UX_payments_gateway_order_id
                    ON dbo.payments(gateway_order_id) WHERE gateway_order_id IS NOT NULL;
                END
                """;
        executeSchema(sql, "Payments table checked/created successfully!");
    }

    private static void createExamsTableIfMissing() {
        String sql = """
                IF OBJECT_ID(N'dbo.exams', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.exams (
                        exam_id INT IDENTITY(1,1) PRIMARY KEY,
                        class_id INT NOT NULL,
                        exam_name VARCHAR(150) NOT NULL,
                        exam_date DATE NOT NULL,
                        max_marks DECIMAL(6,2) NOT NULL,
                        status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
                        created_by INT NOT NULL,
                        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_exams_class
                            FOREIGN KEY (class_id)
                            REFERENCES dbo.classes(class_id),

                        CONSTRAINT FK_exams_created_by
                            FOREIGN KEY (created_by)
                            REFERENCES dbo.users(user_id),

                        CONSTRAINT CK_exams_status CHECK (
                            status IN ('SCHEDULED', 'COMPLETED', 'CANCELLED')
                        )
                    );
                END
                """;

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Exams table checked/created successfully!");

        } catch (SQLException e) {
            System.out.println("Failed to create/check exams table!");
            e.printStackTrace();
        }
    }

    private static void createExamResultsTableIfMissing() {
        String sql = """
                IF OBJECT_ID(N'dbo.exam_results', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.exam_results (
                        result_id INT IDENTITY(1,1) PRIMARY KEY,
                        exam_id INT NOT NULL,
                        student_id INT NOT NULL,
                        marks_obtained DECIMAL(6,2) NOT NULL,
                        grade VARCHAR(5) NOT NULL,
                        remarks VARCHAR(500) NULL,
                        entered_by INT NOT NULL,
                        entered_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_exam_results_exam
                            FOREIGN KEY (exam_id)
                            REFERENCES dbo.exams(exam_id),

                        CONSTRAINT FK_exam_results_student
                            FOREIGN KEY (student_id)
                            REFERENCES dbo.users(user_id),

                        CONSTRAINT FK_exam_results_entered_by
                            FOREIGN KEY (entered_by)
                            REFERENCES dbo.users(user_id),

                        CONSTRAINT UQ_exam_results
                            UNIQUE (exam_id, student_id)
                    );
                END
                """;

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Exam results table checked/created successfully!");

        } catch (SQLException e) {
            System.out.println("Failed to create/check exam_results table!");
            e.printStackTrace();
        }
    }

    private static void createExamMcqTablesIfMissing() {
        String questionsSql = """
                IF OBJECT_ID(N'dbo.exam_mcq_questions', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.exam_mcq_questions (
                        question_id INT IDENTITY(1,1) PRIMARY KEY,
                        exam_id INT NOT NULL,
                        question_text NVARCHAR(1000) NOT NULL,
                        option_a NVARCHAR(500) NOT NULL,
                        option_b NVARCHAR(500) NOT NULL,
                        option_c NVARCHAR(500) NOT NULL,
                        option_d NVARCHAR(500) NOT NULL,
                        correct_option CHAR(1) NOT NULL,
                        points DECIMAL(5,2) NOT NULL DEFAULT 1.0,
                        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_mcq_questions_exam FOREIGN KEY (exam_id)
                            REFERENCES dbo.exams(exam_id) ON DELETE CASCADE,
                        CONSTRAINT CK_mcq_correct_option CHECK (
                            correct_option IN ('A', 'B', 'C', 'D')
                        )
                    );
                END
                """;

        String submissionsSql = """
                IF OBJECT_ID(N'dbo.exam_mcq_submissions', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.exam_mcq_submissions (
                        submission_id INT IDENTITY(1,1) PRIMARY KEY,
                        exam_id INT NOT NULL,
                        student_id INT NOT NULL,
                        total_questions INT NOT NULL,
                        correct_answers INT NOT NULL,
                        score_obtained DECIMAL(6,2) NOT NULL,
                        max_possible DECIMAL(6,2) NOT NULL,
                        submitted_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_mcq_sub_exam FOREIGN KEY (exam_id)
                            REFERENCES dbo.exams(exam_id),
                        CONSTRAINT FK_mcq_sub_student FOREIGN KEY (student_id)
                            REFERENCES dbo.users(user_id),
                        CONSTRAINT UQ_mcq_student_submission UNIQUE (exam_id, student_id)
                    );
                END
                """;

        String answersSql = """
                IF OBJECT_ID(N'dbo.exam_mcq_answers', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.exam_mcq_answers (
                        answer_id INT IDENTITY(1,1) PRIMARY KEY,
                        submission_id INT NOT NULL,
                        question_id INT NOT NULL,
                        selected_option CHAR(1) NULL,
                        is_correct BIT NOT NULL DEFAULT 0,

                        CONSTRAINT FK_mcq_ans_submission FOREIGN KEY (submission_id)
                            REFERENCES dbo.exam_mcq_submissions(submission_id) ON DELETE CASCADE,
                        CONSTRAINT FK_mcq_ans_question FOREIGN KEY (question_id)
                            REFERENCES dbo.exam_mcq_questions(question_id)
                    );
                END
                """;

        executeSchema(questionsSql, "MCQ questions table checked/created successfully!");
        executeSchema(submissionsSql, "MCQ submissions table checked/created successfully!");
        executeSchema(answersSql, "MCQ answers table checked/created successfully!");
    }

    private static void createNotificationsTableIfMissing() {
        String sql = """
                IF OBJECT_ID(N'dbo.notifications', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.notifications (
                        notification_id INT IDENTITY(1,1) PRIMARY KEY,
                        recipient_id INT NOT NULL,
                        title VARCHAR(200) NOT NULL,
                        message VARCHAR(1000) NOT NULL,
                        type VARCHAR(30) NOT NULL,
                        class_id INT NULL,
                        is_read BIT NOT NULL DEFAULT 0,
                        created_by INT NULL,
                        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_notifications_recipient
                            FOREIGN KEY (recipient_id)
                            REFERENCES dbo.users(user_id),

                        CONSTRAINT FK_notifications_class
                            FOREIGN KEY (class_id)
                            REFERENCES dbo.classes(class_id),

                        CONSTRAINT FK_notifications_created_by
                            FOREIGN KEY (created_by)
                            REFERENCES dbo.users(user_id),

                        CONSTRAINT CK_notifications_type CHECK (
                            type IN ('ATTENDANCE', 'FEE', 'RESULT', 'ANNOUNCEMENT', 'GENERAL', 'PAYMENT', 'ENROLLMENT')
                        )
                    );
                END
                """;

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Notifications table checked/created successfully!");

        } catch (SQLException e) {
            System.out.println("Failed to create/check notifications table!");
            e.printStackTrace();
        }
    }

    private static void migrateEnrollmentWorkflowSchema() {
        String sql = """
                IF OBJECT_ID(N'dbo.enrollments', N'U') IS NOT NULL
                BEGIN
                    IF EXISTS (SELECT 1 FROM sys.check_constraints
                               WHERE parent_object_id = OBJECT_ID(N'dbo.enrollments')
                                 AND name = 'CK_enrollments_status')
                        ALTER TABLE dbo.enrollments DROP CONSTRAINT CK_enrollments_status;

                    ALTER TABLE dbo.enrollments ADD CONSTRAINT CK_enrollments_status CHECK (
                        status IN ('PENDING_PAYMENT','PAID_PENDING_ADMIN','PAID_PENDING_STAFF','STAFF_CONFIRMED',
                                   'ACTIVE','REJECTED','CANCELLED')
                    );

                    UPDATE dbo.enrollments SET status = 'PAID_PENDING_ADMIN' WHERE status = 'PAID_PENDING_STAFF';
                END
                """;
        executeSchema(sql, "Enrollment workflow schema checked.");
    }

    private static void migrateRemoveStaffRoleSchema() {
        String sql = """
                IF OBJECT_ID(N'dbo.users', N'U') IS NOT NULL
                BEGIN
                    UPDATE dbo.users SET role = 'ADMIN', status = 'INACTIVE' WHERE role = 'STAFF';

                    IF EXISTS (SELECT 1 FROM sys.check_constraints
                               WHERE parent_object_id = OBJECT_ID(N'dbo.users')
                                 AND name = 'CK_users_role')
                        ALTER TABLE dbo.users DROP CONSTRAINT CK_users_role;

                    ALTER TABLE dbo.users ADD CONSTRAINT CK_users_role CHECK (
                        role IN ('ADMIN', 'TUTOR', 'STUDENT', 'PARENT')
                    );
                END

                IF OBJECT_ID(N'dbo.payments', N'U') IS NOT NULL
                BEGIN
                    UPDATE dbo.payments SET staff_status = 'CONFIRMED' WHERE staff_status = 'PENDING';
                END
                """;
        executeSchema(sql, "Staff role removal and payment workflow schema checked.");
    }

    private static void migratePaymentGatewaySchema() {
        // Each ALTER runs in its own batch. This avoids SQL Server compiling an index/constraint
        // before a newly-added column is visible in the same batch.
        String[] migrations = {
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','gateway_order_id') IS NULL ALTER TABLE dbo.payments ADD gateway_order_id VARCHAR(100) NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','gateway_payment_id') IS NULL ALTER TABLE dbo.payments ADD gateway_payment_id VARCHAR(100) NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','gateway_status') IS NULL ALTER TABLE dbo.payments ADD gateway_status VARCHAR(20) NOT NULL CONSTRAINT DF_payments_gateway_status DEFAULT 'SUCCESS'",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','gateway_method') IS NULL ALTER TABLE dbo.payments ADD gateway_method VARCHAR(30) NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','masked_card_no') IS NULL ALTER TABLE dbo.payments ADD masked_card_no VARCHAR(40) NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','card_holder_name') IS NULL ALTER TABLE dbo.payments ADD card_holder_name VARCHAR(120) NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','staff_status') IS NULL ALTER TABLE dbo.payments ADD staff_status VARCHAR(20) NOT NULL CONSTRAINT DF_payments_staff_status DEFAULT 'CONFIRMED'",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','staff_note') IS NULL ALTER TABLE dbo.payments ADD staff_note VARCHAR(500) NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','confirmed_by') IS NULL ALTER TABLE dbo.payments ADD confirmed_by INT NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','confirmed_at') IS NULL ALTER TABLE dbo.payments ADD confirmed_at DATETIME2 NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','admin_status') IS NULL ALTER TABLE dbo.payments ADD admin_status VARCHAR(20) NOT NULL CONSTRAINT DF_payments_admin_status DEFAULT 'APPROVED'",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','admin_note') IS NULL ALTER TABLE dbo.payments ADD admin_note VARCHAR(500) NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','approved_by') IS NULL ALTER TABLE dbo.payments ADD approved_by INT NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','approved_at') IS NULL ALTER TABLE dbo.payments ADD approved_at DATETIME2 NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('dbo.payments') AND name='received_by' AND is_nullable=0) ALTER TABLE dbo.payments ALTER COLUMN received_by INT NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('dbo.payments') AND name='payment_date' AND is_nullable=0) ALTER TABLE dbo.payments ALTER COLUMN payment_date DATETIME2 NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_payments_confirmed_by') ALTER TABLE dbo.payments ADD CONSTRAINT FK_payments_confirmed_by FOREIGN KEY (confirmed_by) REFERENCES dbo.users(user_id)",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_payments_approved_by') ALTER TABLE dbo.payments ADD CONSTRAINT FK_payments_approved_by FOREIGN KEY (approved_by) REFERENCES dbo.users(user_id)",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_payments_gateway_order_id' AND object_id=OBJECT_ID('dbo.payments')) CREATE UNIQUE INDEX UX_payments_gateway_order_id ON dbo.payments(gateway_order_id) WHERE gateway_order_id IS NOT NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','slip_path') IS NULL ALTER TABLE dbo.payments ADD slip_path VARCHAR(255) NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','bank_name') IS NULL ALTER TABLE dbo.payments ADD bank_name VARCHAR(100) NULL",
                "IF OBJECT_ID(N'dbo.payments',N'U') IS NOT NULL AND COL_LENGTH('dbo.payments','branch_name') IS NULL ALTER TABLE dbo.payments ADD branch_name VARCHAR(100) NULL"
        };
        String checks = """
                IF OBJECT_ID(N'dbo.payments', N'U') IS NOT NULL
                BEGIN
                    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'dbo.payments') AND name='CK_payments_gateway_status')
                        ALTER TABLE dbo.payments DROP CONSTRAINT CK_payments_gateway_status;
                    ALTER TABLE dbo.payments ADD CONSTRAINT CK_payments_gateway_status CHECK (
                        gateway_status IN ('INITIATED','SUCCESS','DEMO_SUBMITTED','SLIP_SUBMITTED','PENDING','FAILED','CANCELLED','CHARGEDBACK')
                    );

                    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'dbo.payments') AND name='CK_payments_staff_status')
                        ALTER TABLE dbo.payments DROP CONSTRAINT CK_payments_staff_status;
                    ALTER TABLE dbo.payments ADD CONSTRAINT CK_payments_staff_status CHECK (
                        staff_status IN ('PENDING','CONFIRMED','REJECTED','CANCELLED')
                    );

                    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'dbo.payments') AND name='CK_payments_admin_status')
                        ALTER TABLE dbo.payments DROP CONSTRAINT CK_payments_admin_status;
                    ALTER TABLE dbo.payments ADD CONSTRAINT CK_payments_admin_status CHECK (
                        admin_status IN ('PENDING','APPROVED','REJECTED')
                    );
                END
                """;
        try (Connection connection = DBUtil.getConnection()) {
            for (String migration : migrations) {
                executeSchema(connection, migration, "Payment workflow column/index checked.");
            }
            executeSchema(connection, checks, "Demo payment status constraints checked.");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private static void migrateNotificationTypes() {
        String sql = """
                IF OBJECT_ID(N'dbo.notifications', N'U') IS NOT NULL
                BEGIN
                    IF EXISTS (SELECT 1 FROM sys.check_constraints
                               WHERE parent_object_id = OBJECT_ID(N'dbo.notifications')
                                 AND name = 'CK_notifications_type')
                        ALTER TABLE dbo.notifications DROP CONSTRAINT CK_notifications_type;

                    ALTER TABLE dbo.notifications ADD CONSTRAINT CK_notifications_type CHECK (
                        type IN ('ATTENDANCE','FEE','RESULT','ANNOUNCEMENT','GENERAL','PAYMENT','ENROLLMENT','TIMETABLE')
                    );
                END
                """;
        executeSchema(sql, "Notification types checked.");
    }

    private static void executeSchema(String sql, String successMessage) {
        executeSchema(null, sql, successMessage);
    }

    private static void executeSchema(Connection conn, String sql, String successMessage) {
        boolean closeAfter = false;
        try {
            Connection connection = conn;
            if (connection == null || connection.isClosed()) {
                connection = DBUtil.getConnection();
                closeAfter = true;
            }
            try (Statement statement = connection.createStatement()) {
                statement.execute(sql);
                System.out.println(successMessage);
            } finally {
                if (closeAfter && connection != null) {
                    connection.close();
                }
            }
        } catch (SQLException e) {
            System.out.println("Database schema update failed: " + successMessage);
            e.printStackTrace();
        }
    }

    private static void createClassMaterialsTableIfMissing() {
        String sql = """
                IF OBJECT_ID(N'dbo.class_materials', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.class_materials (
                        material_id INT IDENTITY(1,1) PRIMARY KEY,
                        class_id INT NOT NULL,
                        title VARCHAR(200) NOT NULL,
                        description VARCHAR(1000) NULL,
                        file_path VARCHAR(500) NOT NULL,
                        uploaded_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_class_materials_class
                            FOREIGN KEY (class_id)
                            REFERENCES dbo.classes(class_id)
                    );
                END
                """;

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Class materials table checked/created successfully!");

        } catch (SQLException e) {
            System.out.println("Failed to create/check class_materials table!");
            e.printStackTrace();
        }
    }

    private static void createTimetableSlotsTableIfMissing() {
        String sql = """
                IF OBJECT_ID(N'dbo.timetable_slots', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.timetable_slots (
                        slot_id INT IDENTITY(1,1) PRIMARY KEY,
                        class_id INT NOT NULL,
                        tutor_id INT NOT NULL,
                        day_of_week VARCHAR(10) NOT NULL,
                        start_time VARCHAR(5) NOT NULL,
                        end_time VARCHAR(5) NOT NULL,
                        room VARCHAR(50) NULL,
                        status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
                        created_at DATETIME2 NOT NULL DEFAULT GETDATE(),

                        CONSTRAINT FK_timetable_class
                            FOREIGN KEY (class_id)
                            REFERENCES dbo.classes(class_id),

                        CONSTRAINT FK_timetable_tutor
                            FOREIGN KEY (tutor_id)
                            REFERENCES dbo.users(user_id),

                        CONSTRAINT CK_timetable_day CHECK (
                            day_of_week IN ('MON','TUE','WED','THU','FRI','SAT','SUN')
                        ),

                        CONSTRAINT CK_timetable_status CHECK (
                            status IN ('ACTIVE', 'CANCELLED')
                        )
                    );
                END
                """;

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Timetable slots table checked/created successfully!");

        } catch (SQLException e) {
            System.out.println("Failed to create/check timetable_slots table!");
            e.printStackTrace();
        }
    }

    private static void migrateClassesImageSchema() {
        String sql = """
                IF OBJECT_ID(N'dbo.classes', N'U') IS NOT NULL
                BEGIN
                    IF COL_LENGTH('dbo.classes', 'image_path') IS NULL
                    BEGIN
                        ALTER TABLE dbo.classes ADD image_path NVARCHAR(500) NULL;
                    END
                END
                """;

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Classes image_path column checked.");

        } catch (SQLException e) {
            System.out.println("Failed to migrate classes image_path column!");
            e.printStackTrace();
        }
    }

    private static void migrateClassesMeetingLinkSchema() {
        String sql = """
                IF OBJECT_ID(N'dbo.classes', N'U') IS NOT NULL
                BEGIN
                    IF COL_LENGTH('dbo.classes', 'meeting_link') IS NULL
                    BEGIN
                        ALTER TABLE dbo.classes ADD meeting_link VARCHAR(500) NULL;
                    END
                END
                """;

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement()) {

            statement.execute(sql);
            System.out.println("Classes meeting_link column checked.");

        } catch (SQLException e) {
            System.out.println("Failed to migrate classes meeting_link column!");
            e.printStackTrace();
        }
    }

    private static void migrateTimetableSlotsConfirmationSchema() {
        String[] migrations = {
                "IF OBJECT_ID(N'dbo.timetable_slots', N'U') IS NOT NULL AND COL_LENGTH('dbo.timetable_slots', 'confirmation_status') IS NULL ALTER TABLE dbo.timetable_slots ADD confirmation_status VARCHAR(30) NOT NULL CONSTRAINT DF_timetable_slots_conf_status DEFAULT 'CONFIRMED'",
                "IF OBJECT_ID(N'dbo.timetable_slots', N'U') IS NOT NULL AND COL_LENGTH('dbo.timetable_slots', 'suggested_day') IS NULL ALTER TABLE dbo.timetable_slots ADD suggested_day VARCHAR(10) NULL",
                "IF OBJECT_ID(N'dbo.timetable_slots', N'U') IS NOT NULL AND COL_LENGTH('dbo.timetable_slots', 'suggested_start_time') IS NULL ALTER TABLE dbo.timetable_slots ADD suggested_start_time VARCHAR(5) NULL",
                "IF OBJECT_ID(N'dbo.timetable_slots', N'U') IS NOT NULL AND COL_LENGTH('dbo.timetable_slots', 'suggested_end_time') IS NULL ALTER TABLE dbo.timetable_slots ADD suggested_end_time VARCHAR(5) NULL",
                "IF OBJECT_ID(N'dbo.timetable_slots', N'U') IS NOT NULL AND COL_LENGTH('dbo.timetable_slots', 'tutor_note') IS NULL ALTER TABLE dbo.timetable_slots ADD tutor_note VARCHAR(500) NULL",
                "IF OBJECT_ID(N'dbo.timetable_slots', N'U') IS NOT NULL AND COL_LENGTH('dbo.timetable_slots', 'responded_at') IS NULL ALTER TABLE dbo.timetable_slots ADD responded_at DATETIME2 NULL"
        };

        String checkConstraint = """
                IF OBJECT_ID(N'dbo.timetable_slots', N'U') IS NOT NULL
                BEGIN
                    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.timetable_slots') AND name = 'CK_timetable_confirmation_status')
                        ALTER TABLE dbo.timetable_slots DROP CONSTRAINT CK_timetable_confirmation_status;

                    ALTER TABLE dbo.timetable_slots ADD CONSTRAINT CK_timetable_confirmation_status CHECK (
                        confirmation_status IN ('PENDING', 'CONFIRMED', 'CHANGE_SUGGESTED')
                    );
                END
                """;

        try (Connection connection = DBUtil.getConnection()) {
            for (String m : migrations) {
                executeSchema(connection, m, "Timetable slot confirmation column checked.");
            }
            executeSchema(connection, checkConstraint, "Timetable slot confirmation constraint checked.");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        initializeDatabase();
    }
}