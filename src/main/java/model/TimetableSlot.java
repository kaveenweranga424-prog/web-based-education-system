package model;

public class TimetableSlot {

    private int slotId;
    private int classId;
    private String subject; // joined
    private String batch;   // joined
    private int tutorId;
    private String tutorName; // joined
    private String dayOfWeek;
    private String startTime; // "HH:mm"
    private String endTime;   // "HH:mm"
    private String room;
    private String status;

    // Confirmation & Alternative Suggestion fields
    private String confirmationStatus = "PENDING"; // PENDING, CONFIRMED, CHANGE_SUGGESTED
    private String suggestedDay;
    private String suggestedStartTime;
    private String suggestedEndTime;
    private String tutorNote;
    private String respondedAt;

    public TimetableSlot() {
    }

    public int getSlotId() {
        return slotId;
    }

    public void setSlotId(int slotId) {
        this.slotId = slotId;
    }

    public int getClassId() {
        return classId;
    }

    public void setClassId(int classId) {
        this.classId = classId;
    }

    public String getSubject() {
        return subject;
    }

    public void setSubject(String subject) {
        this.subject = subject;
    }

    public String getBatch() {
        return batch;
    }

    public void setBatch(String batch) {
        this.batch = batch;
    }

    public int getTutorId() {
        return tutorId;
    }

    public void setTutorId(int tutorId) {
        this.tutorId = tutorId;
    }

    public String getTutorName() {
        return tutorName;
    }

    public void setTutorName(String tutorName) {
        this.tutorName = tutorName;
    }

    public String getDayOfWeek() {
        return dayOfWeek;
    }

    public void setDayOfWeek(String dayOfWeek) {
        this.dayOfWeek = dayOfWeek;
    }

    public String getStartTime() {
        return startTime;
    }

    public void setStartTime(String startTime) {
        this.startTime = startTime;
    }

    public String getEndTime() {
        return endTime;
    }

    public void setEndTime(String endTime) {
        this.endTime = endTime;
    }

    public String getRoom() {
        return room;
    }

    public void setRoom(String room) {
        this.room = room;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getConfirmationStatus() {
        return confirmationStatus;
    }

    public void setConfirmationStatus(String confirmationStatus) {
        this.confirmationStatus = confirmationStatus;
    }

    public String getSuggestedDay() {
        return suggestedDay;
    }

    public void setSuggestedDay(String suggestedDay) {
        this.suggestedDay = suggestedDay;
    }

    public String getSuggestedStartTime() {
        return suggestedStartTime;
    }

    public void setSuggestedStartTime(String suggestedStartTime) {
        this.suggestedStartTime = suggestedStartTime;
    }

    public String getSuggestedEndTime() {
        return suggestedEndTime;
    }

    public void setSuggestedEndTime(String suggestedEndTime) {
        this.suggestedEndTime = suggestedEndTime;
    }

    public String getTutorNote() {
        return tutorNote;
    }

    public void setTutorNote(String tutorNote) {
        this.tutorNote = tutorNote;
    }

    public String getRespondedAt() {
        return respondedAt;
    }

    public void setRespondedAt(String respondedAt) {
        this.respondedAt = respondedAt;
    }

    public boolean isPending() {
        return "PENDING".equalsIgnoreCase(confirmationStatus);
    }

    public boolean isConfirmed() {
        return "CONFIRMED".equalsIgnoreCase(confirmationStatus);
    }

    public boolean isChangeSuggested() {
        return "CHANGE_SUGGESTED".equalsIgnoreCase(confirmationStatus);
    }
}