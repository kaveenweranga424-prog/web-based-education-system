package service;

import dao.ClassMaterialDAO;
import model.ClassMaterial;
import observer.MaterialObserver;
import observer.MaterialSubject;
import observer.StudentMaterialObserver;

import java.sql.SQLException;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * Concrete Subject in the Observer Design Pattern.
 * Manages ClassMaterial CRUD operations and notifies registered observers
 * whenever a new study material is successfully uploaded.
 */
public class ClassMaterialService implements MaterialSubject {

    private final ClassMaterialDAO materialDAO;
    private final List<MaterialObserver> observers = new CopyOnWriteArrayList<>();

    public ClassMaterialService() {
        this(new ClassMaterialDAO());
    }

    public ClassMaterialService(ClassMaterialDAO materialDAO) {
        this.materialDAO = materialDAO;
        // Register default observer for student notifications
        addObserver(new StudentMaterialObserver());
    }

    public ClassMaterialService(ClassMaterialDAO materialDAO, List<MaterialObserver> initialObservers) {
        this.materialDAO = materialDAO;
        if (initialObservers != null) {
            for (MaterialObserver o : initialObservers) {
                addObserver(o);
            }
        }
    }

    @Override
    public void addObserver(MaterialObserver observer) {
        if (observer != null && !observers.contains(observer)) {
            observers.add(observer);
        }
    }

    @Override
    public void removeObserver(MaterialObserver observer) {
        if (observer != null) {
            observers.remove(observer);
        }
    }

    @Override
    public void notifyObservers(ClassMaterial material) {
        if (material == null) {
            return;
        }
        for (MaterialObserver observer : observers) {
            try {
                observer.update(material);
            } catch (Exception e) {
                System.err.println("[ClassMaterialService] Error notifying observer "
                        + observer.getClass().getSimpleName() + ": " + e.getMessage());
                e.printStackTrace();
            }
        }
    }

    public List<MaterialObserver> getObservers() {
        return Collections.unmodifiableList(observers);
    }

    /**
     * Uploads and saves a new class material.
     * Triggers notifyObservers(m) ONLY if the material is successfully saved in the database.
     *
     * @return null on success, or an error message string on failure.
     */
    public String addMaterial(int classId, String title, String description, String filePath) throws SQLException {
        if (title == null || title.isBlank()) return "Material title is required.";
        if (filePath == null || filePath.isBlank()) return "A file is required.";

        ClassMaterial m = new ClassMaterial(classId, title.trim(), description, filePath);
        int generatedId = materialDAO.addMaterial(m);

        if (generatedId > 0) {
            m.setMaterialId(generatedId);
            // ONLY if saving succeeds, notify registered observers
            notifyObservers(m);
            return null;
        }
        return "Failed to upload the material.";
    }

    public MaterialMutationResult updateMaterial(int materialId, int classId, String title, String description, String replacementPath) throws SQLException {
        if (title == null || title.isBlank()) return new MaterialMutationResult("Material title is required.", null, null);
        ClassMaterial m = materialDAO.findById(materialId);
        if (m == null || m.getClassId() != classId) return new MaterialMutationResult("Material was not found for this class.", null, null);
        String old = m.getFilePath();
        m.setTitle(title.trim());
        m.setDescription(description);
        if (replacementPath != null && !replacementPath.isBlank()) m.setFilePath(replacementPath);
        if (!materialDAO.updateMaterial(m)) return new MaterialMutationResult("Failed to update the material.", null, null);
        return new MaterialMutationResult(null, (replacementPath != null && !replacementPath.isBlank()) ? old : null, m);
    }

    public MaterialMutationResult deleteMaterial(int materialId, int classId) throws SQLException {
        ClassMaterial m = materialDAO.findById(materialId);
        if (m == null || m.getClassId() != classId) return new MaterialMutationResult("Material was not found for this class.", null, null);
        if (!materialDAO.deleteMaterial(materialId)) return new MaterialMutationResult("Failed to delete the material.", null, null);
        return new MaterialMutationResult(null, m.getFilePath(), m);
    }

    public ClassMaterial findById(int id) throws SQLException {
        return materialDAO.findById(id);
    }

    public List<ClassMaterial> findByClass(int classId) throws SQLException {
        return materialDAO.findByClass(classId);
    }

    public record MaterialMutationResult(String error, String oldManagedFilePath, ClassMaterial material) {}
}
