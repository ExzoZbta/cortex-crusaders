module scripts.mode7_enabler_script;

import std.stdio;
import std.file : exists, write;
import std.json : JSONValue;
import bindbc.sdl;
import scripts.base_script;
import gameobject;

class Mode7EnablerScript : BaseScript {
    private {
        bool isInitialized = false;
    }

    this(GameObject* gameObject) {
        super(gameObject);
    }

    override void Update() {
        // Only run once when the script first loads
        if (!isInitialized) {
            enableMode7();
            isInitialized = true;
        }
    }

    private void enableMode7() {
        try {
            // Create the mode_switch.json file with the correct key
            auto jsonData = JSONValue([
                "mode7": JSONValue(true)
            ]);
            write("mode_switch.json", jsonData.toString());

            // Create the mode_switch.flag file
            write("mode_switch.flag", "1");

            writeln("Mode7 enable request sent!");
        } catch (Exception e) {
            writefln("Failed to enable Mode7: %s", e.msg);
        }
    }
} 