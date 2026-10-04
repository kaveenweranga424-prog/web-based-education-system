package observer;

import model.ClassMaterial;

/**
 * Observer Interface (Observer Pattern).
 * Defines the update contract for observers that need to react
 * when a new class study material is uploaded by a tutor.
 */
public interface MaterialObserver {

    /**
     * Called by a MaterialSubject when a new ClassMaterial has been
     * successfully created and saved in the database.
     *
     * @param material the newly persisted ClassMaterial object
     */
    void update(ClassMaterial material);
}
