package service;

import dao.ClassDAO;
import dao.TimetableDAO;
import model.Class;
import model.TimetableSlot;

import java.sql.SQLException;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Locale;
import java.util.Set;

public class TimetableService {

    private final TimetableDAO timetableDAO = new TimetableDAO();
    private final ClassDAO classDAO = new ClassDAO();
    private final NotificationService notificationService = new NotificationService();

    private static final Set<String> VALID_DAYS =
            Set.of("MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN");

    private static final DateTimeFormatter FORMATTER_24H =
            DateTimeFormatter.ofPattern("HH:mm");

    private static final DateTimeFormatter FORMATTER_FLEXIBLE =
            new DateTimeFormatterBuilder()
                    .parseCaseInsensitive()
                    .appendPattern("[h:m a][hh:mm a][h:mm a][H:m][HH:mm]")
                    .toFormatter(Locale.ENGLISH);

    private static final DateTimeFormatter DISPLAY_12H =
            DateTimeFormatter.ofPattern("hh:mm a", Locale.ENGLISH);

    /**
     * Returns an error message, or null if the slot was created successfully.
     * Rejects the slot if it clashes with another ACTIVE slot for the same tutor.
     * Synchronized to prevent duplicate slot creation from rapid double-clicks.
     */
    public synchronized String createSlot(int classId, int tutorId, String dayOfWeek,
                                          String startTime, String endTime, String room) throws SQLException {

        if (dayOfWeek == null || !VALID_DAYS.contains(dayOfWeek.trim().toUpperCase())) {
            return "Please select a valid day of the week.";
        }

        String normalizedDay = dayOfWeek.trim().toUpperCase();

        Class classItem = classDAO.findById(classId);
        if (classItem != null) {
            boolean isWeekendClass = classItem.isWeekend();
            boolean isWeekendDay = "SAT".equals(normalizedDay) || "SUN".equals(normalizedDay);

            if (isWeekendClass && !isWeekendDay) {
                return "Cannot schedule on " + normalizedDay + ". '" + classItem.getSubject() + " - " + classItem.getBatch()
                        + "' is a Weekend class and can only be scheduled on Saturday or Sunday.";
            }

            if (!isWeekendClass && isWeekendDay) {
                return "Cannot schedule on " + normalizedDay + ". '" + classItem.getSubject() + " - " + classItem.getBatch()
                        + "' is a Weekday class and can only be scheduled on Monday through Friday.";
            }
        }

        LocalTime parsedStart = parseTime(startTime);
        if (parsedStart == null) {
            return "Please enter a valid start time (e.g. 09:00 AM or 13:00).";
        }

        LocalTime parsedEnd = parseTime(endTime);
        if (parsedEnd == null) {
            return "Please enter a valid end time (e.g. 11:00 AM or 17:00).";
        }

        if (!parsedEnd.isAfter(parsedStart)) {
            String start12 = parsedStart.format(DISPLAY_12H);
            String end12 = parsedEnd.format(DISPLAY_12H);

            if (parsedStart.getHour() >= 12 && parsedEnd.getHour() < 12) {
                return "End time (" + end12 + ") is earlier than Start time (" + start12
                        + "). Did you forget to set PM for the end time?";
            }

            return "End time (" + end12 + ") must be after start time (" + start12 + ").";
        }

        String normalizedStart = parsedStart.format(FORMATTER_24H);
        String normalizedEnd = parsedEnd.format(FORMATTER_24H);

        List<TimetableSlot> conflicts =
                timetableDAO.findOverlapping(tutorId, normalizedDay, normalizedStart, normalizedEnd, -1);

        if (!conflicts.isEmpty()) {
            TimetableSlot conflict = conflicts.get(0);
            return "Tutor already has a class (" + conflict.getSubject() + " - " + conflict.getBatch()
                    + ") from " + conflict.getStartTime() + " to " + conflict.getEndTime()
                    + " on " + conflict.getDayOfWeek() + ".";
        }

        TimetableSlot slot = new TimetableSlot();
        slot.setClassId(classId);
        slot.setTutorId(tutorId);
        slot.setDayOfWeek(normalizedDay);
        slot.setStartTime(normalizedStart);
        slot.setEndTime(normalizedEnd);
        slot.setRoom(room != null ? room.trim() : null);

        int id = timetableDAO.createSlot(slot);

        if (id <= 0) {
            return "Failed to create the timetable slot. Please try again.";
        }

        // Notify the assigned tutor in-app
        try {
            String className = classItem != null ? classItem.getSubject() + " - " + classItem.getBatch() : "Class #" + classId;
            notificationService.notifyUser(
                    tutorId,
                    "New Timetable Slot Assigned",
                    "You have been assigned to teach " + className + " on " + normalizedDay + " (" + normalizedStart + " - " + normalizedEnd + "). Please review and confirm or suggest another time.",
                    "TIMETABLE",
                    classId,
                    null
            );
        } catch (Exception e) {
            System.err.println("Failed to send slot notification: " + e.getMessage());
        }

        return null;
    }

