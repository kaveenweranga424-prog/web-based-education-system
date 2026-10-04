<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Payment" %>

<%
    String contextPath = request.getContextPath();
    Payment payment = (Payment) request.getAttribute("payment");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Receipt <%= payment != null ? payment.getReceiptNo() : "" %> | Classora</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 40px auto; }
        .receipt-box { border: 2px solid #333; padding: 24px; }
        .receipt-row { display: flex; justify-content: space-between; margin: 8px 0; }
        h1 { text-align: center; }
        @media print {
            .no-print { display: none; }
        }
    </style>
</head>
<body>

<% if (payment != null) { %>
<div class="receipt-box">
    <h1>Payment Receipt</h1>
    <div class="receipt-row"><strong>Receipt No.:</strong> <span><%= payment.getReceiptNo() %></span></div>
    <div class="receipt-row"><strong>Date:</strong> <span><%= payment.getPaymentDate() %></span></div>
    <div class="receipt-row"><strong>Student:</strong> <span><%= payment.getStudentName() %></span></div>
    <div class="receipt-row"><strong>Class:</strong> <span><%= payment.getSubject() %> - <%= payment.getBatch() %></span></div>
    <div class="receipt-row"><strong>Amount Paid:</strong> <span><%= payment.getAmountPaid() %></span></div>
    <div class="receipt-row"><strong>Payment Method:</strong> <span><%= payment.getPaymentMethod() %></span></div>
    <div class="receipt-row"><strong>Received By:</strong> <span><%= payment.getReceivedByName() %></span></div>
</div>

<p class="no-print"><button onclick="window.print()">Print Receipt</button></p>
<% } else { %>
<p>Receipt not found.</p>
<% } %>

</body>
</html>