package model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class Payment {
    private int paymentId;
    private int invoiceId;
    private int studentId;
    private int classId;
    private String subject;
    private String batch;
    private String studentName;
    private BigDecimal amountPaid;
    private String paymentMethod;
    private Timestamp paymentDate;
    private Integer receivedBy;
    private String receivedByName;

    private String gatewayOrderId;
    private String gatewayPaymentId;
    private String gatewayStatus;
    private String gatewayMethod;
    private String maskedCardNo;
    private String cardHolderName;
    private String slipPath;
    private String bankName;
    private String branchName;

    private String staffStatus;
    private String staffNote;
    private Integer confirmedBy;
    private String confirmedByName;
    private Timestamp confirmedAt;

    private String adminStatus;
    private String adminNote;
    private Integer approvedBy;
    private String approvedByName;
    private Timestamp approvedAt;

    public Payment() {}

    public int getPaymentId() { return paymentId; }
    public void setPaymentId(int paymentId) { this.paymentId = paymentId; }
    public int getInvoiceId() { return invoiceId; }
    public void setInvoiceId(int invoiceId) { this.invoiceId = invoiceId; }
    public int getStudentId() { return studentId; }
    public void setStudentId(int studentId) { this.studentId = studentId; }
    public int getClassId() { return classId; }
    public void setClassId(int classId) { this.classId = classId; }
    public String getSubject() { return subject; }
    public void setSubject(String subject) { this.subject = subject; }
    public String getBatch() { return batch; }
    public void setBatch(String batch) { this.batch = batch; }
    public String getStudentName() { return studentName; }
    public void setStudentName(String studentName) { this.studentName = studentName; }
    public BigDecimal getAmountPaid() { return amountPaid; }
    public void setAmountPaid(BigDecimal amountPaid) { this.amountPaid = amountPaid; }
    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }
    public Timestamp getPaymentDate() { return paymentDate; }
    public void setPaymentDate(Timestamp paymentDate) { this.paymentDate = paymentDate; }
    public Integer getReceivedBy() { return receivedBy; }
    public void setReceivedBy(Integer receivedBy) { this.receivedBy = receivedBy; }
    public String getReceivedByName() { return receivedByName; }
    public void setReceivedByName(String receivedByName) { this.receivedByName = receivedByName; }

    public String getGatewayOrderId() { return gatewayOrderId; }
    public void setGatewayOrderId(String gatewayOrderId) { this.gatewayOrderId = gatewayOrderId; }
    public String getGatewayPaymentId() { return gatewayPaymentId; }
    public void setGatewayPaymentId(String gatewayPaymentId) { this.gatewayPaymentId = gatewayPaymentId; }
    public String getGatewayStatus() { return gatewayStatus; }
    public void setGatewayStatus(String gatewayStatus) { this.gatewayStatus = gatewayStatus; }
    public String getGatewayMethod() { return gatewayMethod; }
    public void setGatewayMethod(String gatewayMethod) { this.gatewayMethod = gatewayMethod; }
    public String getMaskedCardNo() { return maskedCardNo; }
    public void setMaskedCardNo(String maskedCardNo) { this.maskedCardNo = maskedCardNo; }
    public String getCardHolderName() { return cardHolderName; }
    public void setCardHolderName(String cardHolderName) { this.cardHolderName = cardHolderName; }

    public String getStaffStatus() { return staffStatus; }
    public void setStaffStatus(String staffStatus) { this.staffStatus = staffStatus; }
    public String getStaffNote() { return staffNote; }
    public void setStaffNote(String staffNote) { this.staffNote = staffNote; }
    public Integer getConfirmedBy() { return confirmedBy; }
    public void setConfirmedBy(Integer confirmedBy) { this.confirmedBy = confirmedBy; }
    public String getConfirmedByName() { return confirmedByName; }
    public void setConfirmedByName(String confirmedByName) { this.confirmedByName = confirmedByName; }
    public Timestamp getConfirmedAt() { return confirmedAt; }
    public void setConfirmedAt(Timestamp confirmedAt) { this.confirmedAt = confirmedAt; }

    public String getAdminStatus() { return adminStatus; }
    public void setAdminStatus(String adminStatus) { this.adminStatus = adminStatus; }
    public String getAdminNote() { return adminNote; }
    public void setAdminNote(String adminNote) { this.adminNote = adminNote; }
    public Integer getApprovedBy() { return approvedBy; }
    public void setApprovedBy(Integer approvedBy) { this.approvedBy = approvedBy; }
    public String getApprovedByName() { return approvedByName; }
    public void setApprovedByName(String approvedByName) { this.approvedByName = approvedByName; }
    public Timestamp getApprovedAt() { return approvedAt; }
    public void setApprovedAt(Timestamp approvedAt) { this.approvedAt = approvedAt; }

    public String getSlipPath() { return slipPath; }
    public void setSlipPath(String slipPath) { this.slipPath = slipPath; }
    public String getBankName() { return bankName; }
    public void setBankName(String bankName) { this.bankName = bankName; }
    public String getBranchName() { return branchName; }
    public void setBranchName(String branchName) { this.branchName = branchName; }

    public String getReceiptNo() {
        return "RCPT-" + String.format("%06d", paymentId);
    }

    public boolean isGatewaySuccess() {
        return "SUCCESS".equalsIgnoreCase(gatewayStatus) || "DEMO_SUBMITTED".equalsIgnoreCase(gatewayStatus) || gatewayOrderId == null;
    }
}
