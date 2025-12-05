/**
 * @file mode.d
 * @brief Mode7 graphics engine implementation module
 *
 * This module provides a Mode7 graphics engine implementation using SDL2.
 * It handles texture mapping, sprite rendering, and player movement in a
 * pseudo-3D environment.
 */
module mode;

import bindbc.sdl;
import std.math;
import std.string;
import std.stdio;
import std.algorithm;
import std.array;
import std.random;
import std.file;


// Project files
import factory;
import gameobject;
import animation;
import component;

/**
 * Main Mode7 graphics engine class
 *
 * Handles initialization, rendering, and game loop management for
 * Mode7-style graphics rendering with sprite support.
 */
class Mode7Engine {
    private:
        // Window properties
        int screenWidth = 800;
        int screenHeight = 600;
        SDL_Window* window;
        SDL_Renderer* renderer;
        
        // World properties
            // float worldX = 1000.0f;
            // float worldY = 1000.0f;
        float worldX = 0.5f;
        float worldY = 0.5f;
        float worldAngle = 0.1f;
        float nearPlane = 0.005f;
        float farPlane = 0.03f;
        float fieldOfViewHalf = PI / 4.0f;

        // Player properties
        float playerX = 0.5f;
        float playerY = 0.5f;
        float playerAngle = 0.1f;  // Player's facing direction

        // Camera properties
        float cameraX = 0.5f;
        float cameraY = 0.5f;
        float cameraAngle = 0.1f;
        float scaleStat = 0.4f;
        float xStat = 0.0f;
        
        // Ground texture
        SDL_Texture* groundTexture = null;
        SDL_Texture* skyTexture = null;
        int mapSize = 1024;
        
        // Game state
        bool isRunning = true;
        float playerSpeed = 0.05f;  // pixels per second
        float turnSpeed = 0.5f;      // radians per second

        // Sprite properties
        GameObject* player;
        GameObjectFactory factory;

        // Adjust player scale
        float playerScale = 0.5f;

        float spawnTimer = 0.0f;
        float spawnInterval = 2.0f;
        float spawnRadius = 0.05f;
        float worldSpawnRadius = 0.8f; 
        float minSpawnDistance = 0.02f;
        bool isMoving = false;

        float lastSpawnX = 0.0f;
        float lastSpawnY = 0.0f;
        float minSpawnDifference = 0.1f;

        float mikeSpawnChance = 0.3f;  // 30% chance to spawn Mike instead of capsule

        int score = 0;  // Player's score

        // Add score property and font texture
        SDL_Texture* fontTexture;
        int digitWidth = 20;  // Width of each digit in the font texture
        int digitHeight = 32; // Height of each digit in the font texture

    public:
        /** 
         * Represents an object in the game world
         */
        struct WorldObject {
            float worldX;    /// X position in world coordinates
            float worldY;    /// Y position in world coordinates
            GameObject* gameObject;  /// Pointer to the associated game object
        }

        /**
         * Represents the world objects and their properties in the game
         */
        WorldObject[] worldObjects;

        /**
         * Constructor for Mode7Engine
         * Params:
         *     window = SDL window to render to
         *     renderer = SDL renderer to use for drawing
         */
        this(SDL_Window* window, SDL_Renderer* renderer) {
            this.window = window;
            this.renderer = renderer;

            // Load the ground texture
            groundTexture = loadTexture("./assets/images/floor.bmp");
            if (groundTexture is null) {
                writeln("Failed to load ground texture!");
            }

            // Load the sky texture
            skyTexture = loadTexture("./assets/images/sky.bmp");
            if (skyTexture is null) {
                writeln("Failed to load sky texture!");
            }

            // Load the font texture
            fontTexture = loadTexture("./assets/images/textspritesheet.bmp");
            if (fontTexture is null) {
                writeln("Failed to load font texture!");
            }
        }

        /**
         * Initializes the engine and loads required resources
         * Returns: true if initialization successful, false otherwise
         */
        bool initialize() {
            factory = new GameObjectFactory(renderer);
            if (factory is null) {
                return false;
            }

            player = factory.createPlayer(
                (screenWidth / 2) - 60,
                (screenHeight / 2) + (screenHeight / 4) - 80
            );

            // Set initial scale
            auto texture = player.GetComponent!ComponentTexture();
            if (texture !is null) {
                texture.setScale(playerScale);
            }

            return true;
        }

