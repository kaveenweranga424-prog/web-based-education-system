<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %><%@ page import="model.Payment" %>
<%!
private String h(Object v){if(v==null)return "";return String.valueOf(v).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");}
%>
<%
String cp=request.getContextPath(); List<Payment> payments=(List<Payment>)request.getAttribute("payments");
Object err=session.getAttribute("workflowError"); if(err!=null)session.removeAttribute("workflowError");
%>
<!doctype html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Payment Approvals | Classora</title>
<link rel="stylesheet" href="<%=cp%>/css/dashboard.css"><style>body{font-family:Inter,Arial;background:#f6f7fb;padding:28px;color:#23273a}.page{max-width:1200px;margin:auto}.head{display:flex;justify-content:space-between;gap:20px;align-items:center;margin-bottom:22px}.head p{color:#73798e}.panel{background:#fff;border-radius:16px;box-shadow:0 8px 30px #20284012;overflow:auto}table{width:100%;border-collapse:collapse;min-width:950px}th,td{padding:13px;border-bottom:1px solid #eee;text-align:left;font-size:14px}th{background:#fafaff;color:#666d83}.ok{background:#147a55;color:white;border:0;padding:9px 13px;border-radius:8px;font-weight:700;cursor:pointer}.bad{background:#b83b3b;color:white;border:0;padding:9px 13px;border-radius:8px;font-weight:700;cursor:pointer}input{padding:9px;border:1px solid #d9ddea;border-radius:8px}.actions{display:flex;gap:8px;align-items:center;flex-wrap:wrap}.masked{font-family:monospace}.error{padding:12px 14px;background:#fff1f1;color:#a52c2c;border-radius:10px;margin-bottom:14px}</style></head>
<body><div class="page"><div class="head"><div><h1>Payment Approvals</h1><p>Review submitted card payments. Approving sends the request to Admin; cancelling rejects the enrollment request.</p></div><a href="<%=cp%>/dashboard">Back to Dashboard</a></div>
<% if(err!=null){%><div class="error"><%=h(err)%></div><%}%>
<div class="panel"><table><tr><th>Student</th><th>Class</th><th>Amount</th><th>Card Holder</th><th>Card</th><th>Reference</th><th>Submitted</th><th>Action</th></tr>
<% if(payments!=null&&!payments.isEmpty()){for(Payment p:payments){%>
<tr><td><%=h(p.getStudentName())%></td><td><%=h(p.getSubject())%> - <%=h(p.getBatch())%></td><td>LKR <%=h(p.getAmountPaid())%></td><td><%=h(p.getCardHolderName())%></td><td class="masked"><%=h(p.getMaskedCardNo())%></td><td><%=h(p.getGatewayOrderId())%></td><td><%=h(p.getPaymentDate())%></td>
<td><div class="actions"><form method="post"><input type="hidden" name="paymentId" value="<%=p.getPaymentId()%>"><input type="hidden" name="action" value="confirm"><button class="ok">Approve Payment</button></form>
<form method="post"><input type="hidden" name="paymentId" value="<%=p.getPaymentId()%>"><input type="hidden" name="action" value="cancel"><input name="reason" placeholder="Cancellation reason" required maxlength="500"><button class="bad">Cancel Payment</button></form></div></td></tr>
<%}}else{%><tr><td colspan="8">No payments waiting for Staff confirmation.</td></tr><%}%>
</table></div></div></body></html>
