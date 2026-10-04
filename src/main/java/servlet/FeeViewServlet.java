package servlet;

import dao.ParentStudentDAO;
import dao.UserDAO;
import model.User;
import model.Invoice;
import model.Payment;
import service.FeeService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet("/fees")
public class FeeViewServlet extends HttpServlet {
    private FeeService feeService; private ParentStudentDAO parentStudentDAO; private UserDAO userDAO;
    @Override public void init(){feeService=new FeeService();parentStudentDAO=new ParentStudentDAO();userDAO=new UserDAO();}
    @Override protected void doGet(HttpServletRequest request,HttpServletResponse response)throws ServletException,IOException{
        HttpSession session=request.getSession(false);
        if(session==null||session.getAttribute("userId")==null){response.sendRedirect(request.getContextPath()+"/login");return;}
        String role=String.valueOf(session.getAttribute("userRole"));int userId=((Number)session.getAttribute("userId")).intValue();
        try{
            int studentId;
            if("STUDENT".equalsIgnoreCase(role)){studentId=userId;}
            else if("PARENT".equalsIgnoreCase(role)){
                List<Integer> childIds=parentStudentDAO.findActiveStudentIdsForParent(userId);
                request.setAttribute("childIds",childIds);
                java.util.List<User> linkedChildren = new java.util.ArrayList<>();
                for (Integer childId : childIds) {
                    User child = userDAO.findById(childId);
                    if (child != null) linkedChildren.add(child);
                }
                request.setAttribute("linkedChildren", linkedChildren);
                if(childIds.isEmpty()){request.getRequestDispatcher("/fees.jsp").forward(request,response);return;}
                String requested=request.getParameter("studentId");
                if(requested==null||requested.isBlank())studentId=childIds.get(0);
                else{
                    try{studentId=Integer.parseInt(requested);}catch(NumberFormatException e){response.sendError(400);return;}
                    if(!childIds.contains(studentId)){response.sendError(403);return;}
                }
                request.setAttribute("selectedStudentId",studentId);
            }else{response.sendError(403);return;}
            List<Invoice> invoices=feeService.findInvoicesByStudent(studentId);
            List<Payment> payments=feeService.findPaymentsByStudent(studentId);
            request.setAttribute("invoices",invoices);request.setAttribute("payments",payments);
            request.getRequestDispatcher("/fees.jsp").forward(request,response);
        }catch(SQLException e){e.printStackTrace();request.setAttribute("errorMessage","Database error occurred.");request.getRequestDispatcher("/fees.jsp").forward(request,response);}
    }
}