    /**
     * Tutor confirms the assigned timetable slot.
     */
    public String confirmSlotByTutor(int slotId, int tutorId) throws SQLException {
        TimetableSlot slot = timetableDAO.findById(slotId);
        if (slot == null) {
            return "Timetable slot not found.";
        }
        if (slot.getTutorId() != tutorId) {
            return "You are not authorized to confirm this slot.";
        }

        boolean success = timetableDAO.confirmSlot(slotId, tutorId);
        if (!success) {
            return "Failed to confirm timetable slot. Please try again.";
        }

        // Send in-app notification to institute administrators
        try {
            notificationService.notifyAdmins(
                    "Timetable Slot Confirmed",
                    "Tutor " + slot.getTutorName() + " confirmed schedule for " + slot.getSubject() + " - " + slot.getBatch() + " on " + slot.getDayOfWeek() + " (" + slot.getStartTime() + " - " + slot.getEndTime() + ").",
                    "TIMETABLE",
                    slot.getClassId()
            );
        } catch (Exception e) {
            System.err.println("Failed to notify admins of slot confirmation: " + e.getMessage());
        }

        return null;
    }

    /**
     * Tutor suggests an alternative time slot to the admin.
     */
    public String suggestAlternativeTime(int slotId, int tutorId, String dayOfWeek,
                                         String startTime, String endTime, String note) throws SQLException {
        TimetableSlot slot = timetableDAO.findById(slotId);
        if (slot == null) {
            return "Timetable slot not found.";
        }
        if (slot.getTutorId() != tutorId) {
            return "You are not authorized to manage this slot.";
        }

        if (dayOfWeek == null || !VALID_DAYS.contains(dayOfWeek.trim().toUpperCase())) {
            return "Please select a valid day of the week.";
        }

        String normalizedDay = dayOfWeek.trim().toUpperCase();

        Class classItem = classDAO.findById(slot.getClassId());
        if (classItem != null) {
            boolean isWeekendClass = classItem.isWeekend();
            boolean isWeekendDay = "SAT".equals(normalizedDay) || "SUN".equals(normalizedDay);

            if (isWeekendClass && !isWeekendDay) {
                return "Cannot suggest " + normalizedDay + ". This is a Weekend class and can only be held on Saturday or Sunday.";
            }
            if (!isWeekendClass && isWeekendDay) {
                return "Cannot suggest " + normalizedDay + ". This is a Weekday class and can only be held on Monday through Friday.";
            }
        }

        LocalTime parsedStart = parseTime(startTime);
        if (parsedStart == null) {
            return "Please enter a valid start time.";
        }

        LocalTime parsedEnd = parseTime(endTime);
        if (parsedEnd == null) {
            return "Please enter a valid end time.";
        }

        if (!parsedEnd.isAfter(parsedStart)) {
            return "Suggested end time must be after start time.";
        }

        String normalizedStart = parsedStart.format(FORMATTER_24H);
        String normalizedEnd = parsedEnd.format(FORMATTER_24H);

        // Check if tutor has a clash at their own proposed alternative time
        List<TimetableSlot> conflicts =
                timetableDAO.findOverlapping(tutorId, normalizedDay, normalizedStart, normalizedEnd, slotId);
        if (!conflicts.isEmpty()) {
            TimetableSlot c = conflicts.get(0);
            return "Your suggested time clashes with another class: " + c.getSubject() + " - " + c.getBatch()
                    + " (" + c.getStartTime() + " - " + c.getEndTime() + " on " + c.getDayOfWeek() + ").";
        }

        boolean success = timetableDAO.suggestAlternativeTime(
                slotId, tutorId, normalizedDay, normalizedStart, normalizedEnd, note != null ? note.trim() : null
        );

        if (!success) {
            return "Failed to submit alternative time suggestion. Please try again.";
        }

        // Notify Admins about the suggestion
        try {
            String noteSnippet = (note != null && !note.isBlank()) ? " Note: \"" + note.trim() + "\"" : "";
            notificationService.notifyAdmins(
                    "Alternative Timetable Suggestion",
                    "Tutor " + slot.getTutorName() + " suggested alternative time for " + slot.getSubject() + " - " + slot.getBatch() + ": " + normalizedDay + " (" + normalizedStart + " - " + normalizedEnd + ")." + noteSnippet,
                    "TIMETABLE",
                    slot.getClassId()
            );
        } catch (Exception e) {
            System.err.println("Failed to notify admins of time suggestion: " + e.getMessage());
        }

        return null;
    }

