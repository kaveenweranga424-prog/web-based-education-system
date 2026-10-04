package dao;

import model.TimetableSlot;
import util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class TimetableDAO {

    public int createSlot(TimetableSlot slot) throws SQLException {
        String sql = """
                INSERT INTO dbo.timetable_slots
                (class_id, tutor_id, day_of_week, start_time, end_time, room, status, confirmation_status)
                VALUES (?, ?, ?, ?, ?, ?, 'ACTIVE', 'PENDING')
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement =
                     connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            statement.setInt(1, slot.getClassId());
            statement.setInt(2, slot.getTutorId());
            statement.setString(3, slot.getDayOfWeek());
            statement.setString(4, slot.getStartTime());
            statement.setString(5, slot.getEndTime());
            statement.setString(6, slot.getRoom());

            int rows = statement.executeUpdate();

            if (rows > 0) {
                try (ResultSet keys = statement.getGeneratedKeys()) {
                    if (keys.next()) {
                        return keys.getInt(1);
                    }
                }
            }
        }

        return -1;
    }

    public boolean cancelSlot(int slotId) throws SQLException {
        String sql = "UPDATE dbo.timetable_slots SET status = 'CANCELLED' WHERE slot_id = ?";

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, slotId);
            return statement.executeUpdate() > 0;
        }
    }

    public TimetableSlot findById(int slotId) throws SQLException {
        String sql = """
                SELECT s.slot_id, s.class_id, s.tutor_id, s.day_of_week,
                       s.start_time, s.end_time, s.room, s.status,
                       s.confirmation_status, s.suggested_day, s.suggested_start_time,
                       s.suggested_end_time, s.tutor_note, s.responded_at,
                       c.subject, c.batch,
                       u.first_name, u.last_name
                FROM dbo.timetable_slots s
                JOIN dbo.classes c ON c.class_id = s.class_id
                JOIN dbo.users u ON u.user_id = s.tutor_id
                WHERE s.slot_id = ?
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, slotId);

            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return mapSlot(resultSet);
                }
            }
        }
        return null;
    }

    /**
     * Confirms the assigned slot by the tutor.
     */
    public boolean confirmSlot(int slotId, int tutorId) throws SQLException {
        String sql = """
                UPDATE dbo.timetable_slots
                SET confirmation_status = 'CONFIRMED',
                    responded_at = GETDATE()
                WHERE slot_id = ? AND tutor_id = ? AND status = 'ACTIVE'
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, slotId);
            statement.setInt(2, tutorId);
            return statement.executeUpdate() > 0;
        }
    }

    /**
     * Submits an alternative time suggestion from the tutor to the administrator.
     */
    public boolean suggestAlternativeTime(int slotId, int tutorId, String day,
                                          String startTime, String endTime, String note) throws SQLException {
        String sql = """
                UPDATE dbo.timetable_slots
                SET confirmation_status = 'CHANGE_SUGGESTED',
                    suggested_day = ?,
                    suggested_start_time = ?,
                    suggested_end_time = ?,
                    tutor_note = ?,
                    responded_at = GETDATE()
                WHERE slot_id = ? AND tutor_id = ? AND status = 'ACTIVE'
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setString(1, day);
            statement.setString(2, startTime);
            statement.setString(3, endTime);
            statement.setString(4, note);
            statement.setInt(5, slotId);
            statement.setInt(6, tutorId);
            return statement.executeUpdate() > 0;
        }
    }

    /**
     * Admin accepts the tutor's suggested alternative time.
     * Updates the slot's actual day, start_time, end_time to the suggested values,
     * and sets confirmation_status to 'CONFIRMED'.
     */
    public boolean acceptSuggestion(int slotId) throws SQLException {
        String sql = """
                UPDATE dbo.timetable_slots
                SET day_of_week = suggested_day,
                    start_time = suggested_start_time,
                    end_time = suggested_end_time,
                    confirmation_status = 'CONFIRMED',
                    responded_at = GETDATE()
                WHERE slot_id = ?
                  AND confirmation_status = 'CHANGE_SUGGESTED'
                  AND suggested_day IS NOT NULL
                  AND suggested_start_time IS NOT NULL
                  AND suggested_end_time IS NOT NULL
                """;

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, slotId);
            return statement.executeUpdate() > 0;
        }
    }

    /**
     * Finds ACTIVE slots for a tutor on a given day whose time range
     * overlaps [startTime, endTime). Used for conflict checking.
     * excludeSlotId can be -1 when creating a new slot (nothing to exclude).
     */
    public List<TimetableSlot> findOverlapping(int tutorId, String dayOfWeek,
                                                String startTime, String endTime,
                                                int excludeSlotId) throws SQLException {

        String sql = """
                SELECT s.slot_id, s.class_id, s.tutor_id, s.day_of_week,
                       s.start_time, s.end_time, s.room, s.status,
                       s.confirmation_status, s.suggested_day, s.suggested_start_time,
                       s.suggested_end_time, s.tutor_note, s.responded_at,
                       c.subject, c.batch,
                       u.first_name, u.last_name
                FROM dbo.timetable_slots s
                JOIN dbo.classes c ON c.class_id = s.class_id
                JOIN dbo.users u ON u.user_id = s.tutor_id
                WHERE s.tutor_id = ?
                  AND s.day_of_week = ?
                  AND s.status = 'ACTIVE'
                  AND s.slot_id <> ?
                  AND s.start_time < ?
                  AND s.end_time > ?
                """;

        List<TimetableSlot> slots = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, tutorId);
            statement.setString(2, dayOfWeek);
            statement.setInt(3, excludeSlotId);
            statement.setString(4, endTime);   // existing.start_time < new.end_time
            statement.setString(5, startTime); // existing.end_time   > new.start_time

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    slots.add(mapSlot(resultSet));
                }
            }
        }

        return slots;
    }

    public List<TimetableSlot> findAll() throws SQLException {
        String sql = """
                SELECT s.slot_id, s.class_id, s.tutor_id, s.day_of_week,
                       s.start_time, s.end_time, s.room, s.status,
                       s.confirmation_status, s.suggested_day, s.suggested_start_time,
                       s.suggested_end_time, s.tutor_note, s.responded_at,
                       c.subject, c.batch,
                       u.first_name, u.last_name
                FROM dbo.timetable_slots s
                JOIN dbo.classes c ON c.class_id = s.class_id
                JOIN dbo.users u ON u.user_id = s.tutor_id
                WHERE s.status = 'ACTIVE'
                ORDER BY
                    CASE s.day_of_week
                        WHEN 'MON' THEN 1 WHEN 'TUE' THEN 2 WHEN 'WED' THEN 3
                        WHEN 'THU' THEN 4 WHEN 'FRI' THEN 5 WHEN 'SAT' THEN 6
                        WHEN 'SUN' THEN 7 END,
                    s.start_time
                """;

        List<TimetableSlot> slots = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             Statement statement = connection.createStatement();
             ResultSet resultSet = statement.executeQuery(sql)) {

            while (resultSet.next()) {
                slots.add(mapSlot(resultSet));
            }
        }

        return slots;
    }

    public List<TimetableSlot> findByTutor(int tutorId) throws SQLException {
        String sql = """
                SELECT s.slot_id, s.class_id, s.tutor_id, s.day_of_week,
                       s.start_time, s.end_time, s.room, s.status,
                       s.confirmation_status, s.suggested_day, s.suggested_start_time,
                       s.suggested_end_time, s.tutor_note, s.responded_at,
                       c.subject, c.batch,
                       u.first_name, u.last_name
                FROM dbo.timetable_slots s
                JOIN dbo.classes c ON c.class_id = s.class_id
                JOIN dbo.users u ON u.user_id = s.tutor_id
                WHERE s.tutor_id = ? AND s.status = 'ACTIVE'
                ORDER BY
                    CASE s.day_of_week
                        WHEN 'MON' THEN 1 WHEN 'TUE' THEN 2 WHEN 'WED' THEN 3
                        WHEN 'THU' THEN 4 WHEN 'FRI' THEN 5 WHEN 'SAT' THEN 6
                        WHEN 'SUN' THEN 7 END,
                    s.start_time
                """;

        List<TimetableSlot> slots = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, tutorId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    slots.add(mapSlot(resultSet));
                }
            }
        }

        return slots;
    }

    public List<TimetableSlot> findByClass(int classId) throws SQLException {
        String sql = """
                SELECT s.slot_id, s.class_id, s.tutor_id, s.day_of_week,
                       s.start_time, s.end_time, s.room, s.status,
                       s.confirmation_status, s.suggested_day, s.suggested_start_time,
                       s.suggested_end_time, s.tutor_note, s.responded_at,
                       c.subject, c.batch,
                       u.first_name, u.last_name
                FROM dbo.timetable_slots s
                JOIN dbo.classes c ON c.class_id = s.class_id
                JOIN dbo.users u ON u.user_id = s.tutor_id
                WHERE s.class_id = ? AND s.status = 'ACTIVE'
                ORDER BY
                    CASE s.day_of_week
                        WHEN 'MON' THEN 1 WHEN 'TUE' THEN 2 WHEN 'WED' THEN 3
                        WHEN 'THU' THEN 4 WHEN 'FRI' THEN 5 WHEN 'SAT' THEN 6
                        WHEN 'SUN' THEN 7 END,
                    s.start_time
                """;

        List<TimetableSlot> slots = new ArrayList<>();

        try (Connection connection = DBUtil.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setInt(1, classId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    slots.add(mapSlot(resultSet));
                }
            }
        }

        return slots;
    }

    private TimetableSlot mapSlot(ResultSet resultSet) throws SQLException {
        TimetableSlot slot = new TimetableSlot();
        slot.setSlotId(resultSet.getInt("slot_id"));
        slot.setClassId(resultSet.getInt("class_id"));
        slot.setTutorId(resultSet.getInt("tutor_id"));
        slot.setDayOfWeek(resultSet.getString("day_of_week"));
        slot.setStartTime(resultSet.getString("start_time"));
        slot.setEndTime(resultSet.getString("end_time"));
        slot.setRoom(resultSet.getString("room"));
        slot.setStatus(resultSet.getString("status"));
        slot.setSubject(resultSet.getString("subject"));
        slot.setBatch(resultSet.getString("batch"));
        slot.setTutorName(resultSet.getString("first_name") + " " + resultSet.getString("last_name"));

        try {
            String conf = resultSet.getString("confirmation_status");
            slot.setConfirmationStatus(conf != null ? conf : "CONFIRMED");
            slot.setSuggestedDay(resultSet.getString("suggested_day"));
            slot.setSuggestedStartTime(resultSet.getString("suggested_start_time"));
            slot.setSuggestedEndTime(resultSet.getString("suggested_end_time"));
            slot.setTutorNote(resultSet.getString("tutor_note"));
            Object respAt = resultSet.getObject("responded_at");
            slot.setRespondedAt(respAt != null ? String.valueOf(respAt) : null);
        } catch (SQLException ignored) {
            // Columns might not exist yet before migration runs
            slot.setConfirmationStatus("CONFIRMED");
        }

        return slot;
    }
}