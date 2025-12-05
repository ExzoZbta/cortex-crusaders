/**
 * @file resourcemanager.d
 * @brief Manages resources such as images and textures.
 */

import bindbc.sdl;
import std.string;

/**
 * @brief Represents an image with a filename and pixel data.
 */
struct Image{
    string filename; ///< The filename of the image.
    ubyte[] pixels;  ///< The pixel data of the image.
}

/**
 * @brief Manages resources such as images and textures.
 */
struct ResourceManager{

    /**
     * @brief Gets the singleton instance of the ResourceManager.
     * @return A pointer to the ResourceManager instance.
     */
    static ResourceManager* GetInstance(){
        if(mInstance is null){
            mInstance = new ResourceManager();
        }
        return mInstance;
    }

    /**
     * @brief Loads an image resource and returns an SDL_Texture.
     * @param renderer The SDL_Renderer to use for creating the texture.
     * @param filename The filename of the image to load.
     * @return A pointer to the SDL_Texture created from the image.
     */
    SDL_Texture* LoadImageResource(SDL_Renderer* renderer, string filename){
        if(filename in mTextureResourceMap){
            return mTextureResourceMap[filename];
        }

        SDL_Surface* surface = SDL_LoadBMP(filename.toStringz);
        SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer,surface);
        SDL_FreeSurface(surface);
        mTextureResourceMap[filename] = texture;
        return texture;
    }

    /**
     * @brief Cleans up all loaded textures.
     */
    void cleanup(){
        foreach (texture; mTextureResourceMap.values){
            SDL_DestroyTexture(texture);
        }
        mTextureResourceMap.clear();
    }

    private:
        static ResourceManager* mInstance; ///< Singleton instance of ResourceManager.
        static SDL_Texture*[string] mTextureResourceMap; ///< Map of filenames to SDL_Textures.
}
