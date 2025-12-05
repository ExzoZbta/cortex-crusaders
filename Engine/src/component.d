/**
 * @file component.d
 * @brief Module defining various game components that can be attached to game objects. This module implements a component-based architecture for game objects.
 */
module component;

import std.stdio;
import std.string;
import std.math;
import resourcemanager; 
import std.conv;

// Third-party libraries
import bindbc.sdl;
import scripts.base_script;
import gameobject;
import animation;

/**
 * Enumeration of available component types in the game engine.
 */
enum ComponentType {
    UNKNOWN,    ///< Unknown component type
    TEXTURE,    ///< Component for rendering textures
    COLLISION,  ///< Component for collision detection
    SCRIPT,     ///< Component for custom scripting
    TEXT,       ///< Component for text rendering
    HOVER       ///< Component for hover movement effects
}

/**
 * Base interface for all components in the game engine.
 * All game components must implement this interface.
 */
interface IComponent {
    /**
     * Updates the component's state.
     * 
     * Params:
     *     x = New X position in pixels
     *     y = New Y position in pixels
     */
    void Update(int x, int y);
}

/**
 * Component for handling sprite textures and animations.
 * Manages both static and animated textures with support for sprite sheets.
 */
class ComponentTexture : IComponent{
    private {
        SDL_Texture* mTexture;
        SDL_Rect mSrcRect;
        SDL_Rect mDestRect;
        int mX, mY;
        string mPath;
        ulong mID;
        
        // Animation properties
        string mCurrentAnimation = "idle";
        int[string] mFrameMap;  // Maps animation names to frame numbers
        int mTotalFrames;
        int mFrameWidth;
    }

    /**
     * Constructs a non-animated texture component.
     * 
     * Params:
     *     id = Unique identifier for the component
     *     path = File path to the texture
     *     renderer = SDL renderer instance
     *     scale = Scale factor for the texture (default: 1.0)
     */
    this(ulong id, string path, SDL_Renderer* renderer, float scale = 1.0f) {
        mID = id;
        mPath = path;
        
        // Load the texture
        mTexture = ResourceManager.GetInstance().LoadImageResource(renderer, path);
            
        // Set source and destination rectangles for the entire texture
        int w, h;
        SDL_QueryTexture(mTexture, null, null, &w, &h);
            
        mSrcRect = SDL_Rect(0, 0, w, h);
        mDestRect = SDL_Rect(0, 0, w, h);
        mFrameWidth = w;
            
        // Single frame setup
        mTotalFrames = 1;
        mFrameMap["idle"] = 0;
    }

    // Constructor for animated textures with JSON config
    this(ulong id, string path, SDL_Renderer* renderer, string jsonPath, float scale = 1.0f) {
        mID = id;
        mPath = path;
        
        // Load the texture
        mTexture = ResourceManager.GetInstance().LoadImageResource(renderer, path);
            
        // Load animation data from JSON
        import std.file : readText;
        import std.json : parseJSON, JSONValue;
            
        string jsonContent = readText(jsonPath);
        JSONValue json = parseJSON(jsonContent);
            
            // Get format information
            int totalWidth = cast(int)json["format"]["width"].integer;
            int totalHeight = cast(int)json["format"]["height"].integer;
            mFrameWidth = cast(int)json["format"]["tileWidth"].integer;
            int frameHeight = cast(int)json["format"]["tileHeight"].integer;
            
            // Set source rectangle
            mSrcRect.w = mFrameWidth;
            mSrcRect.h = frameHeight;
            
            // Set destination rectangle
            mDestRect.w = mFrameWidth;
            mDestRect.h = frameHeight;
            
            // Calculate total frames
            mTotalFrames = totalWidth / mFrameWidth;
            
            // Load frame mappings
            foreach (string animName, JSONValue frames; json["frames"].object) {
                mFrameMap[animName] = cast(int)frames.array[0].integer;
            }
    }

    /**
     * Sets the current animation sequence.
     * 
     * Params:
     *     animName = Name of the animation to play
     */
    void setAnimation(string animName) {
        if (animName in mFrameMap) {
            mCurrentAnimation = animName;
            // Update source rectangle X position based on frame number
            mSrcRect.x = mFrameMap[animName] * mFrameWidth;
        }
    }

    override void Update(int x, int y) {
        mX = x;
        mY = y;
        mDestRect.x = x;
        mDestRect.y = y;
    }

