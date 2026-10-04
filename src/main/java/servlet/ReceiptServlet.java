package servlet;

import model.Payment;
import service.FeeService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet(urlPatterns={"/staff/receipt","/student/receipt","/parent/receipt","/admin/receipt"})
public class ReceiptServlet extends HttpServlet {
    private FeeService feeService;
    @Override public void init(){feeService=new FeeService();}
    @Override protected void doGet(HttpServletRequest request,HttpServletResponse response)throws ServletException,IOException{
        HttpSession session=request.getSession(false);
        if(session==null||session.getAttribute("userId")==null){response.sendRedirect(request.getContextPath()+"/login");return;}
        try{
            int paymentId=Integer.parseInt(request.getParameter("paymentId"));
            Payment p=feeService.findPaymentById(paymentId);
            if(p==null){response.sendError(404);return;}
            int userId=((Number)session.getAttribute("userId")).intValue();
            String role=String.valueOf(session.getAttribute("userRole"));
            boolean allowed=false;
            if("STUDENT".equalsIgnoreCase(role)) allowed=p.getStudentId()==userId;
            else if("PARENT".equalsIgnoreCase(role)) allowed=feeService.parentCanViewStudent(userId,p.getStudentId());
            else if("ADMIN".equalsIgnoreCase(role)) allowed=true;
            if(!allowed){response.sendError(403);return;}
            request.setAttribute("payment",p);
            request.getRequestDispatcher("/receipt.jsp").forward(request,response);
        }catch(NumberFormatException e){response.sendError(400);}
        catch(SQLException e){e.printStackTrace();response.sendError(500);}
    }
}
