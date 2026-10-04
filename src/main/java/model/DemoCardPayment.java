package model;

public record DemoCardPayment(
        String cardHolderName,
        String cardNumber,
        String expiry,
        String cvv
) {
    public static String normalizeExpiry(String value) {
        if (value == null) return "";
        String v = value.trim().replace('-', '/').replace(" ", "");
        if (v.isEmpty()) return "";

        String month;
        String year;
        if (v.matches("\\d{4}")) {
            month = v.substring(0, 2);
            year = v.substring(2);
        } else if (v.matches("\\d{1,2}/\\d{2}")) {
            String[] parts = v.split("/");
            month = parts[0];
            year = parts[1];
        } else if (v.matches("\\d{1,2}/\\d{4}")) {
            String[] parts = v.split("/");
            month = parts[0];
            year = parts[1].substring(2);
        } else {
            return "";
        }

        int m;
        try {
            m = Integer.parseInt(month);
        } catch (NumberFormatException e) {
            return "";
        }
        if (m < 1 || m > 12) return "";
        return String.format("%02d/%s", m, year);
    }
}
