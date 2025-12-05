/**
 * @file factory.d
 * @brief Factory module for creating game objects with predefined components.
 */
module factory;

import gameobject;
import bindbc.sdl;
import component;
import std.path : buildPath;
import std.random : uniform;
import std.stdio : writefln;

/**
 * Factory class responsible for creating game objects with standard configurations.
 */
class GameObjectFactory {
    private SDL_Renderer* renderer;
    private string currentCharacter = "sachin";  // Default character
    private string[] availableCharacters = ["sachin", "archit", "richard"];

    // Constructor
    this(SDL_Renderer* renderer) {
        this.renderer = renderer;
    }

    // Method to set current character
    void setCharacter(string characterName) {
        currentCharacter = characterName;
    }

    private string getCharacterSpritePath() {
        return buildPath("assets", "sprites", currentCharacter, "spritesheets", 
                        currentCharacter ~ "-sheet.bmp");
    }

    private string getCharacterConfigPath() {
        return buildPath("assets", "sprites", currentCharacter, 
                        currentCharacter ~ ".json");
    }

    private enum {
        CAPSULE_SPRITE = "./assets/sprites/capsule/capsule.bmp",
        MIKE_SPRITE = "./assets/sprites/mike/mike-front.bmp",
        SCORE_FONT = "./assets/fonts/Audiowide-Regular.ttf"
    }

    /**
     * Creates a new player game object with a random character.
     * 
     * Params:
     *     x = Initial X position
     *     y = Initial Y position
     * Returns: Pointer to the created player game object
     */
    GameObject* createPlayer(float x, float y) {
        // Randomly select a character
        currentCharacter = availableCharacters[uniform(0, availableCharacters.length)];
        writefln("Randomly selected character: %s", currentCharacter);

        auto player = new GameObject("player", cast(int)x, cast(int)y);
        
        // Use randomly selected character's sprite sheet and config
        auto texture = new ComponentTexture(
            player.GetID(),
            getCharacterSpritePath(),  // Dynamic sprite sheet path
            renderer,
            getCharacterConfigPath()   // Dynamic config path
        );
        player.AddComponent!(ComponentType.TEXTURE)(texture);

        auto collision = new ComponentCollision(player.GetID(), cast(int)x, cast(int)y, 125, 50, 170);
        player.AddComponent!(ComponentType.COLLISION)(collision);
        
        auto hover = new HoverComponent(16.0f, 2.0f, &player.mY);
        player.AddComponent!(ComponentType.HOVER)(hover);
        // Set initial animation
        texture.setAnimation("idle");
        
        return player;
    }

    /**
     * Creates a new capsule game object.
     * 
     * Params:
     *     x = Initial X position
     *     y = Initial Y position
     * Returns: Pointer to the created capsule game object
     */
    GameObject* createCapsule(float x, float y) {
        auto capsule = new GameObject("capsule", cast(int)x, cast(int)y);
        
        auto capsule_sprite = new ComponentTexture(capsule.GetID(), CAPSULE_SPRITE, renderer, "./assets/sprites/capsule/capsule.json");
        // Use simple texture for capsule
        capsule.AddComponent!(ComponentType.TEXTURE)(capsule_sprite);

        auto collision = new ComponentCollision(capsule.GetID(), cast(int)x, cast(int)y, 250, 250);
        capsule.AddComponent!(ComponentType.COLLISION)(collision);
        
        return capsule;
    }

    /**
     * Creates a new mike game object.
     * 
     * Params:
     *     x = Initial X position
     *     y = Initial Y position
     * Returns: Pointer to the created mike game object
     */
    GameObject* createMike(float x, float y) {
        auto mike = new GameObject("mike", cast(int)x, cast(int)y);
        auto mike_sprite = new ComponentTexture(mike.GetID(), MIKE_SPRITE, renderer, "./assets/sprites/mike/mike.json");
        mike.AddComponent!(ComponentType.TEXTURE)(mike_sprite);

        auto collision = new ComponentCollision(mike.GetID(), cast(int)x, cast(int)y, 400, 450);
        mike.AddComponent!(ComponentType.COLLISION)(collision);

        mike_sprite.setAnimation("idle");
    
        return mike;
    }
}

