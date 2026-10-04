package servlet;

import model.Class;
import model.ClassMaterial;
import model.Enrollment;
import service.ClassMaterialService;
import service.ClassService;
import service.EnrollmentService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;
import java.util.Collections;
import java.util.List;

@WebServlet(urlPatterns = {"/enroll", "/classes/view"})
public class EnrollmentServlet extends HttpServlet {
    private EnrollmentService enrollmentService;
    private ClassService classService;
    private ClassMaterialService materialService;
    private dao.TimetableDAO timetableDAO;

    @Override
    public void init() {
        enrollmentService = new EnrollmentService();
        classService = new ClassService();
        materialService = new ClassMaterialService();
        timetableDAO = new dao.TimetableDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            String classIdParam = request.getParameter("classId");
            if (classIdParam == null || classIdParam.trim().isEmpty()) {
                classIdParam = request.getParameter("id");
            }
            if (classIdParam == null || classIdParam.trim().isEmpty()) {
                response.sendRedirect(request.getContextPath() + "/classes");
                return;
            }
            int classId = Integer.parseInt(classIdParam.trim());
            Class classItem = classService.findById(classId);
            if (classItem == null) {
                response.sendRedirect(request.getContextPath() + "/classes");
                return;
            }

            HttpSession session = request.getSession(false);
            String role = session != null ? String.valueOf(session.getAttribute("userRole")) : "";

            if (!"ADMIN".equalsIgnoreCase(role) && !"TUTOR".equalsIgnoreCase(role) && !"ACTIVE".equalsIgnoreCase(classItem.getStatus())) {
                if (session != null) {
                    session.setAttribute("flashError", "This class is no longer active or has been discontinued.");
                }
                response.sendRedirect(request.getContextPath() + "/dashboard");
                return;
            }

            request.setAttribute("classItem", classItem);
            request.setAttribute("timetableSlots", timetableDAO.findByClass(classId));
            request.setAttribute("materials", Collections.emptyList());
            request.setAttribute("canViewMaterials", false);

            if (session != null && session.getAttribute("userId") != null) {
                int userId = ((Number) session.getAttribute("userId")).intValue();

                if ("STUDENT".equalsIgnoreCase(role)) {
                    Enrollment enrollment = enrollmentService.findAnyByClassAndStudent(classId, userId);
                    request.setAttribute("enrollmentRequest", enrollment);
                    boolean active = enrollment != null && "ACTIVE".equalsIgnoreCase(enrollment.getStatus());
                    request.setAttribute("alreadyEnrolled", active);
                    request.setAttribute("canViewMaterials", active);
                    if (active) {
                        request.setAttribute("materials", materialService.findByClass(classId));
                    }
                } else if ("PARENT".equalsIgnoreCase(role)) {
                    dao.ParentStudentDAO psDao = new dao.ParentStudentDAO();
                    List<Integer> childIds = psDao.findActiveStudentIdsForParent(userId);
                    boolean anyActive = false;
                    for (Integer chId : childIds) {
                        Enrollment en = enrollmentService.findAnyByClassAndStudent(classId, chId);
                        if (en != null && "ACTIVE".equalsIgnoreCase(en.getStatus())) {
                            anyActive = true;
                            break;
                        }
                    }
                    request.setAttribute("canViewMaterials", anyActive);
                    if (anyActive) {
                        request.setAttribute("materials", materialService.findByClass(classId));
                    }
                } else if ("TUTOR".equalsIgnoreCase(role) || "ADMIN".equalsIgnoreCase(role)) {
                    request.setAttribute("canViewMaterials", true);
                    request.setAttribute("materials", materialService.findByClass(classId));
                }
            }
            request.getRequestDispatcher("/class-details.jsp").forward(request, response);
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/classes");
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("/class-details.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,HttpServletResponse response)
            throws ServletException,IOException {
        HttpSession session=request.getSession(false);
        if(session==null || session.getAttribute("userId")==null){
            response.sendRedirect(request.getContextPath()+"/login.jsp"); return;
        }
        if(!"STUDENT".equalsIgnoreCase(String.valueOf(session.getAttribute("userRole")))){
            response.sendRedirect(request.getContextPath()+"/classes"); return;
        }

        try {
            String classIdParam = request.getParameter("classId");
            if (classIdParam == null || classIdParam.trim().isEmpty()) {
                classIdParam = request.getParameter("id");
            }
            int classId = Integer.parseInt(classIdParam.trim());
            int studentId = ((Number) session.getAttribute("userId")).intValue();
            EnrollmentService.RequestResult result=enrollmentService.requestEnrollment(classId,studentId);
            if(result.error()!=null){
                session.setAttribute("flashError",result.error());
                response.sendRedirect(request.getContextPath()+"/enroll?classId="+classId);
                return;
            }
            response.sendRedirect(request.getContextPath()+"/student/payment?enrollmentId="+result.enrollmentId());
        } catch(NumberFormatException e){
            response.sendRedirect(request.getContextPath()+"/classes");
        } catch(SQLException e){
            e.printStackTrace();
            response.sendRedirect(request.getContextPath()+"/classes");
        }
    }
}
