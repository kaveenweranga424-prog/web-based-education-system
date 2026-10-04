package model;

public record BankSlipPayment(
        String depositorName,
        String bankName,
        String branchName,
        String referenceNumber,
        String slipPath
) {
    public boolean isValid() {
        return depositorName != null && !depositorName.trim().isEmpty()
                && bankName != null && !bankName.trim().isEmpty()
                && referenceNumber != null && !referenceNumber.trim().isEmpty()
                && slipPath != null && !slipPath.trim().isEmpty();
    }
}
