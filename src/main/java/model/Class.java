package model;

import java.math.BigDecimal;

public class Class {
    private int classId;
    private String subject;
    private String batch;
    private Integer tutorId;
    private String tutorName;
    private BigDecimal fee;
    private String status;
    private String imagePath;
    private String classType = "WEEKDAY";
    private String meetingLink;

    public Class() {}

    public Class(String subject, String batch, Integer tutorId, BigDecimal fee) {
        this(subject, batch, tutorId, fee, null, "WEEKDAY");
    }

    public Class(String subject, String batch, Integer tutorId, BigDecimal fee, String imagePath) {
        this(subject, batch, tutorId, fee, imagePath, "WEEKDAY");
    }

    public Class(String subject, String batch, Integer tutorId, BigDecimal fee, String imagePath, String classType) {
        this.subject = subject;
        this.batch = batch;
        this.tutorId = tutorId;
        this.fee = fee;
        this.imagePath = imagePath;
        this.classType = (classType != null && !classType.isBlank()) ? classType.trim().toUpperCase() : "WEEKDAY";
        this.status = "ACTIVE";
    }

    public int getClassId() { return classId; }
    public void setClassId(int classId) { this.classId = classId; }
    public String getSubject() { return subject; }
    public void setSubject(String subject) { this.subject = subject; }
    public String getBatch() { return batch; }
    public void setBatch(String batch) { this.batch = batch; }
    public Integer getTutorId() { return tutorId; }
    public void setTutorId(Integer tutorId) { this.tutorId = tutorId; }
    public String getTutorName() { return tutorName; }
    public void setTutorName(String tutorName) { this.tutorName = tutorName; }
    public BigDecimal getFee() { return fee; }
    public void setFee(BigDecimal fee) { this.fee = fee; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getImagePath() { return imagePath; }
    public void setImagePath(String imagePath) { this.imagePath = imagePath; }
    public String getClassType() { return classType != null ? classType : "WEEKDAY"; }
    public void setClassType(String classType) {
        this.classType = (classType != null && !classType.isBlank()) ? classType.trim().toUpperCase() : "WEEKDAY";
    }
    public String getClassTypeDisplay() {
        return "WEEKEND".equalsIgnoreCase(classType) ? "Weekend" : "Weekday";
    }
    public boolean isWeekend() {
        return "WEEKEND".equalsIgnoreCase(classType);
    }
    public boolean isWeekday() {
        return !isWeekend();
    }
    public String getMeetingLink() {
        return service.ClassService.extractAndNormalizeMeetingLink(meetingLink);
    }
    public void setMeetingLink(String meetingLink) { this.meetingLink = meetingLink; }
    public boolean hasMeetingLink() {
        String cleaned = getMeetingLink();
        return cleaned != null && !cleaned.isBlank();
    }
}
