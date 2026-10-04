package model;

import java.sql.Timestamp;

public class ClassMaterial {

    private int materialId;
    private int classId;
    private String title;
    private String description;
    private String filePath;
    private Timestamp uploadedAt;

    public ClassMaterial() {
    }

    public ClassMaterial(int classId, String title, String description, String filePath) {
        this.classId = classId;
        this.title = title;
        this.description = description;
        this.filePath = filePath;
    }

    public int getMaterialId() {
        return materialId;
    }

    public void setMaterialId(int materialId) {
        this.materialId = materialId;
    }

    public int getClassId() {
        return classId;
    }

    public void setClassId(int classId) {
        this.classId = classId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getFilePath() {
        return filePath;
    }

    public void setFilePath(String filePath) {
        this.filePath = filePath;
    }

    public Timestamp getUploadedAt() {
        return uploadedAt;
    }

    public void setUploadedAt(Timestamp uploadedAt) {
        this.uploadedAt = uploadedAt;
    }
}