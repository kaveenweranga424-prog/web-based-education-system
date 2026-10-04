package servlet;

import dao.ClassDAO;
import model.Class;
import service.ClassMaterialService;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.*;
import java.sql.SQLException;
import java.util.List;
import java.util.UUID;

@WebServlet("/tutor/materials")
@MultipartConfig(maxFileSize = 20 * 1024 * 1024)
public class ClassMaterialServlet extends HttpServlet {
    private ClassMaterialService materialService;
    private ClassDAO classDAO;

    private static String getMaterialsDir() {
        String v=System.getProperty("MATERIALS_DIR");
        if(v==null||v.isBlank())v=System.getenv("MATERIALS_DIR");
        if(v==null||v.isBlank())v=System.getProperty("java.io.tmpdir")+File.separator+"classora-materials";
        return v;
    }

    @Override public void init(){materialService=new ClassMaterialService();classDAO=new ClassDAO();}

    @Override protected void doGet(HttpServletRequest request,HttpServletResponse response)throws ServletException,IOException{
        HttpSession session=requireTutor(request,response);if(session==null)return;
        int tutorId=((Number)session.getAttribute("userId")).intValue();
        try{
            List<Class> assigned=classDAO.findByTutor(tutorId);request.setAttribute("assignedClasses",assigned);
            String value=request.getParameter("classId");
            if(value==null||value.isBlank()){request.getRequestDispatcher("/tutor/manage-materials.jsp").forward(request,response);return;}
            int classId=Integer.parseInt(value);Class selected=classDAO.findById(classId);
            if(!isAssigned(selected,tutorId)){response.sendError(403);return;}
            putData(request,selected,assigned);request.getRequestDispatcher("/tutor/manage-materials.jsp").forward(request,response);
        }catch(NumberFormatException e){response.sendError(400);}
        catch(SQLException e){e.printStackTrace();request.setAttribute("errorMessage","Database error occurred.");request.getRequestDispatcher("/tutor/manage-materials.jsp").forward(request,response);}
    }

    @Override protected void doPost(HttpServletRequest request,HttpServletResponse response)throws ServletException,IOException{
        HttpSession session=requireTutor(request,response);if(session==null)return;
        int tutorId=((Number)session.getAttribute("userId")).intValue();request.setCharacterEncoding("UTF-8");
        int classId;
        try{classId=Integer.parseInt(request.getParameter("classId"));}catch(Exception e){response.sendError(400);return;}
        Path newlyWritten=null;
        try{
            Class selected=classDAO.findById(classId);
            if(!isAssigned(selected,tutorId)){response.sendError(403);return;}
            String action=request.getParameter("action");

            if("delete".equals(action)){
                int materialId=Integer.parseInt(request.getParameter("materialId"));
                service.ClassMaterialService.MaterialMutationResult result=materialService.deleteMaterial(materialId,classId);
                if(result.error()!=null){forwardError(request,response,tutorId,selected,result.error());return;}
                deleteManagedFile(result.oldManagedFilePath());
                response.sendRedirect(request.getContextPath()+"/tutor/materials?classId="+classId);return;
            }

            if("update".equals(action)){
                int materialId=Integer.parseInt(request.getParameter("materialId"));
                Part replacement=request.getPart("file");
                String replacementPath=null;
                if(replacement!=null&&replacement.getSize()>0){
                    newlyWritten=store(replacement);replacementPath=newlyWritten.toString();
                }
                ClassMaterialService.MaterialMutationResult result=materialService.updateMaterial(
                        materialId,classId,request.getParameter("title"),request.getParameter("description"),replacementPath);
                if(result.error()!=null){
                    if(newlyWritten!=null)Files.deleteIfExists(newlyWritten);
                    forwardError(request,response,tutorId,selected,result.error());return;
                }
                deleteManagedFile(result.oldManagedFilePath());
                response.sendRedirect(request.getContextPath()+"/tutor/materials?classId="+classId);return;
            }

            Part filePart=request.getPart("file");
            if(filePart!=null&&filePart.getSize()>0)newlyWritten=store(filePart);
            String error=materialService.addMaterial(classId,request.getParameter("title"),request.getParameter("description"),newlyWritten==null?null:newlyWritten.toString());
            if(error!=null){
                if(newlyWritten!=null)Files.deleteIfExists(newlyWritten);
                forwardError(request,response,tutorId,selected,error);return;
            }
            response.sendRedirect(request.getContextPath()+"/tutor/materials?classId="+classId);
        }catch(NumberFormatException e){if(newlyWritten!=null)Files.deleteIfExists(newlyWritten);response.sendError(400);}
        catch(SQLException e){if(newlyWritten!=null)Files.deleteIfExists(newlyWritten);e.printStackTrace();response.sendRedirect(request.getContextPath()+"/tutor/materials?classId="+classId);}
    }

    private Path store(Part part)throws IOException{
        Path dir=Path.of(getMaterialsDir()).toAbsolutePath().normalize();Files.createDirectories(dir);
        String name=sanitize(extractFileName(part));Path dest=dir.resolve(UUID.randomUUID()+"_"+name).normalize();
        if(!dest.startsWith(dir))throw new IOException("Invalid file name.");
        try(InputStream in=part.getInputStream()){Files.copy(in,dest,StandardCopyOption.REPLACE_EXISTING);}
        return dest;
    }

    private void deleteManagedFile(String stored)throws IOException{
        if(stored==null||stored.isBlank())return;
        Path dir=Path.of(getMaterialsDir()).toAbsolutePath().normalize();
        Path target=Path.of(stored).toAbsolutePath().normalize();
        if(target.startsWith(dir))Files.deleteIfExists(target);
    }

    private void putData(HttpServletRequest request,Class selected,List<Class> assigned)throws SQLException{
        request.setAttribute("assignedClasses",assigned);request.setAttribute("classId",selected.getClassId());
        request.setAttribute("selectedClass",selected);request.setAttribute("materials",materialService.findByClass(selected.getClassId()));
    }

    private void forwardError(HttpServletRequest request,HttpServletResponse response,int tutorId,Class selected,String error)throws SQLException,ServletException,IOException{
        request.setAttribute("errorMessage",error);putData(request,selected,classDAO.findByTutor(tutorId));
        request.getRequestDispatcher("/tutor/manage-materials.jsp").forward(request,response);
    }

    private HttpSession requireTutor(HttpServletRequest request,HttpServletResponse response)throws IOException{
        HttpSession session=request.getSession(false);
        if(session==null||session.getAttribute("userId")==null){response.sendRedirect(request.getContextPath()+"/login");return null;}
        if(!"TUTOR".equalsIgnoreCase(String.valueOf(session.getAttribute("userRole")))){response.sendError(403);return null;}
        return session;
    }
    private boolean isAssigned(Class c,int tutorId){return c!=null&&c.getTutorId()!=null&&c.getTutorId()==tutorId;}
    private String sanitize(String s){if(s==null||s.isBlank())return "file_"+System.currentTimeMillis();return Path.of(s).getFileName().toString();}
    private String extractFileName(Part part){
        String cd=part.getHeader("content-disposition");if(cd!=null)for(String token:cd.split(";"))if(token.trim().startsWith("filename"))return token.substring(token.indexOf('=')+1).trim().replace("\"","");
        return "file_"+System.currentTimeMillis();
    }
}
