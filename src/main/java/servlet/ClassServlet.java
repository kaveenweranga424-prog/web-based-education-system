package servlet;

import dao.UserDAO;
import model.Class;
import model.TutorProfile;
import service.ClassService;
import service.TutorService;

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
import java.util.List;
import java.util.UUID;

/**
 * Admin-only: create, update, list and discontinue classes.
 */
@WebServlet("/admin/classes")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize = 10 * 1024 * 1024,
    maxRequestSize = 25 * 1024 * 1024
)
public class ClassServlet extends HttpServlet {

    private ClassService classService;
    private TutorService tutorService;
    private UserDAO userDAO;

    @Override
    public void init() {
        classService = new ClassService();
        tutorService = new TutorService();
        userDAO = new UserDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!ensureAdmin(request, response)) {
            return;
        }

        try {
            String action = request.getParameter("action");

            if ("edit".equals(action)) {
                int classId = Integer.parseInt(request.getParameter("id"));
                Class classItem = classService.findById(classId);
                request.setAttribute("classItem", classItem);
            }

            List<Class> classes = classService.findAll();
            List<TutorProfile> tutors = tutorService.findActiveTutors();

            request.setAttribute("classes", classes);
            request.setAttribute("tutors", tutors);

            request.getRequestDispatcher("/admin/manage-classes.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("/admin/manage-classes.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!ensureAdmin(request, response)) {
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");

        try {
            String errorMessage = null;

            Part imagePart = null;
            try {
                imagePart = request.getPart("classImage");
            } catch (Exception ignored) {}

            String imagePath = null;
            if (imagePart != null && imagePart.getSize() > 0) {
                imagePath = saveClassImage(imagePart, request);
                if (imagePath == null) {
                    errorMessage = "Invalid image file. Please upload a JPG, PNG, or WebP image.";
                }
            }

            if (errorMessage == null) {
                String classType = request.getParameter("classType");

                if ("update".equals(action)) {
                    int classId = Integer.parseInt(request.getParameter("classId"));

                    errorMessage = classService.updateClass(
                            classId,
                            request.getParameter("subject"),
                            request.getParameter("batch"),
                            request.getParameter("tutorId"),
                            request.getParameter("fee"),
                            request.getParameter("status"),
                            imagePath,
                            classType
                    );

                } else if ("delete".equals(action) || "discontinue".equals(action)) {
                    int classId = Integer.parseInt(request.getParameter("classId"));
                    errorMessage = classService.deleteClass(classId);
                    if (errorMessage == null) {
                        response.sendRedirect(request.getContextPath() + "/admin/classes");
                        return;
                    }

                } else {
                    // create
                    errorMessage = classService.createClass(
                            request.getParameter("subject"),
                            request.getParameter("batch"),
                            request.getParameter("tutorId"),
                            request.getParameter("fee"),
                            imagePath,
                            classType
                    );
                }
            }

            if (errorMessage != null) {
                request.setAttribute("errorMessage", errorMessage);
                request.setAttribute("classes", classService.findAll());
                request.setAttribute("tutors", tutorService.findActiveTutors());
                request.getRequestDispatcher("/admin/manage-classes.jsp").forward(request, response);
                return;
            }

            response.sendRedirect(request.getContextPath() + "/admin/classes");

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            try {
                request.setAttribute("tutors", tutorService.findActiveTutors());
            } catch (SQLException ignored) {}
            request.getRequestDispatcher("/admin/manage-classes.jsp").forward(request, response);
        }
    }

    private String saveClassImage(Part part, HttpServletRequest request) throws IOException {
        if (part == null || part.getSize() <= 0) {
            return null;
        }

        String submitted = part.getSubmittedFileName();
        if (submitted == null || submitted.isBlank()) {
            return null;
        }

        String ext = "";
        int dot = submitted.lastIndexOf('.');
        if (dot >= 0) {
            ext = submitted.substring(dot).toLowerCase();
        }

        if (!ext.equals(".jpg") && !ext.equals(".jpeg") && !ext.equals(".png") && !ext.equals(".webp")) {
            return null;
        }

        String uniqueName = "class_" + System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 8) + ext;

        String webappSubdir = "uploads" + File.separator + "classes";
        String realPath = request.getServletContext().getRealPath("/" + webappSubdir);
        File uploadDir = (realPath != null) ? new File(realPath) : new File("src/main/webapp/" + webappSubdir);
        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
        }

        File targetFile = new File(uploadDir, uniqueName);
        try (InputStream in = part.getInputStream(); OutputStream out = new FileOutputStream(targetFile)) {
            in.transferTo(out);
        }

        try {
            File srcDir = new File("C:/Users/New/Desktop/project SE/TutionManegment/src/main/webapp/uploads/classes");
            if (!srcDir.getCanonicalPath().equalsIgnoreCase(uploadDir.getCanonicalPath())) {
                srcDir.mkdirs();
                File srcFile = new File(srcDir, uniqueName);
                Files.copy(targetFile.toPath(), srcFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (Exception ignored) {}

        return "uploads/classes/" + uniqueName;
    }

    private boolean ensureAdmin(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return false;
        }

        String role = String.valueOf(session.getAttribute("userRole"));
        if (!"ADMIN".equalsIgnoreCase(role)) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return false;
        }

        return true;
    }
}
