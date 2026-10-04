<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Invoice" %>
<%@ page import="model.Payment" %>
<%@ page import="java.util.List" %>
<%!
    private String h(Object val) {
        if (val == null) return "";
        return String.valueOf(val).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    String contextPath = request.getContextPath();
    String errorMessage = request.getAttribute("errorMessage") != null ? request.getAttribute("errorMessage").toString() : "";
    List<Invoice> outstanding = (List<Invoice>) request.getAttribute("outstanding");
    List<Payment> recentPayments = (List<Payment>) request.getAttribute("recentPayments");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Record Payment | Classora Accounts</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/class-pages.css">
    <style>
        .pay-shell { max-width: 1200px; margin: 32px auto; padding: 0 20px; }
        .pay-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .card-panel { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; padding: 24px; box-shadow: 0 2px 8px rgba(0,0,0,.04); margin-bottom: 28px; }
        .panel-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 18px; }
        .panel-head h2 { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 18px; font-weight: 700; color: #171717; }
        .table-wrap { overflow-x: auto; }
        .data-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13.5px; }
        .data-table th { background: #f9fafb; padding: 13px 15px; border-bottom: 1px solid #e5e7eb; color: #4b5563; font-weight: 600; }
        .data-table td { padding: 13px 15px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
        .inline-pay-form { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .pay-input { width: 110px; padding: 7px 10px; border: 1px solid #d4d4d4; border-radius: 8px; font-size: 13px; font-family: inherit; }
        .pay-select { padding: 7px 10px; border: 1px solid #d4d4d4; border-radius: 8px; font-size: 13px; font-family: inherit; }
        .btn-record { background: #16a34a; color: #fff; padding: 7px 14px; border: none; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; }
        .btn-record:hover { background: #15803d; }
        .btn-void { background: #fee2e2; color: #dc2626; border: none; padding: 6px 10px; border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; }
        .btn-void:hover { background: #fca5a5; }
        .alert-error { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        .receipt-link { display: inline-flex; align-items: center; gap: 6px; color: #2563eb; font-weight: 600; text-decoration: none; font-size: 13px; }
        .receipt-link:hover { text-decoration: underline; }
    </style>
</head>
<body class="dash-body">

<header class="class-page-header">
    <a class="class-brand" href="<%= contextPath %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle">Accounts &amp; Payment Desk</span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= contextPath %>/dashboard"><i class="fa-solid fa-arrow-left"></i> Admin Dashboard</a>
    </div>
</header>

<main class="pay-shell">
    <div class="pay-header">
        <div>
            <h1 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:24px;font-weight:700;">Record Student Payments</h1>
            <p style="font-size:14px;color:#737373;margin-top:4px;">Accept cash, bank transfer, and card payments against active fee invoices.</p>
        </div>
        <div>
            <a href="<%= contextPath %>/staff/invoices" class="btn-solid sm" style="text-decoration:none;"><i class="fa-solid fa-file-invoice"></i> Manage Invoices</a>
        </div>
    </div>

    <% if (!errorMessage.isEmpty()) { %>
        <div class="alert-error">
            <i class="fa-solid fa-circle-exclamation"></i>
            <span><%= h(errorMessage) %></span>
        </div>
    <% } %>

    <div class="card-panel">
        <div class="panel-head">
            <h2><i class="fa-solid fa-receipt"></i> Outstanding Invoices Awaiting Payment</h2>
            <span style="font-size:13px;color:#737373;"><%= outstanding != null ? outstanding.size() : 0 %> pending</span>
        </div>

        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Invoice #</th>
                        <th>Student</th>
                        <th>Class / Batch</th>
                        <th>Billed Amount</th>
                        <th>Paid</th>
                        <th>Balance Due</th>
                        <th>Due Date</th>
                        <th>Record Payment Action</th>
                    </tr>
                </thead>
                <tbody>
                <% if (outstanding != null && !outstanding.isEmpty()) { for (Invoice inv : outstanding) { %>
                    <tr>
                        <td style="font-weight:700;color:#7c3aed;">#<%= inv.getInvoiceId() %></td>
                        <td><strong><%= h(inv.getStudentName()) %></strong></td>
                        <td><%= h(inv.getSubject()) %> — <span class="badge badge-neutral"><%= h(inv.getBatch()) %></span></td>
                        <td>Rs. <%= inv.getAmount() %></td>
                        <td>Rs. <%= inv.getAmountPaid() %></td>
                        <td><strong style="color:#d97706;">Rs. <%= inv.getBalance() %></strong></td>
                        <td style="font-size:12.5px;"><%= inv.getDueDate() %></td>
                        <td>
                            <form action="<%= contextPath %>/staff/payments" method="post" class="inline-pay-form">
                                <input type="hidden" name="invoiceId" value="<%= inv.getInvoiceId() %>">
                                <input type="number" step="0.01" name="amountPaid" max="<%= inv.getBalance() %>" value="<%= inv.getBalance() %>" required class="pay-input" placeholder="Amount">
                                <select name="paymentMethod" required class="pay-select">
                                    <option value="CASH">Cash</option>
                                    <option value="BANK_TRANSFER">Bank Transfer</option>
                                    <option value="CARD">Card</option>
                                    <option value="ONLINE">Online</option>
                                    <option value="OTHER">Other</option>
                                </select>
                                <button type="submit" class="btn-record">
                                    <i class="fa-solid fa-check"></i> Record
                                </button>
                            </form>
                        </td>
                    </tr>
                <% } } else { %>
                    <tr>
                        <td colspan="8" style="text-align:center;padding:32px;color:#737373;">
                            <i class="fa-solid fa-circle-check" style="font-size:24px;color:#16a34a;display:block;margin-bottom:8px;"></i>
                            No outstanding invoices. All current student balances are settled!
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>

    <div class="card-panel">
        <div class="panel-head">
            <h2><i class="fa-solid fa-clock-rotate-left"></i> Recent Payment Transactions</h2>
            <span style="font-size:13px;color:#737373;">Latest collected payments</span>
        </div>

        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Receipt No.</th>
                        <th>Student</th>
                        <th>Class</th>
                        <th>Amount Paid</th>
                        <th>Method</th>
                        <th>Date &amp; Time</th>
                        <th>Received By</th>
                        <th>Receipt</th>
                        <th style="text-align:right;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                <% if (recentPayments != null && !recentPayments.isEmpty()) { for (Payment p : recentPayments) { %>
                    <tr>
                        <td style="font-weight:700;color:#171717;"><%= h(p.getReceiptNo() != null ? p.getReceiptNo() : "REC-" + p.getPaymentId()) %></td>
                        <td><%= h(p.getStudentName()) %></td>
                        <td><%= h(p.getSubject()) %> — <%= h(p.getBatch()) %></td>
                        <td><strong style="color:#16a34a;">Rs. <%= p.getAmountPaid() %></strong></td>
                        <td><span class="badge badge-neutral"><%= h(p.getPaymentMethod()) %></span></td>
                        <td style="font-size:12.5px;"><%= p.getPaymentDate() != null ? p.getPaymentDate().toString().substring(0, 16) : "" %></td>
                        <td><%= h(p.getReceivedByName() != null ? p.getReceivedByName() : "System") %></td>
                        <td>
                            <a href="<%= contextPath %>/staff/receipt?paymentId=<%= p.getPaymentId() %>" target="_blank" class="receipt-link">
                                <i class="fa-solid fa-print"></i> View Receipt
                            </a>
                        </td>
                        <td style="text-align:right;">
                            <form action="<%= contextPath %>/staff/payments" method="post" style="display:inline;" onsubmit="return confirm('Void and delete this payment record? This will adjust the student balance.');">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="paymentId" value="<%= p.getPaymentId() %>">
                                <button type="submit" class="btn-void" title="Void / Delete Payment">
                                    <i class="fa-solid fa-trash-can"></i> Delete
                                </button>
                            </form>
                        </td>
                    </tr>
                <% } } else { %>
                    <tr>
                        <td colspan="9" style="text-align:center;padding:24px;color:#737373;">No payment records recorded yet.</td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
</main>

</body>
</html>