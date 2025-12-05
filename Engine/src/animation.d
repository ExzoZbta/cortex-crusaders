/**
 * @file animation.d
 * @brief Module for handling sprite animations and animation sequences.
 */
module animation;

// Standard libraries
import std.stdio;
import std.json;
import std.file;
import std.conv;

// Third-party libraries
import bindbc.sdl;

/**
 * Represents a single frame in an animation sequence.
 */
struct Frame {
    SDL_Rect mRect;  ///< Rectangle defining the frame's position and size in the sprite sheet
}

/**
 * Manages multiple animation sequences for a sprite.
 */
struct AnimationSequences {
    string mFilename;  ///< Path to the animation data file
    Frame[] mFrames;   ///< Collection of all possible frames in the sprite
    long[][string] mFrameNumbers;  ///< Maps animation names to frame sequences

    string mCurrentAnimationName;    ///< Name of the currently playing animation
    long mCurrentFramePlaying;       ///< Index of the current frame being displayed
    long mLastFrameInSequence;       ///< Index of the last frame in current sequence

    SDL_Renderer* mRendererRef;  ///< Reference to the SDL renderer
    SDL_Texture* mTextureRef;    ///< Reference to the sprite texture
    SDL_Rect* mRectRef;          ///< Reference to the destination rectangle

    /**
     * Initializes animation sequences with required SDL references.
     * 
     * Params:
     *     r = SDL renderer reference
     *     tex_reference = SDL texture reference
     *     rect = Destination rectangle reference
     */
    this(SDL_Renderer* r, SDL_Texture* tex_reference, SDL_Rect* rect) {
        mRendererRef = r;
        mTextureRef = tex_reference;
        mRectRef = rect;
    }

    /**
     * Renders the current frame of the animation.
     */
    void RenderCurrentFrame() {
        if (mCurrentAnimationName !is null) {
            long frameIndex = mFrameNumbers[mCurrentAnimationName][mCurrentFramePlaying];
            SDL_Rect srcRect = mFrames[frameIndex].mRect;
            SDL_RenderCopy(mRendererRef, mTextureRef, &srcRect, mRectRef);
        }
    }

    /**
     * Plays an animation based on the specified sequence name.
     * 
     * Params:
     *     name = Name of the animation sequence to play
     */
    void LoopAnimationSequence(string name) {
        if (name in mFrameNumbers) {
            if (name != mCurrentAnimationName) {
                mCurrentAnimationName = name;
                mCurrentFramePlaying = 0;
                mLastFrameInSequence = cast(long)(mFrameNumbers[name].length - 1);
            } else {
                mCurrentFramePlaying = (mCurrentFramePlaying + 1) % (mLastFrameInSequence + 1);
            }
        }

    }

    /**
     * Renders the current frame of the animation with a rotation.
     * 
     * Params:
     *     rotation = Angle of rotation in degrees
     */
    void RenderCurrentFrameWithRotation(double rotation) {
        if (mCurrentAnimationName !is null) {
            long frameIndex = mFrameNumbers[mCurrentAnimationName][mCurrentFramePlaying];
            SDL_Rect srcRect = mFrames[frameIndex].mRect;
            SDL_RenderCopyEx(mRendererRef, mTextureRef, &srcRect, mRectRef, rotation, null, SDL_FLIP_NONE);
        }
    }

    /**
     * Loads animation data from a JSON file.
     * 
     * Params:
     *     filename = Path to the JSON animation data file
     */
    void Load(string filename) {
        mFilename = filename;
        string jsonContent = readText(filename);
        JSONValue json = parseJSON(jsonContent);

        // parse json format
        int width = json["format"]["width"].integer.to!int;
        int height = json["format"]["height"].integer.to!int;
        int tileWidth = json["format"]["tileWidth"].integer.to!int;
        int tileHeight = json["format"]["tileHeight"].integer.to!int;

        // load frames
        int columns = width / tileWidth;
        int rows = height / tileHeight;
        for (int y = 0; y < rows; y++) {
            for (int x = 0; x < columns; x++) {
                Frame frame;
                frame.mRect = SDL_Rect(x * tileWidth, y * tileHeight, tileWidth, tileHeight);
                mFrames ~= frame;
            }
        }

        // parse frames
        foreach (string key, JSONValue value; json["frames"]) {
            long[] frameNumbers;
            foreach (JSONValue frameNumber; value.array) {
                frameNumbers ~= frameNumber.integer;
            }
            mFrameNumbers[key] = frameNumbers;
        }
    }
}
