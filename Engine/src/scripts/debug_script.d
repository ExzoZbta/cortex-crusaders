module scripts.debug_script;

import std.stdio;
import scripts.base_script;
import gameobject;

class DebugScript : BaseScript {
    private int updateCount = 0;

    this(GameObject* gameObject) {
        super(gameObject);
    }

    override void Update() {
        updateCount++;
        writeln("DebugScript Update called: #");
    }
} 