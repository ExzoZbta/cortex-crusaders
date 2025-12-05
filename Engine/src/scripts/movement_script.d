module scripts.movement_script;

import std.stdio;
import scripts.base_script;
import gameobject;

class MovementScript : BaseScript {

    this(GameObject* gameObject) {
        super(gameObject);
    }

    override void Update() {
        this.owner.mX += 10;
        this.owner.mY += 10;
    }
} 