module scripts.timer_transition_script;

import std.stdio;
import std.file : exists, write;
import std.json : JSONValue;
import bindbc.sdl;
import scripts.base_script;
import gameobject;
import scenemanager;

class TimerTransitionScript : BaseScript {
    private {
        bool spaceWasPressed = false;
        bool timerStarted = false;
        uint startTime;
        uint timerDuration = 60_000;  // 60 seconds in milliseconds
        string mode7SceneName = "mode7";
        string finalSceneName = "gameover";
    }

    this(GameObject* gameObject) {
        super(gameObject);
    }

    override void Update() {
        const ubyte* keyState = SDL_GetKeyboardState(null);
        
        // Check for spacebar press to start mode7 and timer
        if (keyState[SDL_SCANCODE_SPACE]) {
            if (!spaceWasPressed && !timerStarted) {
                spaceWasPressed = true;
                startTimer();
                transitionToScene(mode7SceneName);
            }
        } else {
            spaceWasPressed = false;
        }

        // Update timer if it's running
        if (timerStarted) {
            uint currentTime = SDL_GetTicks();
            uint elapsedTime = currentTime - startTime;
            uint remainingTime = timerDuration - elapsedTime;

            // Debug output every second
            if (elapsedTime % 1000 < 16) {  // Assuming 60fps, this will print roughly once per second
                writefln("Time remaining: %d seconds", remainingTime / 1000);
            }

            // Check if timer is complete
            if (elapsedTime >= timerDuration) {
                timerStarted = false;
                writeln("Timer complete! Transitioning to final scene...");
                transitionToScene(finalSceneName);
            }
        }
    }

    private void startTimer() {
        startTime = SDL_GetTicks();
        timerStarted = true;
        writeln("Timer started! Duration: 60 seconds");
    }

    private void transitionToScene(string sceneName) {
        try {
            // Create the load_scene.json file with the target scene name and path
            auto jsonData = JSONValue([
                "sceneName": JSONValue(sceneName),
                "path": JSONValue("./saves/" ~ sceneName ~ ".json")
            ]);
            write("load_scene.json", jsonData.toString());

            // Create the load_scene.flag file
            write("load_scene.flag", "1");

            writefln("Requested scene load: %s", sceneName);
        } catch (Exception e) {
            writefln("Failed to request scene load '%s': %s", sceneName, e.msg);
        }
    }

    // Optional: Methods to set scene names at runtime
    public void setMode7Scene(string sceneName) {
        mode7SceneName = sceneName;
    }

    public void setFinalScene(string sceneName) {
        finalSceneName = sceneName;
    }
} 