        /**
         * Main game loop
         * Handles input processing and scene rendering
         */
        void run() {
            uint lastTime = SDL_GetTicks();
            
            while (isRunning) {
                try {
                    uint current = SDL_GetTicks();
                    float deltaTime = (current - lastTime) / 1000.0f;
                    lastTime = current;
                    
                    handleInput(deltaTime);
                    
                    renderScene();
                    
                }
                catch (Exception e) {
                    isRunning = false;
                }
            }
        }

        /**
         * Updates game state based on elapsed time
         * Params:
         *     deltaTime = Time elapsed since last update in seconds
         */
        void update(float deltaTime) {
            handleInput(deltaTime);
            handleCapsuleSpawning(deltaTime);

            // Check collisions between player and world objects
            auto playerCollider = player.GetComponent!ComponentCollision();
            if (playerCollider) {
                WorldObject[] newWorldObjects;
                
                foreach (ref obj; worldObjects) {
                    auto objCollider = obj.gameObject.GetComponent!ComponentCollision();
                    if (objCollider && playerCollider.CheckCollision(objCollider)) {
                        // Handle different object types
                        if (obj.gameObject.getName() == "capsule") {
                            score += 1;
                            writefln("Capsule collected! Score: %d", score);
                        

                        } else if (obj.gameObject.getName() == "mike") {
                            score = max(0, score - 5);  // Prevent negative scores
                            writefln("Hit Mike! Score: %d", score);
                            
                        }
                        continue;
                    } 
                    newWorldObjects ~= obj;
                }
                worldObjects = newWorldObjects;
            }

            renderScene();
        }

// bitmap loading
        /**
         * Loads a bitmap texture from file
         * Params:
         *     path = File path to the bitmap image
         * Returns: SDL_Texture pointer if successful, null otherwise
         */
        SDL_Texture* loadTexture(string path) {
            if (!std.file.exists(path)) {
                return null;
            }

            SDL_Surface* surface = SDL_LoadBMP(path.ptr);
            if (surface is null) {
                return null;
            }
            
            SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
            if (texture is null) {
                writefln("Failed to create texture from surface: %s, SDL Error: %s", path, SDL_GetError());
            }
            SDL_FreeSurface(surface);
            
            return texture;
        }

// PNG loading
    // private:
    //     SDL_Texture* loadTexture(string path) {
    //         SDL_Surface* surface = IMG_Load(path.ptr);
    //         if (surface is null) {
    //             writefln("Failed to load texture: %s", path);
    //             return null;
    //         }
            
    //         SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
    //         SDL_FreeSurface(surface);
            
    //         return texture;
    //     }

        /**
         * Handles keyboard input events
         * Params:
         *     deltaTime = Time elapsed since last frame in seconds
         */
        void handleInput(float deltaTime) {
            SDL_Event event;
            while (SDL_PollEvent(&event)) {
                switch (event.type) {
                    case SDL_QUIT:
                        isRunning = false;
                        break;
                        
                    case SDL_KEYDOWN:
                        handleKeyDown(event.key.keysym.sym);
                        break;
                        
                    default:
                        break;
                }
            }

            const ubyte* keyState = SDL_GetKeyboardState(null);
            auto texture = player.GetComponent!ComponentTexture();
            
            if (keyState[SDL_SCANCODE_UP]) {
                isMoving = true; 
                texture.setAnimation("forward");
                scaleStat = max(0.001f, scaleStat - 0.25f * deltaTime);
                float moveX = cos(cameraAngle) * playerSpeed * deltaTime;
                float moveY = sin(cameraAngle) * playerSpeed * deltaTime;
                playerX += moveX;
                playerY += moveY;
            }
            else if (keyState[SDL_SCANCODE_DOWN]) {
                isMoving = true;
                texture.setAnimation("backward");
                scaleStat += 0.25f * deltaTime;
                float moveX = cos(cameraAngle) * playerSpeed * deltaTime;
                float moveY = sin(cameraAngle) * playerSpeed * deltaTime;
                playerX -= moveX;
                playerY -= moveY;
            }
            else if (keyState[SDL_SCANCODE_LEFT]) {
                isMoving = true;
                texture.setAnimation("left");
                float adjustedScaleStat = max(0.05f, scaleStat);
                xStat += 50.0f * deltaTime / adjustedScaleStat;
                playerY -= playerSpeed * deltaTime * cos(playerAngle);
                playerX -= playerSpeed * deltaTime * sin(playerAngle);
            }
            else if (keyState[SDL_SCANCODE_RIGHT]) {
                isMoving = true;
                texture.setAnimation("right");
                float adjustedScaleStat = max(0.05f, scaleStat);
                xStat -= 50.0f * deltaTime / adjustedScaleStat;
                playerY += playerSpeed * deltaTime * cos(playerAngle);
                playerX += playerSpeed * deltaTime * sin(playerAngle);
            }
            else {
                texture.setAnimation("idle");
            }

            // Update camera position to follow player
            float cameraDistance = 0.01f;
            cameraX = playerX;
            cameraY = playerY - cameraDistance;
            cameraAngle = playerAngle;

            player.Update();

        }