    void Render(SDL_Renderer* renderer, float angle = 0.0f) {
        if (mTexture !is null) {
            SDL_RenderCopyEx(
                renderer,
                mTexture,
                &mSrcRect,
                &mDestRect,
                angle,
                null,
                SDL_FLIP_NONE
            );
        }
    }

    void setScale(float newScale) {
        mDestRect.w = cast(int)(mFrameWidth * newScale);
        mDestRect.h = cast(int)(mSrcRect.h * newScale);
    }

    string GetPath() { return mPath; }
    int GetWidth() { return mDestRect.w; }
    int GetHeight() { return mDestRect.h; }
}

/**
 * Component for handling collision detection and physics.
 * Provides rectangular collision bounds and intersection testing.
 */
class ComponentCollision : IComponent {
    private int mX;
    private int mY;
    private int mW;
    private int mH;
    private int mYOffset;
    private ulong mID;
    private int originalW;
    private int originalH;

    this(ulong id, int x, int y, int w, int h, int yOffset = 0) {
        mID = id;
        mW = w;
        mH = h;
        mYOffset = yOffset;
        originalW = w;
        originalH = h;
        mX = x;
        mY = y + mYOffset;

    }

    override void Update(int x, int y) {
        mX = x;
        mY = y + mYOffset;
    }

    void Render(SDL_Renderer* renderer) {
        SDL_Rect rect;
        rect.x = mX;
        rect.y = mY;
        rect.w = mW;
        rect.h = mH;
        SDL_RenderDrawRect(renderer, &rect);
    }

    /**
     * Checks for collision with another collision component.
     * 
     * Params:
     *     other = The other collision component to test against
     * 
     * Returns: true if colliding, false otherwise
     */
    bool CheckCollision(ComponentCollision other) {
        return (mX < other.mX + other.mW &&
                mX + mW > other.mX &&
                mY < other.mY + other.mH &&
                mY + mH > other.mY);
    }

    void setScale(float newScale) {
        // Update destRect dimensions
        mW = cast(int)(originalW * newScale);
        mH = cast(int)(originalH * newScale);
    }

    // Getters
    int GetX() { return mX; }
    int GetY() { return mY; }
    int GetWidth() { return mW; }
    int GetHeight() { return mH; }
    ulong GetID() { return mID; }
}

/**
 * Component for handling custom game scripts.
 * Loads and manages script instances attached to game objects.
 */
class ComponentScript : IComponent {
    private BaseScript scriptInstance;
    private string scriptPath;
    private GameObject* owner;

    this(GameObject* gameObject, string scriptPath) {
        this.owner = gameObject;
        this.scriptPath = scriptPath;
        
        // Load the appropriate script based on the path
        import std.path : baseName, stripExtension;
        import std.string : toLower;
        
        string scriptName = baseName(scriptPath).stripExtension.toLower;
        
        // Create the appropriate script instance
        switch(scriptName) {
            case "debug_script":
                import scripts.debug_script : DebugScript;
                scriptInstance = new DebugScript(gameObject);
                break;
            // Add other script types here as needed
            case "movement_script":
                import scripts.movement_script : MovementScript;
                scriptInstance = new MovementScript(gameObject);
                break;
            case "scene_transition_script":
                import scripts.scene_transition_script : SceneTransitionScript;
                scriptInstance = new SceneTransitionScript(gameObject);
                break;
            case "mode7_enabler_script":
                import scripts.mode7_enabler_script : Mode7EnablerScript;
                scriptInstance = new Mode7EnablerScript(gameObject);
                break;
            case "timer_transition_script":
                import scripts.timer_transition_script : TimerTransitionScript;
                scriptInstance = new TimerTransitionScript(gameObject);
                break;
            case "mode7_timer_script":
                import scripts.mode7_timer_script : Mode7TimerScript;
                scriptInstance = new Mode7TimerScript(gameObject);
                break;
            case "mode7_delay_timer_script":
                import scripts.mode7_delay_timer_script : Mode7DelayTimerScript;
                scriptInstance = new Mode7DelayTimerScript(gameObject);
                break;
            case "scene_transition_script2":
                import scripts.scene_transition_script2 : SceneTransitionScript2;
                scriptInstance = new SceneTransitionScript2(gameObject);
                break;
            default:
                writeln("Unknown script type: ", scriptName);
                break;
        }
    }

    override void Update(int x, int y) {
        if (scriptInstance !is null) {
            scriptInstance.Update();
        }
    }

    float GetRotation() {
        return scriptInstance !is null ? scriptInstance.GetRotation() : 0.0f;
    }

    string GetPath() { return scriptPath; }
}

/**
 * Component for rendering bitmap fonts.
 * Handles sprite-based font rendering for scores and text.
 */
