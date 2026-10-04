<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Invoice,model.Enrollment,model.Class" %>
<%!
private String h(Object value){
    if(value==null)return "";
    return String.valueOf(value).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
}
%>
<%
String cp = request.getContextPath();
Invoice invoice = (Invoice) request.getAttribute("invoice");
Enrollment enrollment = (Enrollment) request.getAttribute("enrollment");
Class classItem = (Class) request.getAttribute("classItem");
String error = request.getAttribute("paymentError") == null ? "" : String.valueOf(request.getAttribute("paymentError"));
String depositor = request.getAttribute("depositorName") == null ? "" : String.valueOf(request.getAttribute("depositorName"));
String bank = request.getAttribute("bankName") == null ? "Commercial Bank" : String.valueOf(request.getAttribute("bankName"));
String branch = request.getAttribute("branchName") == null ? "" : String.valueOf(request.getAttribute("branchName"));
String refNo = request.getAttribute("referenceNumber") == null ? "" : String.valueOf(request.getAttribute("referenceNumber"));
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Upload Bank Slip | Classora</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<link rel="stylesheet" href="<%=cp%>/css/class-pages.css">
<style>
.bank-info-card {
    background: linear-gradient(135deg, #eff6ff 0%, #f0fdf4 100%);
    border: 1.5px solid #bfdbfe;
    border-radius: 16px;
    padding: 24px;
    margin-bottom: 24px;
}
.bank-info-header {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 16px;
}
.bank-info-header i {
    font-size: 24px;
    color: #2563eb;
}
.bank-info-header h3 {
    margin: 0;
    font-size: 18px;
    font-weight: 700;
    color: #1e3a8a;
}
.bank-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 16px;
    margin-bottom: 16px;
}
.bank-grid-item {
    background: #ffffff;
    padding: 12px 16px;
    border-radius: 10px;
    border: 1px solid #e2e8f0;
}
.bank-grid-item span {
    display: block;
    font-size: 12px;
    color: #64748b;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}
.bank-grid-item strong {
    font-size: 15px;
    color: #0f172a;
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-top: 4px;
}
.copy-btn {
    background: none;
    border: none;
    color: #2563eb;
    cursor: pointer;
    font-size: 13px;
    padding: 2px 6px;
    border-radius: 4px;
}
.copy-btn:hover { background: #dbeafe; }
.bank-instructions {
    background: #ffffff99;
    padding: 12px 14px;
    border-radius: 8px;
    font-size: 13px;
    color: #334155;
    line-height: 1.5;
}
.slip-dropzone {
    border: 2px dashed #cbd5e1;
    border-radius: 12px;
    padding: 28px 20px;
    text-align: center;
    cursor: pointer;
    transition: all 0.2s ease;
    background: #f8fafc;
    position: relative;
}
.slip-dropzone:hover, .slip-dropzone.dragover {
    border-color: #3b82f6;
    background: #eff6ff;
}
.slip-dropzone input[type="file"] {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    opacity: 0;
    cursor: pointer;
}
.slip-preview-box {
    margin-top: 14px;
    display: none;
    text-align: center;
}
.slip-preview-img {
    max-height: 240px;
    max-width: 100%;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    border: 1px solid #e2e8f0;
}
.file-name-pill {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    margin-top: 8px;
    background: #e2e8f0;
    color: #1e293b;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;
}
</style>
</head>
<body class="class-page-body">
<header class="class-page-header">
  <a class="class-brand" href="<%=cp%>/dashboard"><span class="class-brand-mark">C</span><span class="class-brand-copy"><span class="class-brand-title">Classora</span><span class="class-brand-subtitle">Student Portal</span></span></a>
  <div class="class-header-actions"><a class="class-nav-link" href="<%=cp%>/enroll?classId=<%=classItem.getClassId()%>"><i class="fa-solid fa-arrow-left"></i> Class Details</a></div>
</header>
<main class="class-page-shell">
<section class="class-detail-card demo-payment-card" style="max-width:760px;margin:auto;">
  <div class="class-detail-head">
    <div>
      <span class="class-page-kicker"><i class="fa-solid fa-building-columns"></i> Bank Slip Verification</span>
      <h1 class="class-detail-title"><%=h(classItem.getSubject())%> — <%=h(classItem.getBatch())%></h1>
      <p class="demo-payment-note">Transfer or deposit the class fee to the institute bank account and upload your payment slip below for Admin approval.</p>
    </div>
    <div class="class-fee-box">
      <span>Class Fee</span>
      <strong>Rs. <%=h(invoice.getAmount())%></strong>
    </div>
  </div>

  <!-- Institute Bank Account Details -->
  <div class="bank-info-card">
    <div class="bank-info-header">
      <i class="fa-solid fa-landmark"></i>
      <div>
        <h3>Institute Bank Account Details</h3>
        <p style="margin:2px 0 0;font-size:13px;color:#475569;">Make payment to the following account via Cash Deposit, CDM, or Online Banking Transfer:</p>
      </div>
    </div>
    <div class="bank-grid">
      <div class="bank-grid-item">
        <span>Bank</span>
        <strong>Commercial Bank of Ceylon</strong>
      </div>
      <div class="bank-grid-item">
        <span>Account Name</span>
        <strong>Classora Institute</strong>
      </div>
      <div class="bank-grid-item">
        <span>Account Number</span>
        <strong>
          <span id="accNo">1000 8923 4512</span>
          <button type="button" class="copy-btn" onclick="copyAccountNo()" title="Copy Account Number"><i class="fa-regular fa-copy"></i> Copy</button>
        </strong>
      </div>
      <div class="bank-grid-item">
        <span>Branch</span>
        <strong>Colombo City Branch</strong>
      </div>
    </div>
    <div class="bank-instructions">
      <i class="fa-solid fa-circle-info" style="color:#2563eb;margin-right:4px;"></i>
      <strong>Important:</strong> Include your student name as the deposit/transfer reference. After depositing, take a clear photo or screenshot of the receipt and submit below.
    </div>
  </div>

  <% if(!error.isEmpty()){ %><div class="class-notice"><i class="fa-solid fa-circle-exclamation"></i> <%=h(error)%></div><% } %>

  <form class="demo-card-form" action="<%=cp%>/student/payment" method="post" enctype="multipart/form-data" autocomplete="off">
    <input type="hidden" name="enrollmentId" value="<%=enrollment.getEnrollmentId()%>">

    <div class="demo-field demo-field-full">
      <label for="depositorName"><i class="fa-solid fa-user"></i> Depositor / Student Full Name</label>
      <input id="depositorName" name="depositorName" maxlength="120" value="<%=h(depositor)%>" placeholder="e.g. Kasun Perera" required>
    </div>

    <div class="demo-field">
      <label for="bankName"><i class="fa-solid fa-building-columns"></i> Paid Bank</label>
      <select id="bankName" name="bankName" class="form-control" style="width:100%;padding:11px 14px;border:1.5px solid #dbe2ea;border-radius:10px;font-size:14px;background:#fff;" required>
        <option value="Commercial Bank" <%="Commercial Bank".equals(bank)?"selected":""%>>Commercial Bank</option>
        <option value="Bank of Ceylon (BOC)" <%="Bank of Ceylon (BOC)".equals(bank)?"selected":""%>>Bank of Ceylon (BOC)</option>
        <option value="People's Bank" <%="People's Bank".equals(bank)?"selected":""%>>People's Bank</option>
        <option value="Sampath Bank" <%="Sampath Bank".equals(bank)?"selected":""%>>Sampath Bank</option>
        <option value="Hatton National Bank (HNB)" <%="Hatton National Bank (HNB)".equals(bank)?"selected":""%>>Hatton National Bank (HNB)</option>
        <option value="Nations Trust Bank (NTB)" <%="Nations Trust Bank (NTB)".equals(bank)?"selected":""%>>Nations Trust Bank (NTB)</option>
        <option value="Seylan Bank" <%="Seylan Bank".equals(bank)?"selected":""%>>Seylan Bank</option>
        <option value="Other Bank / Online Transfer" <%="Other Bank / Online Transfer".equals(bank)?"selected":""%>>Other Bank / Online Transfer</option>
      </select>
    </div>

    <div class="demo-field">
      <label for="branchName"><i class="fa-solid fa-location-dot"></i> Branch / CDM (Optional)</label>
      <input id="branchName" name="branchName" maxlength="100" value="<%=h(branch)%>" placeholder="e.g. Kandy Branch / Online App">
    </div>

    <div class="demo-field demo-field-full">
      <label for="referenceNumber"><i class="fa-solid fa-receipt"></i> Slip Reference / Transaction Number</label>
      <input id="referenceNumber" name="referenceNumber" maxlength="100" value="<%=h(refNo)%>" placeholder="e.g. TXN-948201 / Slip No. 4821" required>
    </div>

    <div class="demo-field demo-field-full">
      <label><i class="fa-solid fa-file-invoice"></i> Upload Bank Deposit Slip / Transfer Receipt</label>
      <div class="slip-dropzone" id="dropzone">
        <input type="file" id="slipFile" name="slipFile" accept="image/*,application/pdf" required onchange="previewSlip(this)">
        <i class="fa-solid fa-cloud-arrow-up" style="font-size:36px;color:#3b82f6;margin-bottom:8px;display:block;"></i>
        <strong style="color:#1e293b;font-size:15px;display:block;">Click to choose file or drag &amp; drop here</strong>
        <span style="font-size:13px;color:#64748b;display:block;margin-top:4px;">Supported: JPG, PNG, WEBP, PDF (Max 10MB)</span>
      </div>
      <div class="slip-preview-box" id="previewBox">
        <img id="previewImg" class="slip-preview-img" alt="Slip Preview">
        <div id="pdfNotice" style="display:none;padding:16px;background:#f1f5f9;border-radius:8px;color:#334155;font-weight:600;"><i class="fa-solid fa-file-pdf" style="color:#ef4444;font-size:24px;vertical-align:middle;margin-right:8px;"></i> PDF Document Selected</div>
        <div class="file-name-pill" id="fileNamePill"><i class="fa-solid fa-check"></i> <span id="fileNameText">file</span></div>
      </div>
    </div>

    <div class="demo-safe-note demo-field-full">
      <i class="fa-solid fa-shield-halved"></i>
      <span>Your bank slip is encrypted and accessible only to Classora administration for enrollment verification. Once approved, class access will be activated immediately.</span>
    </div>

    <div class="demo-field-full">
      <button class="class-primary-btn demo-submit-btn" type="submit" style="background:#16a34a;display:flex;align-items:center;justify-content:center;gap:8px;">
        <i class="fa-solid fa-upload"></i> Submit Slip for Approval
      </button>
    </div>
  </form>
</section>
</main>

<script>
function copyAccountNo() {
    navigator.clipboard.writeText("100089234512").then(() => {
        alert("Account number copied to clipboard: 1000 8923 4512");
    }).catch(() => {
        alert("Account Number: 1000 8923 4512");
    });
}

function previewSlip(input) {
    const previewBox = document.getElementById('previewBox');
    const previewImg = document.getElementById('previewImg');
    const pdfNotice = document.getElementById('pdfNotice');
    const fileNameText = document.getElementById('fileNameText');

    if (input.files && input.files[0]) {
        const file = input.files[0];
        fileNameText.textContent = file.name + ' (' + (file.size / 1024).toFixed(1) + ' KB)';
        previewBox.style.display = 'block';

        if (file.type === 'application/pdf') {
            previewImg.style.display = 'none';
            pdfNotice.style.display = 'block';
        } else {
            pdfNotice.style.display = 'none';
            previewImg.style.display = 'inline-block';
            const reader = new FileReader();
            reader.onload = function(e) {
                previewImg.src = e.target.result;
            };
            reader.readAsDataURL(file);
        }
    } else {
        previewBox.style.display = 'none';
    }
}

const dropzone = document.getElementById('dropzone');
['dragenter', 'dragover'].forEach(eventName => {
    dropzone.addEventListener(eventName, (e) => { e.preventDefault(); dropzone.classList.add('dragover'); }, false);
});
['dragleave', 'drop'].forEach(eventName => {
    dropzone.addEventListener(eventName, (e) => { e.preventDefault(); dropzone.classList.remove('dragover'); }, false);
});
</script>
</body>
</html>
