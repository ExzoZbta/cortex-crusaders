/**
 * @file tree.d
 * @brief Represents a node in the scene tree hierarchy.
 */
import std.stdio;
import gameapplication;
import component;
import gameobject;

/** 
 * Represents a node in the scene tree hierarchy.
 * Each node contains a game object and maintains parent-child relationships.
 */
struct TreeNode {
    static uint nextId = 0;
    uint id;
    GameObject* gameObject;
    TreeNode*[] children;
    TreeNode* parent;

    /**
     * Constructs a new TreeNode with the given game object.
     * @param obj Pointer to the GameObject to be contained in this node
     */
    this(GameObject* obj) {
        id = nextId++;
        gameObject = obj;
        parent = null;
    }

    /**
     * Adds a child node to this node.
     * @param child Pointer to the TreeNode to be added as a child
     */
    void addChild(TreeNode* child) {
        children ~= child;
        child.parent = &this;
    }
}

/**
 * Represents the hierarchical structure of the scene.
 * Manages the relationships between game objects in a tree structure.
 */
struct SceneTree {
    TreeNode* root;

    /**
     * Adds a child node to a specified parent node in the tree.
     * If parent is null, the child becomes the root node.
     * @param parent Pointer to the parent TreeNode
     * @param child Pointer to the child TreeNode to be added
     */
    void addChild(TreeNode* parent, TreeNode* child) {
        if (parent is null){
            root = child;
            child.parent = null;
        }
        else{
            parent.addChild(child);
        }
    }

    /**
     * Traverses the entire tree and applies the given function to each node.
     * @param func Delegate function to be applied to each node during traversal
     */
    void traverse(void delegate(TreeNode*) func) {
        traverseHelper(root, func);
    }

    /**
     * Helper function for recursive tree traversal.
     * @param node Current node being processed
     * @param func Delegate function to be applied to each node
     */
    private void traverseHelper(TreeNode* node, void delegate(TreeNode*) func) {
        //writeln("hey");
        if (node is null) return;
        func(node);
        foreach(child; node.children){
            traverseHelper(child, func);
        }
    }

    /**
     * Finds a node in the tree by the game object's name.
     * @param name Name of the game object to find
     * @return Pointer to the found TreeNode, or null if not found
     */
    TreeNode* findNode(string name) {
        return findNodeRecursive(root, name);
    }

    /**
     * Helper function for recursive node search.
     * @param node Current node being checked
     * @param name Name of the game object to find
     * @return Pointer to the found TreeNode, or null if not found
     */
    private TreeNode* findNodeRecursive(TreeNode* node, string name) {
        if(node.gameObject.GetName() == name){
            return node;
        }
        foreach (child; node.children){
            TreeNode* result = findNodeRecursive(child, name);
            if(result !is null){
                return result;
            }
        }
        return null;
    }
}