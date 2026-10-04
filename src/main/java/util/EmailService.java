package util;

import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import java.io.InputStream;
import java.util.Properties;

/**
 * Service to dispatch emails (such as tutor account credentials) via SMTP.
 * If SMTP credentials are not configured, it gracefully falls back to logging the email to console
 * so that local development and testing proceed seamlessly without failure.
 */
public class EmailService {

    private static final Properties props = new Properties();
    private static boolean isConfigured = false;

    static {
        loadProperties();
    }

    private static void loadProperties() {
        try (InputStream in = EmailService.class.getClassLoader().getResourceAsStream("email.properties")) {
            if (in != null) {
                props.load(in);
            }
        } catch (Exception e) {
            System.err.println("Could not load email.properties: " + e.getMessage());
        }

        String username = props.getProperty("mail.smtp.username");
        String password = props.getProperty("mail.smtp.password");

        // Consider configured only if username & password are non-blank and not placeholders
        isConfigured = username != null && !username.isBlank() &&
                       password != null && !password.isBlank() &&
                       !password.contains("your_password");
    }

    public static boolean isConfigured() {
        loadProperties(); // dynamically re-check in case properties file was edited
        return isConfigured;
    }

    /**
     * Sends an email with the tutor's login email and temporary password.
     *
     * @param recipientEmail The tutor's personal email
     * @param tutorName      The tutor's name (e.g. Kasun Perera)
     * @param tempPassword   The generated/provided temporary password
     * @param loginUrl       Direct URL to the login page (or null for default)
     * @return true if dispatched or successfully simulated in dev mode; false on failure.
     */
    public static boolean sendTutorCredentials(String recipientEmail, String tutorName,
                                              String tempPassword, String loginUrl) {
        if (loginUrl == null || loginUrl.isBlank()) {
            loginUrl = "http://localhost:8080/TutionManegment/login";
        }

        String subject = "Welcome to Classora - Your Tutor Account Credentials";

        if (!isConfigured) {
            logDevEmail(recipientEmail, tutorName, tempPassword, loginUrl);
            return true;
        }

        try {
            final String username = props.getProperty("mail.smtp.username").trim();
            final String password = props.getProperty("mail.smtp.password").replace(" ", "").trim();
            final String fromEmail = props.getProperty("mail.from", username).trim();
            final String fromName = props.getProperty("mail.from.name", "Classora Tuition Management").trim();

            Session session = Session.getInstance(props, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(username, password);
                }
            });

            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(fromEmail, fromName));
            message.setRecipient(Message.RecipientType.TO, new InternetAddress(recipientEmail));
            message.setSubject(subject, "UTF-8");

            String htmlBody = buildTutorCredentialsHtml(tutorName, recipientEmail, tempPassword, loginUrl);
            message.setContent(htmlBody, "text/html; charset=UTF-8");

            Transport.send(message);
            System.out.println("[EMAIL SERVICE] Credentials email successfully sent to " + recipientEmail);
            return true;

        } catch (Exception e) {
            System.err.println("[EMAIL SERVICE ERROR] Failed to send email to " + recipientEmail + ": " + e.getMessage());
            // Fall back to console log so admin/dev can still see the temporary password
            logDevEmail(recipientEmail, tutorName, tempPassword, loginUrl);
            return false;
        }
    }

    private static void logDevEmail(String recipientEmail, String tutorName, String tempPassword, String loginUrl) {
        System.out.println();
        System.out.println("==================================================================================");
        System.out.println("                     [CLASSORA EMAIL SERVICE - DEV / SIMULATION MODE]             ");
        System.out.println("==================================================================================");
        System.out.println("To:                 " + recipientEmail + " (" + (tutorName != null ? tutorName : "Tutor") + ")");
        System.out.println("Subject:            Welcome to Classora - Your Tutor Account Credentials");
        System.out.println("Login Email:        " + recipientEmail);
        System.out.println("Temporary Password: " + tempPassword);
        System.out.println("Login URL:          " + loginUrl);
        System.out.println("Note:               To send real emails, enter your SMTP details in email.properties.");
        System.out.println("==================================================================================");
        System.out.println();
    }

    private static String buildTutorCredentialsHtml(String name, String email, String password, String loginUrl) {
        return """
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <style>
                body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8fafc; margin: 0; padding: 24px; color: #1e293b; }
                .email-container { max-width: 580px; margin: 0 auto; background: #ffffff; border-radius: 14px; overflow: hidden; border: 1px solid #e2e8f0; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
                .header { background: linear-gradient(135deg, #1e3a8a, #3b82f6); padding: 32px 28px; text-align: center; color: #ffffff; }
                .header h1 { margin: 0; font-size: 24px; font-weight: 700; letter-spacing: -0.5px; }
                .header p { margin: 6px 0 0; font-size: 14px; opacity: 0.9; }
                .content { padding: 32px 28px; }
                .greeting { font-size: 16px; font-weight: 600; margin-bottom: 12px; }
                .info-box { background: #f1f5f9; border-radius: 10px; padding: 18px 20px; margin: 20px 0; border-left: 4px solid #3b82f6; }
                .cred-row { margin-bottom: 8px; font-size: 14px; }
                .cred-label { font-weight: 600; color: #64748b; width: 150px; display: inline-block; }
                .cred-val { font-weight: 700; color: #0f172a; font-family: monospace; font-size: 15px; }
                .btn { display: inline-block; background: #2563eb; color: #ffffff !important; text-decoration: none; padding: 12px 26px; border-radius: 8px; font-weight: 600; font-size: 14px; margin-top: 12px; text-align: center; }
                .notice { font-size: 13px; color: #64748b; margin-top: 24px; line-height: 1.5; border-top: 1px solid #f1f5f9; padding-top: 16px; }
                .footer { background: #f8fafc; padding: 16px 28px; text-align: center; font-size: 12px; color: #94a3b8; }
              </style>
            </head>
            <body>
              <div class="email-container">
                <div class="header">
                  <h1>Classora Tuition Management</h1>
                  <p>Tutor Account Activation</p>
                </div>
                <div class="content">
                  <div class="greeting">Hello %s,</div>
                  <p>Your tutor account has been created by the institute administrator. You can now log in to the Classora Tutor Portal using the temporary credentials below:</p>
                  <div class="info-box">
                    <div class="cred-row"><span class="cred-label">Login Email:</span> <span class="cred-val">%s</span></div>
                    <div class="cred-row"><span class="cred-label">Temporary Password:</span> <span class="cred-val">%s</span></div>
                  </div>
                  <div style="text-align: center; margin: 28px 0 16px;">
                    <a href="%s" class="btn">Sign In to Tutor Portal</a>
                  </div>
                  <div class="notice">
                    <strong>Important Security Note:</strong> For security reasons, please change your temporary password to a personal secure password upon signing in. You can change your password anytime directly from your tutor dashboard.
                  </div>
                </div>
                <div class="footer">
                  &copy; Classora Tuition Management System. This is an automated message.
                </div>
              </div>
            </body>
            </html>
            """.formatted(
                name != null ? name : "Tutor",
                email,
                password,
                loginUrl
            );
    }
}
