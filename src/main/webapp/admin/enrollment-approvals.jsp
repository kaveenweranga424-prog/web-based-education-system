<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %><%@ page import="model.Payment" %>
<%!
private String h(Object v){if(v==null)return "";return String.valueOf(v).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");}
%>
<%
String cp = request.getContextPath();
List<Payment> payments = (List<Payment>) request.getAttribute("payments");
Object err = session.getAttribute("workflowError");
if(err != null) session.removeAttribute("workflowError");
%>
<!doctype html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Enrollment Approvals | Classora</title>
<link rel="stylesheet" href="<%=cp%>/css/dashboard.css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<style>
body{font-family:Inter,Arial,sans-serif;background:#f6f7fb;padding:28px;color:#23273a}
.page{max-width:1240px;margin:auto}
.head{display:flex;justify-content:space-between;gap:20px;align-items:center;margin-bottom:22px}
.head h1{font-size:24px;font-weight:700;margin:0 0 4px 0}
.head p{color:#73798e;margin:0}
.back-btn{display:inline-flex;align-items:center;gap:6px;padding:9px 16px;background:#fff;border:1px solid #d9ddea;border-radius:10px;color:#334155;text-decoration:none;font-weight:600;font-size:14px;transition:background 0.2s}
.back-btn:hover{background:#f1f5f9}
.panel{background:#fff;border-radius:16px;box-shadow:0 8px 30px #20284012;overflow:auto}
table{width:100%;border-collapse:collapse;min-width:960px}
th,td{padding:14px;border-bottom:1px solid #eee;text-align:left;font-size:14px;vertical-align:middle}
th{background:#fafaff;color:#666d83;font-weight:600}
.ok{background:#16a34a;color:white;border:0;padding:8px 14px;border-radius:8px;font-weight:600;font-size:13px;cursor:pointer;display:inline-flex;align-items:center;gap:6px;transition:background 0.15s}
.ok:hover{background:#15803d}
.bad{background:#dc2626;color:white;border:0;padding:8px 14px;border-radius:8px;font-weight:600;font-size:13px;cursor:pointer;display:inline-flex;align-items:center;gap:6px;transition:background 0.15s}
.bad:hover{background:#b91c1c}
input{padding:8px 10px;border:1px solid #d9ddea;border-radius:8px;font-size:13px}
.actions{display:flex;gap:8px;align-items:center;flex-wrap:wrap}
.error{padding:12px 14px;background:#fff1f1;color:#a52c2c;border-radius:10px;margin-bottom:14px;border:1px solid #fecaca}
.slip-btn{display:inline-flex;align-items:center;gap:6px;padding:6px 12px;background:#eff6ff;color:#2563eb;border:1px solid #bfdbfe;border-radius:8px;text-decoration:none;font-weight:600;font-size:13px;cursor:pointer;transition:all 0.15s}
.slip-btn:hover{background:#dbeafe;border-color:#93c5fd}
.slip-thumb{width:42px;height:42px;border-radius:6px;object-fit:cover;border:1px solid #cbd5e1;cursor:pointer;vertical-align:middle;margin-right:6px}
/* Modal Lightbox */
.modal-overlay{position:fixed;inset:0;background:rgba(15,23,42,0.75);display:none;align-items:center;justify-content:center;z-index:9999;padding:20px}
.modal-overlay.open{display:flex}
.modal-card{background:#fff;border-radius:16px;max-width:800px;width:100%;max-height:90vh;display:flex;flex-direction:column;overflow:hidden;box-shadow:0 25px 50px -12px rgba(0,0,0,0.25)}
.modal-head{display:flex;justify-content:space-between;align-items:center;padding:16px 20px;border-bottom:1px solid #e2e8f0}
.modal-head h3{margin:0;font-size:17px;font-weight:700}
.modal-close{background:none;border:none;font-size:20px;color:#64748b;cursor:pointer}
.modal-body{padding:20px;overflow:auto;text-align:center;background:#f8fafc}
.modal-body img{max-width:100%;max-height:70vh;border-radius:8px;box-shadow:0 4px 12px rgba(0,0,0,0.1)}
</style>
</head>
<body>
<div class="page">
  <div class="head">
    <div>
      <h1>Enrollment Approvals</h1>
      <p>Verify uploaded bank deposit / transfer slips and approve class enrollments to grant access.</p>
    </div>
    <a href="<%=cp%>/dashboard" class="back-btn"><i class="fa-solid fa-arrow-left"></i> Back to Dashboard</a>
  </div>

  <% if(err!=null){ %><div class="error"><i class="fa-solid fa-circle-exclamation"></i> <%=h(err)%></div><% } %>

  <div class="panel">
    <table>
      <thead>
        <tr>
          <th>Student</th>
          <th>Class</th>
          <th>Amount</th>
          <th>Payer &amp; Bank</th>
          <th>Slip / Reference</th>
          <th>Payment Date</th>
          <th>Bank Slip</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody>
      <% if(payments != null && !payments.isEmpty()){
           for(Payment p : payments){
             String slipPath = p.getSlipPath();
             boolean hasSlip = slipPath != null && !slipPath.isBlank();
             boolean isPdf = hasSlip && slipPath.toLowerCase().endsWith(".pdf");
      %>
        <tr>
          <td>
            <strong><%=h(p.getStudentName())%></strong>
          </td>
          <td>
            <strong><%=h(p.getSubject())%></strong>
            <div style="font-size:12px;color:#64748b;"><%=h(p.getBatch())%></div>
          </td>
          <td style="font-weight:700;color:#15803d;white-space:nowrap;">
            Rs. <%=h(p.getAmountPaid())%>
          </td>
          <td>
            <div><strong><%=h(p.getCardHolderName() != null ? p.getCardHolderName() : p.getStudentName())%></strong></div>
            <div style="font-size:12px;color:#64748b;">
              <%=h(p.getBankName() != null ? p.getBankName() : "Bank Transfer")%>
              <%=p.getBranchName() != null && !p.getBranchName().isBlank() ? (" · " + h(p.getBranchName())) : ""%>
            </div>
          </td>
          <td>
            <code style="background:#f1f5f9;padding:3px 7px;border-radius:6px;font-size:12px;"><%=h(p.getGatewayOrderId())%></code>
          </td>
          <td style="font-size:13px;color:#64748b;white-space:nowrap;">
            <%=h(p.getPaymentDate())%>
          </td>
          <td>
            <% if(hasSlip){ %>
              <div style="display:flex;align-items:center;">
                <% if(!isPdf){ %>
                  <img src="<%=cp%>/<%=h(slipPath)%>" class="slip-thumb" alt="Slip" onclick="openSlipModal('<%=cp%>/<%=h(slipPath)%>', '<%=h(p.getStudentName())%>')">
                <% } %>
                <a href="<%=cp%>/<%=h(slipPath)%>" target="_blank" class="slip-btn">
                  <i class="fa-solid <%=isPdf ? "fa-file-pdf" : "fa-arrow-up-right-from-square"%>"></i>
                  <%=isPdf ? "View PDF" : "Inspect"%>
                </a>
              </div>
            <% } else { %>
              <span style="color:#94a3b8;font-size:13px;font-style:italic;">No file</span>
            <% } %>
          </td>
          <td>
            <div class="actions">
              <form method="post">
                <input type="hidden" name="paymentId" value="<%=p.getPaymentId()%>">
                <input type="hidden" name="action" value="approve">
                <button type="submit" class="ok" onclick="return confirm('Approve enrollment for <%=h(p.getStudentName())%>? This will grant immediate access to class materials and live sessions.');">
                  <i class="fa-solid fa-check"></i> Approve
                </button>
              </form>
              <form method="post" style="display:flex;gap:4px;">
                <input type="hidden" name="paymentId" value="<%=p.getPaymentId()%>">
                <input type="hidden" name="action" value="reject">
                <input name="reason" placeholder="Rejection note" required maxlength="500" style="width:130px;">
                <button type="submit" class="bad" onclick="return confirm('Reject this payment request?');">
                  <i class="fa-solid fa-xmark"></i> Reject
                </button>
              </form>
            </div>
          </td>
        </tr>
      <%   }
         } else { %>
        <tr>
          <td colspan="8" style="text-align:center;padding:36px;color:#64748b;">
            <i class="fa-solid fa-circle-check" style="font-size:28px;color:#22c55e;margin-bottom:8px;display:block;"></i>
            No payment slips waiting for Admin approval.
          </td>
        </tr>
      <% } %>
      </tbody>
    </table>
  </div>
</div>

<!-- Modal Lightbox for Image Preview -->
<div class="modal-overlay" id="slipModal" onclick="closeSlipModal(event)">
  <div class="modal-card" onclick="event.stopPropagation()">
    <div class="modal-head">
      <h3 id="modalStudentName">Payment Slip Inspection</h3>
      <button class="modal-close" onclick="closeSlipModal()">&times;</button>
    </div>
    <div class="modal-body">
      <img id="modalImg" src="" alt="Bank Slip">
    </div>
  </div>
</div>

<script>
function openSlipModal(src, studentName) {
    document.getElementById('modalImg').src = src;
    document.getElementById('modalStudentName').textContent = 'Bank Slip — ' + studentName;
    document.getElementById('slipModal').classList.add('open');
}
function closeSlipModal() {
    document.getElementById('slipModal').classList.remove('open');
}
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeSlipModal();
});
</script>
</body>
</html>
