module scripts.base_script;

import component;
import gameobject;

class BaseScript {
    protected GameObject* owner;

    this(GameObject* gameObject) {
        owner = gameObject;
    }

    void Update() {
        // Base implementation does nothing
    }

    float GetRotation() {
        return 0.0f;
    }
} 