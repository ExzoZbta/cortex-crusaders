/**
 * @file gameobject.d
 * @brief Represents a game object in the game world.
 */
import core.atomic;
import std.stdio;
import std.conv;

import component;

// Third-party libraries
import bindbc.sdl;

/** 
 * Represents a game object in the game world.
 * Each GameObject can have multiple components attached to it for
 * handling rendering, collision, scripting, and other behaviors.
 */
struct GameObject{
	// Constructor
    int mX;
    int mY;
	float rotation_angle = 0;
	float rotation_speed = 2;

    int player_direction;
    static int alien_direction = 1;

	/**
	 * Constructs a new GameObject.
	 *
	 * @param name    The unique name identifier for the game object
	 * @param x_pos   The initial x-coordinate position
	 * @param y_pos   The initial y-coordinate position
	 *
	 * @throws AssertError if name is empty
	 */
	this(string name, int x_pos, int y_pos){
		assert(name.length > 0);
		mName = name;	
		// atomic increment of number of game objects
		atomicOp!"+="(sGameObjectCount, 1);		
		mID = sGameObjectCount; 
        mX = x_pos;
        mY = y_pos;
        
        // Immediately update position for any components that get added
        foreach (component; mComponents) {
            if (component !is null) {
                component.Update(mX, mY);
            }
        }
	}

	/**
	 * Destructor that cleans up all components attached to this GameObject.
	 */
	~this(){
		auto collision = this.GetComponent!(ComponentCollision)();
		auto texture = this.GetComponent!(ComponentTexture)();
		auto script = this.GetComponent!(ComponentScript)();

		destroy(collision);
		destroy(texture);
		destroy(script);
	}

	/**
	 * Retrieves the name of the GameObject.
	 *
	 * @return The name of the GameObject
	 */
	string GetName() const { return mName; }

	/**
	 * Retrieves the unique ID of the GameObject.
	 *
	 * @return The unique ID of the GameObject
	 */
	size_t GetID() const { return mID; }

	/**
	 * Updates the GameObject and all its attached components.
	 * Called once per frame to update position and state.
	 */
	void Update() {

		// Update all components with new position
		foreach(component; mComponents) {
			if (component !is null) {
				component.Update(mX, mY);
			}
		}
	}

	/**
	 * Renders the GameObject and all its visible components.
	 *
	 * @param renderer The SDL renderer used for drawing
	 */
	void Render(SDL_Renderer* renderer) {
		auto texture = GetComponent!ComponentTexture();
		if (texture !is null) {
			texture.Render(renderer, rotation_angle);
		}

		auto text = GetComponent!ComponentBitmapFont();
		if (text !is null) {
			text.Render(renderer, 0);
		}
	}

	/**
	 * Retrieves a component of the specified type attached to this GameObject.
	 *
	 * @tparam T The type of component to retrieve
	 * @return The component of type T if found, null otherwise
	 */
	T GetComponent(T)() {
		ComponentType type = ComponentType.UNKNOWN;
		
		static if(is(T == ComponentTexture)) {
			type = ComponentType.TEXTURE;
		}
		else static if(is(T == ComponentCollision)) {
			type = ComponentType.COLLISION;
		}
		else static if(is(T == ComponentScript)) {
			type = ComponentType.SCRIPT;
		}
		else static if(is(T == ComponentBitmapFont)) {
			type = ComponentType.TEXT;
		}
		else static if(is(T == HoverComponent)) {  // Add this case
			type = ComponentType.HOVER;
		}

		if (type in mComponents) {
			return cast(T)mComponents[type];
		}
		
		return null;
	}

	/**
	 * Gets the current X coordinate of the GameObject.
	 *
	 * @return The X coordinate
	 */
	int GetX(){
		return mX;
	}
	
	/**
	 * Gets the current Y coordinate of the GameObject.
	 *
	 * @return The Y coordinate
	 */
	int GetY(){
		return mY;
	}

	/**
	 * Gets the name of the GameObject.
	 *
	 * @return The name of the GameObject
	 */
	string getName(){
		return mName;
	}

	/**
	 * Adds a component to the GameObject.
	 *
	 * @tparam T The ComponentType enum value for the component
	 * @param component The component instance to add
	 */
	void AddComponent(ComponentType T)(IComponent component){
		mComponents[T] = component;
		// Update component position immediately when added
		if (component !is null) {
			component.Update(cast(int)mX, cast(int)mY);
		}
	}
	
	protected:
	// Common components for all game objects
	// Pointers are 'null' by default in DLang.
	// See reference types: https://dlang.org/spec/property.html#init
	IComponent[ComponentType] mComponents;

	private:
	// Any private fields that make up the game object
	string mName;
	size_t mID;

	static shared size_t sGameObjectCount = 0;
}

