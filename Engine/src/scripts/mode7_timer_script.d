module scripts.mode7_timer_script;

import std.stdio;
import std.file : exists, write;
import std.json : JSONValue;
import bindbc.sdl;
import scripts.base_script;
import gameobject;

class Mode7TimerScript : BaseScript {
    private {
        bool isInitialized = false;
        bool mode7Enabled = false;
        uint startTime;
        uint timerDuration = 5_000;  // 5 seconds in milliseconds
        string nextSceneName = "alienscene";  // Scene to load after timer
    }

    this(GameObject* gameObject) {
        super(gameObject);
    }

    override void Update() {
        // Initialize on first update
        if (!isInitialized) {
            enableMode7();
            startTime = SDL_GetTicks();
            isInitialized = true;
            mode7Enabled = true;
        }

        // Check timer if mode7 is enabled
        if (mode7Enabled) {
            uint currentTime = SDL_GetTicks();
            uint elapsedTime = currentTime - startTime;
            
            // Debug output remaining time every second
            if (elapsedTime % 1000 < 16) {  // Print roughly once per second
                writefln("Mode7 time remaining: %d seconds", (timerDuration - elapsedTime) / 1000);
            }

            // Check if timer is complete
            if (elapsedTime >= timerDuration) {
                disableMode7();
                loadNextScene();
                mode7Enabled = false;
            }
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

            writeln("Mode7 enabled! Timer started.");
        } catch (Exception e) {
            writefln("Failed to enable Mode7: %s", e.msg);
        }
    }

    private void disableMode7() {
        try {
            // Create the mode_switch.json file with mode7 disabled
            auto jsonData = JSONValue([
                "mode7": JSONValue(false)
            ]);
            write("mode_switch.json", jsonData.toString());

            // Create the mode_switch.flag file
            write("mode_switch.flag", "1");

            writeln("Mode7 disabled!");
        } catch (Exception e) {
            writefln("Failed to disable Mode7: %s", e.msg);
        }
    }

    private void loadNextScene() {
        try {
            // Create the load_scene.json file with the target scene name and path
            auto jsonData = JSONValue([
                "sceneName": JSONValue(nextSceneName),
                "path": JSONValue("./saves/" ~ nextSceneName ~ ".json")
            ]);
            write("load_scene.json", jsonData.toString());

            // Create the load_scene.flag file
            write("load_scene.flag", "1");

            writefln("Loading next scene: %s", nextSceneName);
        } catch (Exception e) {
            writefln("Failed to load next scene '%s': %s", nextSceneName, e.msg);
        }
    }

    // Optional: Method to set the next scene name
    public void setNextScene(string sceneName) {
        nextSceneName = sceneName;
    }
} 