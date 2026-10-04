package servlet;

import service.EnrollmentPaymentService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/admin/enrollment-approvals")
public class AdminEnrollmentApprovalServlet extends HttpServlet {
    private EnrollmentPaymentService service;
    @Override public void init(){service=new EnrollmentPaymentService();}
    private HttpSession requireAdmin(HttpServletRequest req,HttpServletResponse res)throws IOException{
        HttpSession s=req.getSession(false);
        if(s==null||s.getAttribute("userId")==null){res.sendRedirect(req.getContextPath()+"/login");return null;}
        if(!"ADMIN".equalsIgnoreCase(String.valueOf(s.getAttribute("userRole")))){res.sendError(403);return null;}
        return s;
    }
    @Override protected void doGet(HttpServletRequest req,HttpServletResponse res)throws ServletException,IOException{
        if(requireAdmin(req,res)==null)return;
        try{req.setAttribute("payments",service.findPendingAdmin());req.getRequestDispatcher("/admin/enrollment-approvals.jsp").forward(req,res);}
        catch(SQLException e){e.printStackTrace();res.sendError(500);}
    }
    @Override protected void doPost(HttpServletRequest req,HttpServletResponse res)throws IOException{
        HttpSession s=requireAdmin(req,res);if(s==null)return;
        try{
            int paymentId=Integer.parseInt(req.getParameter("paymentId"));
            int adminId=((Number)s.getAttribute("userId")).intValue();
            String action=req.getParameter("action");
            String error="reject".equals(action)
                    ?service.rejectByAdmin(paymentId,adminId,req.getParameter("reason"))
                    :service.approveByAdmin(paymentId,adminId);
            if(error!=null)s.setAttribute("workflowError",error);
            res.sendRedirect(req.getContextPath()+"/admin/enrollment-approvals");
        }catch(Exception e){e.printStackTrace();res.sendError(500);}
    }
}
