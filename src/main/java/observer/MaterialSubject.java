package observer;

import model.ClassMaterial;

/**
 * Subject Interface (Observer Pattern).
 * Defines the contract for attaching, detaching, and notifying
 * observers about new ClassMaterial upload events.
 */
public interface MaterialSubject {

    /**
     * Attaches an observer to this subject.
     *
     * @param observer the observer to register
     */
    void addObserver(MaterialObserver observer);

    /**
     * Detaches an observer from this subject.
     *
     * @param observer the observer to remove
     */
    void removeObserver(MaterialObserver observer);

    /**
     * Notifies all registered observers about a newly uploaded material.
     *
     * @param material the newly persisted ClassMaterial object
     */
    void notifyObservers(ClassMaterial material);
}