        /**
         * Handles keyboard key press events
         * Params:
         *     key = SDL keycode of the pressed key
         */
        void handleKeyDown(SDL_Keycode key) {
            switch (key) {
                case SDLK_ESCAPE:
                    isRunning = false;
                    break;
                    
                default:
                    break;
            }
        }

        /**
         * Renders the current game scene including ground, sky, and sprites
         */
        void renderScene() {
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
            SDL_RenderClear(renderer);    

            uint[] pixelBuffer = new uint[screenWidth * screenHeight];

            // Calculate texture dimensions and get pixels
            int groundTexWidth, groundTexHeight;
            int skyTexWidth, skyTexHeight;
            SDL_QueryTexture(groundTexture, null, null, &groundTexWidth, &groundTexHeight);
            SDL_QueryTexture(skyTexture, null, null, &skyTexWidth, &skyTexHeight);

            static uint[] groundPixels;
            static uint[] skyPixels;
            
            // Update pixel arrays if textures have changed
            if (groundPixels.length != groundTexWidth * groundTexHeight || 
                skyPixels.length != skyTexWidth * skyTexHeight) {
                groundPixels = getTexturePixels(groundTexture);
                skyPixels = getTexturePixels(skyTexture);
            }

            // Calculate frustum corners
            float farX1 = cameraX + cos(cameraAngle - fieldOfViewHalf) * farPlane;
            float farY1 = cameraY + sin(cameraAngle - fieldOfViewHalf) * farPlane;
            float nearX1 = cameraX + cos(cameraAngle - fieldOfViewHalf) * nearPlane;
            float nearY1 = cameraY + sin(cameraAngle - fieldOfViewHalf) * nearPlane;
            float farX2 = cameraX + cos(cameraAngle + fieldOfViewHalf) * farPlane;
            float farY2 = cameraY + sin(cameraAngle + fieldOfViewHalf) * farPlane;
            float nearX2 = cameraX + cos(cameraAngle + fieldOfViewHalf) * nearPlane;
            float nearY2 = cameraY + sin(cameraAngle + fieldOfViewHalf) * nearPlane;

            // Render the Mode7 effect
            for (int y = 0; y < screenHeight / 2; y++) {
                float sampleDepth = cast(float)y / (cast(float)screenHeight / 2.0f);
                
                // Calculate start and end points for this scanline
                float startX = (farX1 - nearX1) / (sampleDepth) + nearX1;
                float startY = (farY1 - nearY1) / (sampleDepth) + nearY1;
                float endX = (farX2 - nearX2) / (sampleDepth) + nearX2;
                float endY = (farY2 - nearY2) / (sampleDepth) + nearY2;

                // Draw the scanline
                for (int x = 0; x < screenWidth; x++) {
                    float sampleWidth = cast(float)x / cast(float)screenWidth;
                    float sampleX = (endX - startX) * sampleWidth + startX;
                    float sampleY = (endY - startY) * sampleWidth + startY;

                    // Wrap coordinates
                    sampleX = fmod(sampleX, 1.0f);
                    sampleY = fmod(sampleY, 1.0f);
                    if (sampleX < 0) sampleX += 1.0f;
                    if (sampleY < 0) sampleY += 1.0f;

                    // Sample ground texture with bounds checking
                    int texPixelX = cast(int)(sampleX * groundTexWidth) % groundTexWidth;
                    int texPixelY = cast(int)(sampleY * groundTexHeight) % groundTexHeight;
                    if (texPixelX < 0) texPixelX += groundTexWidth;
                    if (texPixelY < 0) texPixelY += groundTexHeight;
                    uint groundColor = groundPixels[texPixelY * groundTexWidth + texPixelX];
                    
                    // Sample sky texture with bounds checking
                    int skyPixelX = cast(int)(sampleX * skyTexWidth) % skyTexWidth;
                    int skyPixelY = cast(int)(sampleY * skyTexHeight) % skyTexHeight;
                    if (skyPixelX < 0) skyPixelX += skyTexWidth;
                    if (skyPixelY < 0) skyPixelY += skyTexHeight;
                    uint skyColor = skyPixels[skyPixelY * skyTexWidth + skyPixelX];

                    // Write directly to pixel buffer
                    pixelBuffer[(y + screenHeight / 2) * screenWidth + x] = groundColor;
                    pixelBuffer[((screenHeight / 2) - y - 1) * screenWidth + x] = skyColor;

                    // renderTexturePoint(skyTexture, x, (screenHeight / 2) - y - 1, 
                    //                 sampleX * 0.3f + worldX * 0.3f, 
                    //                 sampleY * 0.3f + worldY * 0.3f);
                }
            }

            // Create texture from pixel buffer and render it
            static SDL_Texture* frameTexture = null;
            if (frameTexture is null) {
                frameTexture = SDL_CreateTexture(
                    renderer,
                    SDL_PIXELFORMAT_RGBA8888,
                    SDL_TEXTUREACCESS_STREAMING,
                    screenWidth,
                    screenHeight
                );
            }

            // Fix the pitch calculation
            SDL_UpdateTexture(frameTexture, null, pixelBuffer.ptr, screenWidth * 4);
            SDL_RenderCopy(renderer, frameTexture, null, null);

            // Draw horizon line
            SDL_SetRenderDrawColor(renderer, 0, 255, 255, 255);
            SDL_RenderDrawLine(renderer, 0, screenHeight / 2, screenWidth, screenHeight / 2);

            WorldObject[] validObjects;
            
            foreach (ref obj; worldObjects) {

                if (obj.gameObject is null) {
                    continue;
                }
                
                float relativeX = obj.worldX - worldX;
                float relativeY = obj.worldY - worldY;

                float rotatedX = scaleStat;
                float rotatedY = scaleStat;
                
                float depth = rotatedY / farPlane;
                if (depth <= 0) {
                    continue;
                }
                
                float scale = 1.0f / depth;
                float screenX = screenWidth / 2 + (relativeX / depth * screenWidth);
                float screenY = screenHeight / 2 + (0.5f / depth * screenHeight);

                // Update game object position
                float xOffset = (relativeX - 0.5f) * screenWidth * 0.005f; 
                obj.gameObject.mX = cast(int)xStat + cast(int)xOffset;
                obj.gameObject.mY = cast(int)screenY;

                obj.gameObject.Update();
                
                auto sprite = obj.gameObject.GetComponent!ComponentTexture();
                if (sprite !is null) {
                    sprite.setScale(scale * 1.0f);

                    // Destroy Mike if he becomes too small (far away)
                    if (obj.gameObject.getName() == "mike" && scale < 0.05f) {
                        obj.gameObject.destroy();
                        writefln("Mike destroyed due to distance!");
                        continue;
                    }
                }

                auto collision = obj.gameObject.GetComponent!ComponentCollision();
                if (collision) {
                    collision.setScale(scale * 1.0f);
                    collision.Update(cast(int)obj.gameObject.mX, cast(int)obj.gameObject.mY);
                    //collision.Render(renderer);
                }
                
                obj.gameObject.Render(renderer);
                validObjects ~= obj; 
            }
            worldObjects = validObjects;

            // Update player scale during rendering if needed
            auto texture = player.GetComponent!ComponentTexture();
            if (texture !is null) {
                texture.setScale(playerScale);
            }

            player.Render(renderer);
          

            // After rendering everything else, render the score on top
            renderScore();

            SDL_RenderPresent(renderer);
        }

