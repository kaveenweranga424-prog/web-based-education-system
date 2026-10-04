package servlet;

import dao.ClassDAO;
import dao.EnrollmentDAO;
import dao.ParentStudentDAO;
import model.Class;
import model.ClassMaterial;
import service.ClassMaterialService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.sql.SQLException;
import java.util.List;

@WebServlet("/materials/download")
public class MaterialDownloadServlet extends HttpServlet {

    private ClassMaterialService materialService;
    private ClassDAO classDAO;
    private EnrollmentDAO enrollmentDAO;
    private ParentStudentDAO parentStudentDAO;

    @Override
    public void init() {
        materialService = new ClassMaterialService();
        classDAO = new ClassDAO();
        enrollmentDAO = new EnrollmentDAO();
        parentStudentDAO = new ParentStudentDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        int userId = ((Number) session.getAttribute("userId")).intValue();
        String role = String.valueOf(session.getAttribute("userRole")).toUpperCase();

        String materialIdParam = request.getParameter("materialId");
        if (materialIdParam == null || materialIdParam.isBlank()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing materialId parameter.");
            return;
        }

        int materialId;
        try {
            materialId = Integer.parseInt(materialIdParam);
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid materialId parameter.");
            return;
        }

        try {
            ClassMaterial material = materialService.findById(materialId);
            if (material == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Study material not found.");
                return;
            }

            int classId = material.getClassId();
            boolean authorized = false;

            if ("ADMIN".equals(role)) {
                authorized = true;
            } else if ("TUTOR".equals(role)) {
                Class c = classDAO.findById(classId);
                if (c != null && c.getTutorId() != null && c.getTutorId() == userId) {
                    authorized = true;
                }
            } else if ("STUDENT".equals(role)) {
                if (enrollmentDAO.isEnrolled(classId, userId)) {
                    authorized = true;
                }
            } else if ("PARENT".equals(role)) {
                List<Integer> childIds = parentStudentDAO.findActiveStudentIdsForParent(userId);
                for (Integer childId : childIds) {
                    if (enrollmentDAO.isEnrolled(classId, childId)) {
                        authorized = true;
                        break;
                    }
                }
            }

            if (!authorized) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to download this material.");
                return;
            }

            String storedPath = material.getFilePath();
            if (storedPath == null || storedPath.isBlank()) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Material file path is missing.");
                return;
            }

            File file = new File(storedPath);
            if (!file.exists() || !file.isFile()) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "The requested file could not be found on the server storage.");
                return;
            }

            String mimeType = getServletContext().getMimeType(file.getName());
            if (mimeType == null) {
                mimeType = "application/octet-stream";
            }

            response.setContentType(mimeType);
            response.setContentLengthLong(file.length());

            String downloadName = file.getName();
            int underscoreIdx = downloadName.indexOf('_');
            if (underscoreIdx > 0 && underscoreIdx < downloadName.length() - 1) {
                downloadName = downloadName.substring(underscoreIdx + 1);
            }
            downloadName = downloadName.replaceAll("[^a-zA-Z0-9._-]", "_");

            response.setHeader("Content-Disposition", "attachment; filename=\"" + downloadName + "\"");

            try (FileInputStream in = new FileInputStream(file);
                 OutputStream out = response.getOutputStream()) {
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = in.read(buffer)) != -1) {
                    out.write(buffer, 0, bytesRead);
                }
                out.flush();
            }

        } catch (SQLException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error retrieving material.");
        }
    }
}