    /**
     * Admin accepts the tutor's suggested alternative time.
     */
    public String acceptSuggestionByAdmin(int slotId) throws SQLException {
        TimetableSlot slot = timetableDAO.findById(slotId);
        if (slot == null) {
            return "Timetable slot not found.";
        }
        if (!slot.isChangeSuggested() || slot.getSuggestedDay() == null || slot.getSuggestedStartTime() == null) {
            return "There is no pending alternative time suggestion for this slot.";
        }

        // Verify no conflicts at the suggested time before accepting
        List<TimetableSlot> conflicts = timetableDAO.findOverlapping(
                slot.getTutorId(),
                slot.getSuggestedDay(),
                slot.getSuggestedStartTime(),
                slot.getSuggestedEndTime(),
                slotId
        );
        if (!conflicts.isEmpty()) {
            TimetableSlot c = conflicts.get(0);
            return "Cannot accept suggestion: clashes with " + c.getSubject() + " - " + c.getBatch()
                    + " (" + c.getStartTime() + " - " + c.getEndTime() + ").";
        }

        boolean success = timetableDAO.acceptSuggestion(slotId);
        if (!success) {
            return "Failed to accept suggestion. Please try again.";
        }

        // Notify the tutor that their suggestion was approved
        try {
            notificationService.notifyUser(
                    slot.getTutorId(),
                    "Suggested Schedule Approved",
                    "Your suggested time for " + slot.getSubject() + " - " + slot.getBatch() + " (" + slot.getSuggestedDay() + " " + slot.getSuggestedStartTime() + " - " + slot.getSuggestedEndTime() + ") has been approved and confirmed by the administrator.",
                    "TIMETABLE",
                    slot.getClassId(),
                    null
            );
        } catch (Exception e) {
            System.err.println("Failed to notify tutor of accepted suggestion: " + e.getMessage());
        }

        return null;
    }

    public TimetableSlot findById(int slotId) throws SQLException {
        return timetableDAO.findById(slotId);
    }

    public boolean cancelSlot(int slotId) throws SQLException {
        return timetableDAO.cancelSlot(slotId);
    }

    public List<TimetableSlot> findAll() throws SQLException {
        return timetableDAO.findAll();
    }

    public List<TimetableSlot> findByTutor(int tutorId) throws SQLException {
        return timetableDAO.findByTutor(tutorId);
    }

    public List<TimetableSlot> findByClass(int classId) throws SQLException {
        return timetableDAO.findByClass(classId);
    }

    private LocalTime parseTime(String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return null;
        }

        String trimmed = raw.trim().replaceAll("\\s+", " ");

        // Try strict 24-hour format (HH:mm)
        try {
            return LocalTime.parse(trimmed, FORMATTER_24H);
        } catch (DateTimeParseException ignored) {
        }

        // Try 12-hour AM/PM and other flexible patterns
        try {
            return LocalTime.parse(trimmed, FORMATTER_FLEXIBLE);
        } catch (DateTimeParseException ignored) {
        }

        return null;
    }
}