        void handleCapsuleSpawning(float deltaTime) {
            // Only spawn if we have no capsules
            if (worldObjects.length > 0) {
                return;
            }

            spawnTimer += deltaTime;
            if (spawnTimer >= spawnInterval) {
                spawnTimer = 0.0f;

                float spawnX, spawnY;
                int maxAttempts = 5;
                bool validPosition = false;

                while (!validPosition && maxAttempts > 0) {
                    // Generate spawn position relative to player
                    float angle = uniform(0.0f, PI * 2);
                    float distance = uniform(0.02f, worldSpawnRadius);

                    spawnX = playerX + cos(angle) * distance;
                    spawnY = playerY + sin(angle) * distance;

                    // Check if this position is different enough from the last spawn
                    float diffX = abs(spawnX - lastSpawnX);
                    float diffY = abs(spawnY - lastSpawnY);
                    if (diffX > minSpawnDifference || diffY > minSpawnDifference) {
                        validPosition = true;
                    }

                    maxAttempts--;
                }

                if (validPosition) {
                    // Create new object and add it to worldObjects
                    if (uniform(0.0f, 1.0f) < mikeSpawnChance) {
                        worldObjects ~= WorldObject(spawnX, spawnY, factory.createMike(0, 0));
                        writefln("Mike spawned in world at position (%.2f, %.2f)", spawnX, spawnY);
                    } else {
                        worldObjects ~= WorldObject(spawnX, spawnY, factory.createCapsule(0, 0));
                        writefln("Capsule spawned in world at position (%.2f, %.2f)", spawnX, spawnY);
                    }
                    
                    lastSpawnX = spawnX;
                    lastSpawnY = spawnY;
                }
            }
        }

