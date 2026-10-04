<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Class" %>
<%@ page import="model.Enrollment" %>
<%@ page import="model.Invoice" %>
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
    List<Invoice> invoices = (List<Invoice>) request.getAttribute("invoices");
    List<Class> classes = (List<Class>) request.getAttribute("classes");
    List<Enrollment> enrollments = (List<Enrollment>) request.getAttribute("enrollments");
    Integer selectedClassId = (Integer) request.getAttribute("selectedClassId");

    String selectedFee = "";
    if (classes != null && selectedClassId != null) {
        for (Class c : classes) {
            if (c.getClassId() == selectedClassId && c.getFee() != null) {
                selectedFee = c.getFee().toPlainString();
                break;
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Invoices | Classora Accounts</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/class-pages.css">
    <style>
        .inv-shell { max-width: 1200px; margin: 32px auto; padding: 0 20px; }
        .inv-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .card-panel { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; padding: 24px; box-shadow: 0 2px 8px rgba(0,0,0,.04); margin-bottom: 28px; }
        .panel-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 18px; }
        .panel-head h2 { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 18px; font-weight: 700; color: #171717; margin: 0; }
        .table-wrap { overflow-x: auto; }
        .data-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13.5px; }
        .data-table th { background: #f9fafb; padding: 13px 15px; border-bottom: 1px solid #e5e7eb; color: #4b5563; font-weight: 600; }
        .data-table td { padding: 13px 15px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
        .form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; align-items: flex-end; margin-top: 12px; }
        .form-group { display: flex; flex-direction: column; gap: 6px; }
        .form-group label { font-size: 13px; font-weight: 600; color: #374151; }
        .form-control { padding: 9px 12px; border: 1px solid #d4d4d4; border-radius: 8px; font-size: 13.5px; font-family: inherit; width: 100%; box-sizing: border-box; }
        .form-control:focus { border-color: #7c3aed; outline: none; box-shadow: 0 0 0 3px rgba(124, 58, 237, 0.1); }
        .btn-action { background: #7c3aed; color: #fff; border: none; padding: 10px 18px; border-radius: 8px; font-weight: 600; font-size: 13.5px; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; gap: 8px; }
        .btn-action:hover { background: #6d28d9; }
        .btn-cancel-inv { background: #fee2e2; color: #dc2626; border: none; padding: 6px 12px; border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 4px; }
        .btn-cancel-inv:hover { background: #fca5a5; }
        .badge-status { padding: 4px 10px; border-radius: 9999px; font-size: 11.5px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; display: inline-block; }
        .badge-paid { background: #dcfce7; color: #15803d; }
        .badge-unpaid { background: #fee2e2; color: #b91c1c; }
        .badge-partial { background: #fef3c7; color: #b45309; }
        .badge-cancelled { background: #f3f4f6; color: #6b7280; }
        .alert-error { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        .step-tag { display: inline-block; background: #ede9fe; color: #6d28d9; font-weight: 700; font-size: 12px; padding: 2px 8px; border-radius: 6px; margin-bottom: 8px; }
    </style>
</head>
<body class="dash-body">

<header class="class-page-header">
    <a class="class-brand" href="<%= contextPath %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle">Accounts &amp; Invoicing</span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= contextPath %>/staff/payments"><i class="fa-solid fa-cash-register"></i> Payment Desk</a>
        <a class="class-nav-link" href="<%= contextPath %>/dashboard"><i class="fa-solid fa-arrow-left"></i> Admin Dashboard</a>
    </div>
</header>

<main class="inv-shell">
    <div class="inv-header">
        <div>
            <h1 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:24px;font-weight:700;margin:0;">Fee Invoice Management</h1>
            <p style="font-size:14px;color:#737373;margin-top:4px;margin-bottom:0;">Generate monthly and term fee invoices for enrolled students, track status, and cancel erroneous bills.</p>
        </div>
        <div style="display:flex;gap:10px;">
            <a href="<%= contextPath %>/staff/payments" class="btn-action" style="text-decoration:none;background:#16a34a;"><i class="fa-solid fa-money-bill-wave"></i> Collect Payments</a>
        </div>
    </div>

    <% if (!errorMessage.isEmpty()) { %>
        <div class="alert-error">
            <i class="fa-solid fa-circle-exclamation"></i>
            <span><%= h(errorMessage) %></span>
        </div>
    <% } %>

    <!-- Invoice Generation Panel -->
    <div class="card-panel">
        <div class="panel-head">
            <h2><i class="fa-solid fa-file-circle-plus" style="color:#7c3aed;"></i> Generate Student Invoice</h2>
        </div>

        <div>
            <span class="step-tag">Step 1: Choose Class</span>
            <form action="<%= contextPath %>/staff/invoices" method="get" style="margin-bottom: 20px;">
                <div style="display:flex; gap:12px; max-width: 500px;">
                    <select name="classId" class="form-control" onchange="this.form.submit()" required>
                        <option value="">-- Select Class to Load Students --</option>
                        <% if (classes != null) { for (Class c : classes) { %>
                        <option value="<%= c.getClassId() %>"
                                <%= selectedClassId != null && selectedClassId == c.getClassId() ? "selected" : "" %>>
                            <%= h(c.getSubject()) %> - <%= h(c.getBatch()) %> (Fee: Rs. <%= c.getFee() != null ? c.getFee() : "0.00" %>)
                        </option>
                        <% } } %>
                    </select>
                    <noscript>
                        <button type="submit" class="btn-action">Filter</button>
                    </noscript>
                </div>
            </form>
        </div>

        <% if (selectedClassId != null) { %>
            <div>
                <span class="step-tag">Step 2: Assign Invoice Details</span>
                <% if (enrollments != null && !enrollments.isEmpty()) { %>
                    <form action="<%= contextPath %>/staff/invoices" method="post">
                        <input type="hidden" name="action" value="create">
                        <div class="form-grid">
                            <div class="form-group" style="grid-column: span 2;">
                                <label for="enrollmentId"><i class="fa-solid fa-user-graduate"></i> Enrolled Student</label>
                                <select name="enrollmentId" id="enrollmentId" class="form-control" required>
                                    <option value="">-- Select Student --</option>
                                    <% for (Enrollment e : enrollments) { %>
                                    <option value="<%= e.getEnrollmentId() %>">
                                        <%= h(e.getStudentName()) %> (Enrollment #<%= e.getEnrollmentId() %> - Status: <%= h(e.getStatus()) %>)
                                    </option>
                                    <% } %>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="amount"><i class="fa-solid fa-tag"></i> Billing Amount (Rs.)</label>
                                <input type="number" step="0.01" min="0.01" name="amount" id="amount" class="form-control"
                                       value="<%= h(selectedFee) %>" placeholder="0.00" required>
                            </div>

                            <div class="form-group">
                                <label for="dueDate"><i class="fa-regular fa-calendar-days"></i> Due Date</label>
                                <input type="date" name="dueDate" id="dueDate" class="form-control" required>
                            </div>

                            <div class="form-group">
                                <button type="submit" class="btn-action" style="width: 100%;">
                                    <i class="fa-solid fa-check"></i> Issue Invoice
                                </button>
                            </div>
                        </div>
                    </form>
                <% } else { %>
                    <div style="padding: 16px; background: #fefce8; border: 1px solid #fef08a; border-radius: 8px; color: #854d0e; font-size: 13.5px;">
                        <i class="fa-solid fa-triangle-exclamation"></i> No active student enrollments found for this selected class.
                    </div>
                <% } %>
            </div>
        <% } %>
    </div>

    <!-- All Invoices Table -->
    <div class="card-panel">
        <div class="panel-head">
            <h2><i class="fa-solid fa-list-check" style="color:#7c3aed;"></i> All Fee Invoices</h2>
            <span style="font-size:13px;color:#737373;"><%= invoices != null ? invoices.size() : 0 %> total records</span>
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
                        <th>Balance</th>
                        <th>Due Date</th>
                        <th>Status</th>
                        <th style="text-align:right;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (invoices != null && !invoices.isEmpty()) { 
                        for (Invoice inv : invoices) { 
                            String status = inv.getStatus() != null ? inv.getStatus().toUpperCase() : "UNKNOWN";
                            String badgeClass = "badge-unpaid";
                            if ("PAID".equals(status)) {
                                badgeClass = "badge-paid";
                            } else if ("PARTIAL".equals(status)) {
                                badgeClass = "badge-partial";
                            } else if ("CANCELLED".equals(status)) {
                                badgeClass = "badge-cancelled";
                            }
                    %>
                    <tr>
                        <td style="font-weight:700;color:#374151;">#INV-<%= inv.getInvoiceId() %></td>
                        <td style="font-weight:600;"><%= h(inv.getStudentName()) %></td>
                        <td><%= h(inv.getSubject()) %> <span style="font-size:12px;color:#6b7280;">(<%= h(inv.getBatch()) %>)</span></td>
                        <td>Rs. <%= inv.getAmount() != null ? inv.getAmount().toPlainString() : "0.00" %></td>
                        <td style="color:#15803d;font-weight:600;">Rs. <%= inv.getAmountPaid() != null ? inv.getAmountPaid().toPlainString() : "0.00" %></td>
                        <td style="color:#b91c1c;font-weight:600;">Rs. <%= inv.getBalance() != null ? inv.getBalance().toPlainString() : "0.00" %></td>
                        <td><%= inv.getDueDate() != null ? inv.getDueDate() : "-" %></td>
                        <td><span class="badge-status <%= badgeClass %>"><%= status %></span></td>
                        <td style="text-align:right;">
                            <% if (!"PAID".equals(status) && !"CANCELLED".equals(status)) { %>
                            <form style="display:inline" action="<%= contextPath %>/staff/invoices" method="post"
                                  onsubmit="return confirm('Are you sure you want to cancel invoice #INV-<%= inv.getInvoiceId() %>?');">
                                <input type="hidden" name="action" value="cancel">
                                <input type="hidden" name="invoiceId" value="<%= inv.getInvoiceId() %>">
                                <button type="submit" class="btn-cancel-inv">
                                    <i class="fa-solid fa-ban"></i> Cancel
                                </button>
                            </form>
                            <% } else { %>
                            <span style="font-size:12px;color:#9ca3af;">-</span>
                            <% } %>
                        </td>
                    </tr>
                    <%  } 
                    } else { %>
                    <tr>
                        <td colspan="9" style="text-align:center;padding:32px;color:#6b7280;">
                            <i class="fa-solid fa-inbox" style="font-size:24px;margin-bottom:8px;display:block;"></i>
                            No fee invoices found in the system.
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