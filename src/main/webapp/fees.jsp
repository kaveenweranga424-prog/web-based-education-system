<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Invoice,model.Payment,model.User,java.util.List" %>
<%!
    private String h(Object v) {
        if (v == null) return "";
        return String.valueOf(v).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    String cp = request.getContextPath();
    List<Invoice> invoices = (List<Invoice>) request.getAttribute("invoices");
    List<Payment> payments = (List<Payment>) request.getAttribute("payments");
    List<Integer> childIds = (List<Integer>) request.getAttribute("childIds");
    List<User> linkedChildren = (List<User>) request.getAttribute("linkedChildren");
    Integer selected = (Integer) request.getAttribute("selectedStudentId");
    String role = String.valueOf(session.getAttribute("userRole"));
    String err = request.getAttribute("errorMessage") == null ? "" : String.valueOf(request.getAttribute("errorMessage"));
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fees &amp; Payments | Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= cp %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= cp %>/css/class-pages.css">
    <style>
        .fee-shell { max-width: 1200px; margin: 32px auto; padding: 0 20px; }
        .fee-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .card-panel { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; padding: 24px; box-shadow: 0 2px 8px rgba(0,0,0,.04); margin-bottom: 28px; }
        .panel-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 18px; }
        .panel-head h2 { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 18px; font-weight: 700; color: #171717; margin: 0; }
        .table-wrap { overflow-x: auto; }
        .data-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13.5px; }
        .data-table th { background: #f9fafb; padding: 13px 15px; border-bottom: 1px solid #e5e7eb; color: #4b5563; font-weight: 600; }
        .data-table td { padding: 13px 15px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
        .badge-status { padding: 4px 10px; border-radius: 9999px; font-size: 11.5px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; display: inline-block; }
        .badge-paid { background: #dcfce7; color: #15803d; }
        .badge-unpaid { background: #fee2e2; color: #b91c1c; }
        .badge-partial { background: #fef3c7; color: #b45309; }
        .badge-pending { background: #dbeafe; color: #1d4ed8; }
        .badge-neutral { background: #f3f4f6; color: #6b7280; }
        .select-child { padding: 8px 14px; border: 1px solid #d4d4d4; border-radius: 8px; font-size: 13.5px; font-family: inherit; font-weight: 600; color: #374151; }
        .alert-error { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        .receipt-pill { display: inline-flex; align-items: center; gap: 6px; color: #2563eb; font-weight: 600; text-decoration: none; font-size: 13px; }
        .receipt-pill:hover { text-decoration: underline; }
    </style>
</head>
<body class="dash-body">

<header class="class-page-header">
    <a class="class-brand" href="<%= cp %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle">Fee Invoices &amp; Payments</span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= cp %>/dashboard"><i class="fa-solid fa-arrow-left"></i> Dashboard</a>
    </div>
</header>

<main class="fee-shell">
    <div class="fee-header">
        <div>
            <h1 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:24px;font-weight:700;margin:0;">Fee Invoices &amp; Payment Ledger</h1>
            <p style="font-size:14px;color:#737373;margin-top:4px;margin-bottom:0;">View outstanding tuition invoices, billing history, and payment receipts.</p>
        </div>

        <% if ("PARENT".equalsIgnoreCase(role) && childIds != null && !childIds.isEmpty()) { %>
        <div>
            <form method="get" action="<%= cp %>/fees" style="display:flex;align-items:center;gap:8px;">
                <label for="studentId" style="font-size:13px;font-weight:600;color:#4b5563;"><i class="fa-solid fa-child"></i> Student:</label>
                <select class="select-child" id="studentId" name="studentId" onchange="this.form.submit()">
                    <% if (linkedChildren != null) { 
                        for (User child : linkedChildren) { 
                            Integer id = child.getUserId(); %>
                    <option value="<%= id %>" <%= id.equals(selected) ? "selected" : "" %>>
                        <%= h(child.getFullName()) %> (#<%= id %>)
                    </option>
                    <% } } %>
                </select>
            </form>
        </div>
        <% } %>
    </div>

    <% if (!err.isEmpty()) { %>
        <div class="alert-error">
            <i class="fa-solid fa-circle-exclamation"></i>
            <span><%= h(err) %></span>
        </div>
    <% } %>

    <!-- Invoices Panel -->
    <div class="card-panel">
        <div class="panel-head">
            <h2><i class="fa-solid fa-file-invoice-dollar" style="color:#7c3aed;"></i> Fee Invoices</h2>
            <span style="font-size:13px;color:#737373;"><%= invoices != null ? invoices.size() : 0 %> records</span>
        </div>

        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Invoice #</th>
                        <th>Class / Batch</th>
                        <th>Billed Amount</th>
                        <th>Paid</th>
                        <th>Balance Due</th>
                        <th>Due Date</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (invoices != null && !invoices.isEmpty()) {
                        for (Invoice i : invoices) {
                            String st = i.getStatus() != null ? i.getStatus().toUpperCase() : "UNKNOWN";
                            String bClass = "badge-unpaid";
                            if ("PAID".equals(st)) bClass = "badge-paid";
                            else if ("PARTIAL".equals(st)) bClass = "badge-partial";
                            else if ("CANCELLED".equals(st)) bClass = "badge-neutral";
                    %>
                    <tr>
                        <td style="font-weight:700;">#INV-<%= i.getInvoiceId() %></td>
                        <td><%= h(i.getSubject()) %> <span style="font-size:12px;color:#6b7280;">(<%= h(i.getBatch()) %>)</span></td>
                        <td>Rs. <%= i.getAmount() != null ? i.getAmount().toPlainString() : "0.00" %></td>
                        <td style="color:#15803d;font-weight:600;">Rs. <%= i.getAmountPaid() != null ? i.getAmountPaid().toPlainString() : "0.00" %></td>
                        <td style="color:#b91c1c;font-weight:600;">Rs. <%= i.getBalance() != null ? i.getBalance().toPlainString() : "0.00" %></td>
                        <td><%= i.getDueDate() != null ? i.getDueDate() : "-" %></td>
                        <td><span class="badge-status <%= bClass %>"><%= st %></span></td>
                    </tr>
                    <% } } else { %>
                    <tr>
                        <td colspan="7" style="text-align:center;padding:32px;color:#6b7280;">
                            <i class="fa-solid fa-inbox" style="font-size:24px;margin-bottom:8px;display:block;"></i>
                            No fee invoices found.
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Payment History Panel -->
    <div class="card-panel">
        <div class="panel-head">
            <h2><i class="fa-solid fa-receipt" style="color:#7c3aed;"></i> Payment History &amp; Receipts</h2>
            <span style="font-size:13px;color:#737373;"><%= payments != null ? payments.size() : 0 %> payments</span>
        </div>

        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Receipt #</th>
                        <th>Class</th>
                        <th>Amount Paid</th>
                        <th>Method</th>
                        <th>Bank / Details</th>
                        <th>Reference</th>
                        <th>Approval</th>
                        <th>Payment Date</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (payments != null && !payments.isEmpty()) {
                        for (Payment p : payments) {
                            String receiptRoute = "PARENT".equalsIgnoreCase(role) ? "/parent/receipt" : "/student/receipt";
                    %>
                    <tr>
                        <td>
                            <a class="receipt-pill" href="<%= cp + receiptRoute %>?paymentId=<%= p.getPaymentId() %>">
                                <i class="fa-solid fa-arrow-up-right-from-square"></i>
                                <%= h(p.getReceiptNo()) %>
                            </a>
                        </td>
                        <td><%= h(p.getSubject()) %> <span style="font-size:12px;color:#6b7280;">(<%= h(p.getBatch()) %>)</span></td>
                        <td style="font-weight:700;color:#15803d;">Rs. <%= p.getAmountPaid() != null ? p.getAmountPaid().toPlainString() : "0.00" %></td>
                        <td><span style="font-weight:600;color:#4b5563;"><%= h(p.getPaymentMethod()) %></span></td>
                        <td>
                            <% if(p.getSlipPath() != null && !p.getSlipPath().isBlank()){ %>
                                <a href="<%=cp%>/<%=h(p.getSlipPath())%>" target="_blank" style="color:#2563eb;text-decoration:none;font-weight:600;font-size:12px;"><i class="fa-solid fa-file-invoice"></i> View Slip</a>
                            <% } else if(p.getMaskedCardNo() != null && !p.getMaskedCardNo().isBlank()){ %>
                                <span style="font-family:monospace;font-size:12.5px;"><%= h(p.getMaskedCardNo()) %></span>
                            <% } else { %>
                                <span style="color:#94a3b8;font-size:12px;">Bank Transfer</span>
                            <% } %>
                        </td>
                        <td style="font-size:12px;color:#6b7280;"><%= h(p.getGatewayOrderId()) %></td>
                        <td>
                            <span class="badge-status badge-paid"><%= h(p.getAdminStatus() != null ? p.getAdminStatus() : "APPROVED") %></span>
                        </td>
                        <td><%= p.getPaymentDate() %></td>
                    </tr>
                    <% } } else { %>
                    <tr>
                        <td colspan="8" style="text-align:center;padding:32px;color:#6b7280;">
                            <i class="fa-solid fa-wallet" style="font-size:24px;margin-bottom:8px;display:block;"></i>
                            No payment transactions recorded yet.
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>
</main>

</body>
</html>