        /**
         * Extracts pixel data from an SDL texture
         * Params:
         *     texture = SDL texture to extract pixels from
         * Returns: Array of pixels in RGBA8888 format
         */
        uint[] getTexturePixels(SDL_Texture* texture) {
            int width, height;
            SDL_QueryTexture(texture, null, null, &width, &height);
            
            // Create a surface matching the texture format
            SDL_Surface* surface = SDL_CreateRGBSurface(0, width, height, 32, 
                0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
                
            // Create a temporary target texture
            SDL_Texture* target = SDL_CreateTexture(
                renderer,
                SDL_PIXELFORMAT_RGBA8888,
                SDL_TEXTUREACCESS_TARGET,
                width,
                height
            );
            
            // Copy the original texture to the target
            SDL_SetRenderTarget(renderer, target);
            SDL_RenderCopy(renderer, texture, null, null);
            
            // Read the pixels
            SDL_RenderReadPixels(renderer, null, 
                SDL_PIXELFORMAT_RGBA8888, surface.pixels, surface.pitch);
            
            // Copy the pixels to the array
            uint[] pixels = new uint[width * height];
            pixels[0 .. width * height] = (cast(uint*)surface.pixels)[0 .. width * height];
            
            // Cleanup
            SDL_FreeSurface(surface);
            SDL_DestroyTexture(target);
            SDL_SetRenderTarget(renderer, null);
            
            return pixels;
        }

        /**
         * Updates ground and sky textures
         * Params:
         *     groundPath = File path to new ground texture
         *     skyPath = File path to new sky texture
         */
        void updateTextures(string groundPath, string skyPath) {
            // Clean up existing textures if they exist
            if (groundTexture) SDL_DestroyTexture(groundTexture);
            if (skyTexture) SDL_DestroyTexture(skyTexture);
            
            // Load new textures
            groundTexture = loadTexture(groundPath);
            skyTexture = loadTexture(skyPath);
        }

        /**
         * Destructor - cleans up allocated resources
         */
        ~this() {
            if (groundTexture) SDL_DestroyTexture(groundTexture);
            if (skyTexture) SDL_DestroyTexture(skyTexture);
            if (fontTexture) SDL_DestroyTexture(fontTexture);
        }

        void renderScore() {
            // Convert score to string
            import std.conv : to;
            string scoreText = score.to!string;
            
            // Position for score display (top-right corner)
            int x = cast(int)(screenWidth - (scoreText.length * digitWidth) - 10);  // 10 pixels padding
            int y = cast(int)10;  // 10 pixels from top

            // Render each digit
            foreach (char digit; scoreText) {
                // Calculate source rectangle (which part of the font texture to use)
                SDL_Rect srcRect;
                srcRect.x = (digit - '0') * digitWidth;  // Select correct digit from texture
                srcRect.y = 0;
                srcRect.w = digitWidth;
                srcRect.h = digitHeight;

                // Calculate destination rectangle (where to render on screen)
                SDL_Rect dstRect;
                dstRect.x = x;
                dstRect.y = y;
                dstRect.w = digitWidth;
                dstRect.h = digitHeight;

                // Render the digit
                SDL_RenderCopy(renderer, fontTexture, &srcRect, &dstRect);
                
                // Move to next digit position
                x += digitWidth;
            }
        }

        // Add method to update score
        void updateScore(int newScore) {
            score = newScore;
        }
    }

// Main function to create and run the engine
// void main() {
//     auto engine = new Mode7Engine();
    
//     if (engine.initialize()) {
//         engine.run();
//     } else {
//     }
// }
