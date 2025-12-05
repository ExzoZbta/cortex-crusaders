module scripts.scene_transition_script;

import std.stdio;
import std.file : exists, write;
import std.json : JSONValue;
import bindbc.sdl;
import scripts.base_script;
import gameobject;
import scenemanager;

class SceneTransitionScript : BaseScript {
    private {
        bool spaceWasPressed = false;
        string targetSceneName = "finalmode7";  // The specific scene to transition to
    }

    this(GameObject* gameObject) {
        super(gameObject);
    }

    override void Update() {
        const ubyte* keyState = SDL_GetKeyboardState(null);
        
        // Check for spacebar press (only trigger once per press)
        if (keyState[SDL_SCANCODE_SPACE]) {
            if (!spaceWasPressed) {
                spaceWasPressed = true;
                
                // Print available scenes
                auto sceneManager = SceneManager.GetInstance();
                auto sceneNames = sceneManager.GetSceneNames();
                writeln("\nAvailable scenes:");
                foreach (name; sceneNames) {
                    writeln("- ", name);
                }
                writeln(); // Add blank line for readability
                
                transitionToScene();
            }
        } else {
            spaceWasPressed = false;
        }
    }

    private void transitionToScene() {
        try {
            // Create the load_scene.json file with the target scene name and path
            auto jsonData = JSONValue([
                "sceneName": JSONValue(targetSceneName),
                "path": JSONValue("./saves/" ~ targetSceneName ~ ".json")
            ]);
            write("load_scene.json", jsonData.toString());

            // Create the load_scene.flag file
            write("load_scene.flag", "1");

            writefln("Requested scene load: %s", targetSceneName);
        } catch (Exception e) {
            writefln("Failed to request scene load '%s': %s", targetSceneName, e.msg);
        }
    }

    // Optional: Method to set target scene at runtime
    public void setTargetScene(string sceneName) {
        targetSceneName = sceneName;
    }
}