class ComponentBitmapFont : IComponent{
    SDL_Texture* mTexture;
    SDL_Rect mSourceRectangle;
    SDL_Rect mDestRectangle;
    int mCharWidth;
    int mCharHeight;
    int mScore;

     /**
     * Constructs a hover component.
     * 
     * Params:
     *     owner = The object owner
     *     bitmapFilePath = The path to the bitmap file
     *     renderer = The SDL renderer instance
     */
    this(size_t owner, string bitmapFilePath, SDL_Renderer* renderer){
        mOwner = owner;
        mTexture = ResourceManager.GetInstance().LoadImageResource(renderer, bitmapFilePath);

        mCharWidth = 20;
        mCharHeight = 20;

        mSourceRectangle.x = 0;
        mSourceRectangle.y = 0;
        mSourceRectangle.w = mCharWidth;
        mSourceRectangle.h = mCharHeight;

        mDestRectangle.x = 10;
        mDestRectangle.y = 10;
        mDestRectangle.w = mCharWidth;
        mDestRectangle.h = mCharHeight;

        mScore = 0;
    }

    override void Update(int x, int y){
        mDestRectangle.x = x;
        mDestRectangle.y = y; 
    }
    
    void Render(SDL_Renderer* renderer, float angle){
        string scoreString = to!string(mScore);
        foreach(i, digit; scoreString){
            int digitValue = digit - '0';
            mSourceRectangle.x = digitValue * mCharWidth;
            mDestRectangle.x = 10 + cast(int)i * mCharWidth;
            SDL_RenderCopyEx(renderer, mTexture, &mSourceRectangle, &mDestRectangle, angle, null, SDL_FLIP_NONE);
        }
    }

    void SetScore(int score){
        mScore = score;
    }

    private:
    size_t mOwner;


}

/**
 * Component for managing animation sequences.
 * Handles frame-based animations with timing control.
 */
class AnimationComponent : IComponent {

    private {   
        AnimationSequences* sequences;
        string currentAnimation = "idle";
        float frameTime = 0.0f;
        float frameDelay = 1.0f;
        int frameCounter = 0;
        bool isAnimating = true;
        GameObject* gameObject;
    }

    protected GameObject* getGameObject() {
        return gameObject;
    }

    public void setGameObject(GameObject* obj) {
        gameObject = obj;
        start();
    }

    void setAnimation(string animName) {
        currentAnimation = animName;
    }

    void setFrameDelay(float delay) {
        frameDelay = delay;
    }

    void pauseAnimation() {
        isAnimating = false;
    }

    void resumeAnimation() {
        isAnimating = true;
    }

    void start() {
        //WILL FIX LATER
        // auto sprite = getGameObject().GetComponent!ComponentTexture();
        // if (sprite !is null) {
        //     sequences = sprite.getAnimationSequences();
        // }
    }

    override void Update(int x, int y) {
        //WILL FIX LATER
        // if (sequences is null || !isAnimating) return;

        // frameTime += deltaTime;
        // if (frameTime >= frameDelay) {
        //     frameTime -= frameDelay;
        //     sequences.LoopAnimationSequence(currentAnimation);
        // }
    }
}

/**
 * Component for creating hovering motion effects.
 * Implements sinusoidal vertical movement for game objects.
 */
class HoverComponent : IComponent {
    private {
        ulong mID;
        float mAmplitude;    // How many pixels up/down
        float mFrequency;    // How many seconds per cycle
        float mTime = 0.0f;  // Current time in the cycle
        int mBaseY;          // Original Y position
        bool mBaseYSet = false;
        int* mYPtr; 
    }

    /**
     * Constructs a hover component.
     * 
     * Params:
     *     amplitude = Maximum distance to move up/down in pixels
     *     frequency = Time in seconds for one complete cycle
     *     yPtr = Pointer to the Y coordinate to modify
     */
    this(float amplitude, float frequency, int* yPtr) {
        mAmplitude = amplitude;
        mFrequency = frequency;
        mYPtr = yPtr;
    }

    override void Update(int x, int y) {
        if (!mBaseYSet) {
            mBaseY = y;
            mBaseYSet = true;
        }

        // Update time (assuming 60 FPS)
        mTime += 1.0f / 60.0f;
        
        // Calculate vertical offset using sine wave
        float offset = mAmplitude * sin(2 * PI * (mTime / mFrequency));
        
        // Update the game object's position
        if (mYPtr) {
            *mYPtr = mBaseY + cast(int)offset;
        }
    }
}