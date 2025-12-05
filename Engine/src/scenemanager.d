/**
 * @file scenemanager.d
 * @brief Manages game scenes and their associated objects.
 */
module scenemanager;

import std.container : DList;
import std.stdio;
import tree;
import gameobject;

/** 
 * Represents a game scene containing a tree of game objects.
 */
class Scene {
    string name;              ///< The name of the scene
    SceneTree sceneTree;      ///< The tree structure containing game objects
    TreeNode* rootNode;       ///< The root node of the scene tree

    /**
     * Constructs a new Scene with the given name.
     * Params:
     *     sceneName = The name to assign to the scene
     */
    this(string sceneName) {
        name = sceneName;
        rootNode = new TreeNode(new GameObject("Root", 0, 0));
        sceneTree = SceneTree();
        sceneTree.addChild(null, rootNode);
    }
}

/**
 * Manages multiple scenes in the game.
 * Implements the Singleton pattern for global scene management.
 */
class SceneManager {
    private static SceneManager instance;        ///< Singleton instance
    private Scene[string] scenes;                ///< Map of scene names to Scene objects
    private Scene activeScene;                   ///< Currently active scene

    private this() {}

    /**
     * Gets or creates the singleton instance of SceneManager.
     * Returns: The singleton instance of SceneManager
     */
    static SceneManager GetInstance() {
        if (instance is null) {
            instance = new SceneManager();
        }
        return instance;
    }

    /**
     * Creates a new scene with the specified name.
     * Params:
     *     name = The name for the new scene
     * Returns: The newly created Scene
     * Throws: Exception if a scene with the given name already exists
     */
    Scene CreateScene(string name) {
        if (name in scenes) {
            throw new Exception("Scene with name '" ~ name ~ "' already exists");
        }
        auto scene = new Scene(name);
        scenes[name] = scene;
        return scene;
    }

    /**
     * Sets the active scene by name.
     * Params:
     *     name = The name of the scene to set as active
     * Throws: Exception if the scene doesn't exist
     */
    void SetActiveScene(string name) {
        if (name !in scenes) {
            throw new Exception("Scene '" ~ name ~ "' does not exist");
        }
        activeScene = scenes[name];
    }

    /**
     * Gets the currently active scene.
     * Returns: The active Scene object
     */
    Scene GetActiveScene() {
        return activeScene;
    }

    /**
     * Gets a scene by name.
     * Params:
     *     name = The name of the scene to retrieve
     * Returns: The requested Scene object, or null if not found
     */
    Scene GetScene(string name) {
        return scenes.get(name, null);
    }

    /**
     * Gets a list of all scene names.
     * Returns: An array of scene names
     */
    string[] GetSceneNames() {
        return scenes.keys;
    }

    /**
     * Removes a scene by name.
     * Params:
     *     name = The name of the scene to remove
     * Returns: true if the scene was removed, false if it wasn't found
     * Throws: Exception if attempting to remove the active scene
     */
    bool RemoveScene(string name) {
        if (name in scenes) {
            if (activeScene == scenes[name]) {
                throw new Exception("Cannot delete active scene");
            }
            scenes.remove(name);
            return true;
        }
        return false;
    }
} 

 