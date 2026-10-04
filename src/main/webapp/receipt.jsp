<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Payment" %>
<%!
private String h(Object v){if(v==null)return "";return String.valueOf(v).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");}
%>
<%
    String cp = request.getContextPath();
    Payment p = (Payment) request.getAttribute("payment");
    String role = session != null ? (String) session.getAttribute("userRole") : null;
    String dashUrl = cp + "/dashboard";
    String dashLabel = "Go to Student Dashboard";
    if ("PARENT".equalsIgnoreCase(role)) {
        dashUrl = cp + "/dashboard";
        dashLabel = "Go to Parent Dashboard";
    } else if ("ADMIN".equalsIgnoreCase(role)) {
        dashUrl = cp + "/dashboard";
        dashLabel = "Go to Admin Dashboard";
    }
    boolean isNewPayment = request.getParameter("fromPayment") != null || request.getParameter("autoRedirect") != null;
%>
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Payment Receipt <%= p != null && p.getReceiptNo() != null ? ("— " + h(p.getReceiptNo())) : "" %> | Classora</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>
        * { box-sizing: border-box; }
        body {
            font-family: 'Plus Jakarta Sans', 'Inter', Arial, sans-serif;
            background: #f4f5f9;
            padding: 30px 16px;
            color: #24283a;
            margin: 0;
        }
        .receipt {
            max-width: 740px;
            margin: auto;
            background: #ffffff;
            padding: 36px;
            border-radius: 18px;
            box-shadow: 0 12px 40px rgba(32, 40, 64, 0.08);
            border: 1px solid #eef0f5;
        }
        .top-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
            padding-bottom: 16px;
            border-bottom: 1px solid #f0f2f7;
            flex-wrap: wrap;
            gap: 12px;
        }
        .back-link {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            color: #5b43d6;
            font-weight: 700;
            font-size: 13.5px;
            text-decoration: none;
            transition: color 0.15s, transform 0.15s;
        }
        .back-link:hover {
            color: #432ebb;
            transform: translateX(-2px);
        }
        .secure-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            color: #059669;
            background: #ecfdf5;
            padding: 5px 12px;
            border-radius: 999px;
            font-weight: 600;
            border: 1px solid #a7f3d0;
        }
        .redirect-banner {
            background: linear-gradient(135deg, #f5f3ff 0%, #ede9fe 100%);
            border: 1px solid #ddd6fe;
            border-radius: 14px;
            padding: 16px 20px;
            margin-bottom: 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 16px;
            flex-wrap: wrap;
        }
        .redirect-info {
            display: flex;
            align-items: center;
            gap: 14px;
            color: #3b0764;
        }
        .redirect-icon {
            font-size: 26px;
            color: #7c3aed;
        }
        .redirect-title {
            font-size: 14.5px;
            font-weight: 700;
            color: #3b0764;
        }
        .redirect-sub {
            font-size: 13px;
            color: #6b21a8;
            margin-top: 2px;
        }
        .redirect-countdown {
            font-weight: 800;
            color: #7c3aed;
        }
        .redirect-actions {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .btn-direct-now {
            padding: 8px 16px;
            background: #7c3aed;
            color: #ffffff;
            border-radius: 9px;
            text-decoration: none;
            font-size: 13px;
            font-weight: 700;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: background 0.15s;
        }
        .btn-direct-now:hover {
            background: #6d28d9;
        }
        .btn-stay {
            padding: 8px 14px;
            background: #ffffff;
            border: 1px solid #c4b5fd;
            color: #5b21b6;
            border-radius: 9px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 600;
            transition: background 0.15s;
        }
        .btn-stay:hover {
            background: #faf5ff;
        }
        .brand {
            display: flex;
            align-items: center;
            gap: 14px;
            margin-bottom: 24px;
        }
        .mark {
            width: 46px;
            height: 46px;
            border-radius: 14px;
            background: linear-gradient(135deg, #7c3aed 0%, #5b43d6 100%);
            color: #fff;
            display: grid;
            place-items: center;
            font-weight: 800;
            font-size: 20px;
            box-shadow: 0 4px 14px rgba(91, 67, 214, 0.35);
        }
        .brand-title {
            margin: 0;
            font-size: 22px;
            font-weight: 800;
            color: #1e1b4b;
        }
        .sub {
            color: #71717a;
            font-size: 13px;
            margin-top: 2px;
        }
        .row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 20px;
            border-bottom: 1px solid #f1f3f7;
            padding: 12px 0;
            font-size: 14px;
        }
        .row span {
            color: #64748b;
            font-weight: 500;
        }
        .row strong {
            text-align: right;
            color: #0f172a;
            font-weight: 700;
        }
        .status-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
        }
        .status-pending {
            background: #fef3c7;
            color: #b45309;
        }
        .status-success {
            background: #dcfce7;
            color: #15803d;
        }
        .notice {
            margin: 22px 0 20px;
            padding: 14px 16px;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            color: #475569;
            font-size: 13px;
            line-height: 1.5;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .notice i {
            color: #6366f1;
            font-size: 16px;
            flex-shrink: 0;
        }
        .receipt-actions {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-top: 26px;
            padding-top: 20px;
            border-top: 1px solid #f0f2f7;
            flex-wrap: wrap;
        }
        .btn-dash {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 12px 24px;
            background: linear-gradient(135deg, #7c3aed 0%, #5b43d6 100%);
            color: #ffffff;
            text-decoration: none;
            border-radius: 12px;
            font-weight: 700;
            font-size: 14px;
            box-shadow: 0 4px 14px rgba(91, 67, 214, 0.3);
            transition: transform 0.15s, box-shadow 0.15s;
        }
        .btn-dash:hover {
            transform: translateY(-1px);
            box-shadow: 0 6px 18px rgba(91, 67, 214, 0.4);
            color: #ffffff;
        }
        .btn-print {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 12px 20px;
            background: #f8fafc;
            color: #334155;
            border: 1px solid #cbd5e1;
            border-radius: 12px;
            font-weight: 700;
            font-size: 14px;
            cursor: pointer;
            transition: background 0.15s, border-color 0.15s;
        }
        .btn-print:hover {
            background: #f1f5f9;
            border-color: #94a3b8;
        }
        @media print {
            .top-bar, .redirect-banner, .receipt-actions, .no-print {
                display: none !important;
            }
            body {
                background: white;
                padding: 0;
            }
            .receipt {
                box-shadow: none;
                border: none;
                padding: 0;
            }
        }
        @media (max-width: 600px) {
            body { padding: 16px 10px; }
            .receipt { padding: 22px 18px; }
            .row { flex-direction: column; align-items: flex-start; gap: 4px; }
            .row strong { text-align: left; }
            .receipt-actions { flex-direction: column; width: 100%; }
            .btn-dash, .btn-print { width: 100%; }
        }
    </style>
</head>
<body>
<div class="receipt">
    <div class="top-bar">
        <a href="<%=dashUrl%>" class="back-link">
            <i class="fa-solid fa-arrow-left"></i> <%= "STUDENT".equalsIgnoreCase(role) ? "Back to Student Dashboard" : ("PARENT".equalsIgnoreCase(role) ? "Back to Parent Dashboard" : "Back to Dashboard") %>
        </a>
        <span class="secure-badge">
            <i class="fa-solid fa-shield-halved"></i> Verified Transaction
        </span>
    </div>

    <% if (isNewPayment) { %>
    <div class="redirect-banner" id="redirectBanner">
        <div class="redirect-info">
            <i class="fa-solid fa-circle-check redirect-icon"></i>
            <div>
                <div class="redirect-title">Payment Submitted Successfully!</div>
                <div class="redirect-sub">Directing to Student Dashboard in <span id="countdown" class="redirect-countdown">5</span> seconds...</div>
            </div>
        </div>
        <div class="redirect-actions">
            <a href="<%=dashUrl%>" class="btn-direct-now"><i class="fa-solid fa-gauge"></i> Go Now</a>
            <button type="button" class="btn-stay" onclick="stopCountdown()">Stay on Receipt</button>
        </div>
    </div>
    <% } %>

    <div class="brand">
        <span class="mark">C</span>
        <div>
            <h1 class="brand-title">Classora Payment Receipt</h1>
            <div class="sub">Official and secure payment record</div>
        </div>
    </div>

    <% if(p != null) { %>
    <div class="row">
        <span>Receipt No.</span>
        <strong style="color:#7c3aed;font-family:monospace;font-size:15px;"><%=h(p.getReceiptNo())%></strong>
    </div>
    <div class="row">
        <span>Student</span>
        <strong><%=h(p.getStudentName())%></strong>
    </div>
    <div class="row">
        <span>Class</span>
        <strong><%=h(p.getSubject())%> - <%=h(p.getBatch())%></strong>
    </div>
    <div class="row">
        <span>Amount</span>
        <strong style="font-size:16px;color:#0f172a;">LKR <%=h(p.getAmountPaid())%></strong>
    </div>
    <div class="row">
        <span>Payment Method</span>
        <strong><%=p.getSlipPath() != null ? "Bank Transfer / Deposit Slip" : h(p.getPaymentMethod())%></strong>
    </div>
    <% if(p.getCardHolderName() != null && !p.getCardHolderName().isBlank()) { %>
    <div class="row">
        <span><%=p.getSlipPath() != null ? "Depositor Name" : "Card Holder"%></span>
        <strong><%=h(p.getCardHolderName())%></strong>
    </div>
    <% } %>
    <% if(p.getBankName() != null && !p.getBankName().isBlank()) { %>
    <div class="row">
        <span>Bank &amp; Branch</span>
        <strong><%=h(p.getBankName())%><%=p.getBranchName() != null && !p.getBranchName().isBlank() ? (" - " + h(p.getBranchName())) : ""%></strong>
    </div>
    <% } %>
    <% if(p.getMaskedCardNo() != null && !p.getMaskedCardNo().isBlank()) { %>
    <div class="row">
        <span>Card Number</span>
        <strong style="letter-spacing:1px;"><%=h(p.getMaskedCardNo())%></strong>
    </div>
    <% } %>
    <div class="row">
        <span>Payment Reference</span>
        <strong style="font-family:monospace;color:#475569;"><%=h(p.getGatewayOrderId())%></strong>
    </div>
    <% if(p.getSlipPath() != null && !p.getSlipPath().isBlank()) { %>
    <div class="row">
        <span>Uploaded Bank Slip</span>
        <strong><a href="<%=cp%>/<%=h(p.getSlipPath())%>" target="_blank" style="color:#2563eb;text-decoration:none;"><i class="fa-solid fa-file-invoice"></i> View Slip Document</a></strong>
    </div>
    <% } %>
    <div class="row">
        <span>Submitted Date</span>
        <strong><%=h(p.getPaymentDate())%></strong>
    </div>
    <div class="row">
        <span>Admin Status</span>
        <strong>
            <% String aStatus = p.getAdminStatus() != null ? p.getAdminStatus() : "PENDING"; %>
            <span class="status-badge <%="APPROVED".equalsIgnoreCase(aStatus) || "ACTIVE".equalsIgnoreCase(aStatus) ? "status-success" : "status-pending"%>">
                <%=h(aStatus)%>
            </span>
        </strong>
    </div>

    <div class="notice">
        <i class="fa-solid fa-circle-info"></i>
        <span>Bank slip submitted and recorded for administrative verification. You can view all past transactions in your student portal.</span>
    </div>

    <div class="receipt-actions">
        <a href="<%=dashUrl%>" class="btn-dash">
            <i class="fa-solid fa-gauge"></i> <%=dashLabel%>
        </a>
        <button type="button" class="btn-print" onclick="stopCountdown(); window.print();">
            <i class="fa-solid fa-print"></i> Print Receipt
        </button>
    </div>
    <% } else { %>
    <div style="padding:40px 20px;text-align:center;color:#64748b;">
        <i class="fa-solid fa-triangle-exclamation" style="font-size:32px;color:#eab308;margin-bottom:12px;"></i>
        <p>Receipt not found or not accessible.</p>
        <a href="<%=dashUrl%>" class="btn-dash" style="margin-top:12px;display:inline-block;"><i class="fa-solid fa-gauge"></i> <%=dashLabel%></a>
    </div>
    <% } %>
</div>

<script>
    var timerId = null;
    var count = 5;

    function startCountdown() {
        var el = document.getElementById('countdown');
        if (!el) return;
        timerId = setInterval(function() {
            count--;
            if (el) el.textContent = count;
            if (count <= 0) {
                clearInterval(timerId);
                window.location.href = '<%=dashUrl%>';
            }
        }, 1000);
    }

    function stopCountdown() {
        if (timerId) {
            clearInterval(timerId);
            timerId = null;
        }
        var banner = document.getElementById('redirectBanner');
        if (banner) {
            banner.style.display = 'none';
        }
    }

    <% if (isNewPayment) { %>
    window.addEventListener('DOMContentLoaded', function() {
        startCountdown();
    });
    <% } %>
</script>
</body>
</html>
