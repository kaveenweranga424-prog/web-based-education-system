package service;

import dao.ClassDAO;
import model.Class;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ClassService {

    private final ClassDAO classDAO = new ClassDAO();

    private static final Set<String> VALID_STATUS = Set.of("ACTIVE", "INACTIVE");

    /**
     * Returns an error message, or null if the class was created successfully.
     */
    public String createClass(String subject, String batch, String tutorIdRaw, String feeRaw) throws SQLException {
        return createClass(subject, batch, tutorIdRaw, feeRaw, null, "WEEKDAY");
    }

    public String createClass(String subject, String batch, String tutorIdRaw, String feeRaw, String imagePath) throws SQLException {
        return createClass(subject, batch, tutorIdRaw, feeRaw, imagePath, "WEEKDAY");
    }

    public String createClass(String subject, String batch, String tutorIdRaw, String feeRaw,
                              String imagePath, String classType) throws SQLException {

        String cleanClassType = normalizeClassType(classType);
        String formattedBatch = formatBatchWithSchedule(batch, cleanClassType);

        String error = validateCommon(subject, formattedBatch, feeRaw);
        if (error != null) {
            return error;
        }

        // Prevent duplicate active class with identical subject, batch and class type
        List<Class> existingList = classDAO.search(subject.trim(), null, formattedBatch, cleanClassType);
        for (Class ec : existingList) {
            if (ec.getSubject().equalsIgnoreCase(subject.trim())
                    && ec.getBatch().equalsIgnoreCase(formattedBatch)
                    && ec.getClassType().equalsIgnoreCase(cleanClassType)
                    && "ACTIVE".equalsIgnoreCase(ec.getStatus())) {
                String typeDisplay = "WEEKEND".equalsIgnoreCase(cleanClassType) ? "Weekend" : "Weekday";
                return "An active class for '" + subject.trim() + " - " + formattedBatch + "' (" + typeDisplay + ") already exists.";
            }
        }

        Integer tutorId = parseTutorId(tutorIdRaw);
        BigDecimal fee = new BigDecimal(feeRaw.trim());

        Class classItem = new Class(subject.trim(), formattedBatch, tutorId, fee, imagePath, cleanClassType);

        int id = classDAO.createClass(classItem);

        if (id <= 0) {
            return "Failed to create the class. Please try again.";
        }

        return null;
    }

    public String updateClass(int classId, String subject, String batch, String tutorIdRaw,
                               String feeRaw, String status) throws SQLException {
        return updateClass(classId, subject, batch, tutorIdRaw, feeRaw, status, null, "WEEKDAY");
    }

    public String updateClass(int classId, String subject, String batch, String tutorIdRaw,
                               String feeRaw, String status, String imagePath) throws SQLException {
        return updateClass(classId, subject, batch, tutorIdRaw, feeRaw, status, imagePath, "WEEKDAY");
    }

    public String updateClass(int classId, String subject, String batch, String tutorIdRaw,
                               String feeRaw, String status, String imagePath, String classType) throws SQLException {

        String cleanClassType = normalizeClassType(classType);
        String formattedBatch = formatBatchWithSchedule(batch, cleanClassType);

        String error = validateCommon(subject, formattedBatch, feeRaw);
        if (error != null) {
            return error;
        }

        if (status == null || !VALID_STATUS.contains(status.trim().toUpperCase())) {
            return "Invalid class status.";
        }

        Class existing = classDAO.findById(classId);
        if (existing == null) {
            return "Class not found.";
        }

        existing.setSubject(subject.trim());
        existing.setBatch(formattedBatch);
        existing.setTutorId(parseTutorId(tutorIdRaw));
        existing.setFee(new BigDecimal(feeRaw.trim()));
        existing.setStatus(status.trim().toUpperCase());
        existing.setClassType(cleanClassType);
        if (imagePath != null && !imagePath.isBlank()) {
            existing.setImagePath(imagePath.trim());
        }

        boolean updated = classDAO.updateClass(existing);

        if (!updated) {
            return "Failed to update the class. Please try again.";
        }

        return null;
    }

    public boolean discontinueClass(int classId) throws SQLException {
        return classDAO.discontinueClass(classId);
    }

    public String deleteClass(int classId) throws SQLException {
        return classDAO.deleteClass(classId);
    }

    public Class findById(int classId) throws SQLException {
        return classDAO.findById(classId);
    }

    public List<Class> findAll() throws SQLException {
        return classDAO.findAll();
    }

    public List<Class> search(String subject, String tutorName, String batch) throws SQLException {
        return classDAO.search(subject, tutorName, batch);
    }

    public List<Class> search(String subject, String tutorName, String batch, String classType) throws SQLException {
        return classDAO.search(subject, tutorName, batch, classType);
    }

    public List<Class> findByTutor(int tutorId) throws SQLException {
        return classDAO.findByTutor(tutorId);
    }

    private static final Pattern HTTP_URL_PATTERN = Pattern.compile(
        "https?://[a-zA-Z0-9_.-]+(?:\\.[a-zA-Z]{2,})+(?::\\d+)?(?:/[^\\s\"'<>]*)?",
        Pattern.CASE_INSENSITIVE
    );

    private static final Pattern NO_SCHEME_PATTERN = Pattern.compile(
        "(?:[a-zA-Z0-9_-]+\\.)+(?:zoom\\.us|google\\.com|microsoft\\.com|webex\\.com)(?:/[^\\s\"'<>]*)?",
        Pattern.CASE_INSENSITIVE
    );

    /**
     * Intelligently extracts a valid meeting URL even if the user pasted a complete Zoom/Meet
     * invitation message (with topic, passcodes, multi-line text, etc.) or typed a domain without scheme.
     */
    public static String extractAndNormalizeMeetingLink(String input) {
        if (input == null) return null;
        String text = input.trim();
        if (text.isEmpty()) return null;

        // If previously saved with a dummy prepended scheme e.g. "https://janith is inviting you"
        if (text.startsWith("https://") && text.indexOf(' ') > 0 && text.indexOf(' ') < 15) {
            text = text.substring(8).trim();
        } else if (text.startsWith("http://") && text.indexOf(' ') > 0 && text.indexOf(' ') < 14) {
            text = text.substring(7).trim();
        }

        Matcher matcher = HTTP_URL_PATTERN.matcher(text);
        List<String> found = new ArrayList<>();
        while (matcher.find()) {
            String u = matcher.group().trim();
            // strip trailing punctuation such as '.', ',', ';', ')', '>'
            u = u.replaceAll("[.,;)>]+$", "");
            found.add(u);
        }

        if (!found.isEmpty()) {
            // 1st priority: Zoom join link containing /j/, /my/, or /w/
            for (String u : found) {
                if (u.contains("zoom.us/j/") || u.contains("zoom.us/my/") || u.contains("zoom.us/w/")) {
                    return u;
                }
            }
            // 2nd priority: Google Meet
            for (String u : found) {
                if (u.contains("meet.google.com/")) {
                    return u;
                }
            }
            // 3rd priority: Microsoft Teams
            for (String u : found) {
                if (u.contains("teams.microsoft.com/") || u.contains("teams.live.com/")) {
                    return u;
                }
            }
            // 4th priority: any zoom.us link
            for (String u : found) {
                if (u.contains("zoom.us")) {
                    return u;
                }
            }
            // Fallback: first found valid URL
            return found.get(0);
        }

        // Check if user entered domain without http/https (e.g. us05web.zoom.us/j/...)
        Matcher noScheme = NO_SCHEME_PATTERN.matcher(text);
        if (noScheme.find()) {
            String u = noScheme.group().trim().replaceAll("[.,;)>]+$", "");
            return "https://" + u;
        }

        // Single domain-like string without spaces
        if (!text.contains(" ") && text.contains(".") && text.indexOf('.') < text.length() - 2) {
            if (!text.startsWith("http://") && !text.startsWith("https://")) {
                return "https://" + text;
            }
            return text;
        }

        return null;
    }

    public String updateMeetingLink(int classId, int tutorId, String meetingLink) throws SQLException {
        Class existing = classDAO.findById(classId);
        if (existing == null) {
            return "Class not found.";
        }
        if (existing.getTutorId() == null || existing.getTutorId() != tutorId) {
            return "You are not authorized to manage the meeting link for this class.";
        }

        String rawInput = (meetingLink != null) ? meetingLink.trim() : "";
        String cleanedLink = null;
        if (!rawInput.isEmpty()) {
            cleanedLink = extractAndNormalizeMeetingLink(rawInput);
            if (cleanedLink == null || cleanedLink.isBlank()) {
                return "Please enter a valid Zoom, Google Meet, or online class link.";
            }
            if (cleanedLink.length() > 500) {
                return "Meeting link URL is too long (maximum 500 characters).";
            }
        }

        boolean ok = classDAO.updateMeetingLink(classId, tutorId, cleanedLink);
        if (!ok) {
            return "Failed to update the meeting link. Please try again.";
        }
        return null;
    }

    public static String formatBatchWithSchedule(String batch, String classType) {
        if (batch == null || batch.isBlank()) {
            return batch;
        }
        String trimmed = batch.trim();
        String normalizedType = "WEEKEND".equalsIgnoreCase(classType) ? "Weekend" : "Weekday";
        String lower = trimmed.toLowerCase();

        // If batch already has weekday or weekend specified, don't duplicate
        if (lower.contains("weekend") || lower.contains("weekday")) {
            return trimmed;
        }

        return trimmed + " (" + normalizedType + ")";
    }

    private String normalizeClassType(String classType) {
        if (classType != null && "WEEKEND".equalsIgnoreCase(classType.trim())) {
            return "WEEKEND";
        }
        return "WEEKDAY";
    }

    private String validateCommon(String subject, String batch, String feeRaw) {
        if (subject == null || subject.isBlank()) {
            return "Subject is required.";
        }

        if (subject.length() > 100) {
            return "Subject is too long.";
        }

        if (batch == null || batch.isBlank()) {
            return "Batch is required.";
        }

        if (batch.length() > 50) {
            return "Batch is too long.";
        }

        if (feeRaw == null || feeRaw.isBlank()) {
            return "Fee is required.";
        }

        try {
            BigDecimal fee = new BigDecimal(feeRaw.trim());
            if (fee.compareTo(BigDecimal.ZERO) < 0) {
                return "Fee cannot be negative.";
            }
        } catch (NumberFormatException e) {
            return "Fee must be a valid number.";
        }

        return null;
    }

    private Integer parseTutorId(String tutorIdRaw) {
        if (tutorIdRaw == null || tutorIdRaw.isBlank()) {
            return null;
        }

        try {
            return Integer.parseInt(tutorIdRaw.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}