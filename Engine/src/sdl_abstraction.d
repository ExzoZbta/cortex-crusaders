/** 
 * @file sdl_abstraction.d
 * @brief SDL2/SDL3 initialization and shutdown abstraction layer
 */
module sdl_abstraction;

import std.stdio;
import std.string;

import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

/** Global variable storing SDL support level */
const SDLSupport ret;

/** 
 * Module constructor that initializes SDL
 * 
 * Attempts to load SDL libraries appropriate for the current operating system.
 * For Windows, tries SDL3 first then falls back to SDL2.
 * For macOS, searches in Homebrew locations.
 * For Linux, uses default system locations.
 * 
 * Prints version information and any errors encountered during initialization.
 */
shared static this(){
		// Load the SDL libraries from bindbc-sdl
		// on the appropriate operating system
		version(Windows){
				writeln("Searching for SDL on Windows");
				// NOTE: Windows folks I've defaulted into SDL3, but
				// 			 will fallback to try to find SDL2 otherwise.
				ret = loadSDL("SDL3.dll");
				if(ret != sdlSupport){
						writeln("Falling back on Windows to find SDL2.dll");
						ret = loadSDL("SDL2.dll");
				}
		}
		version(OSX){
			writeln("Searching for SDL on Mac");
			// Try the Homebrew Cellar location first
			ret = loadSDL("/opt/homebrew/Cellar/sdl2/2.30.10/lib/libSDL2-2.0.0.dylib");
			if(ret != sdlSupport){
				// Fallback to other common locations
				ret = loadSDL("/opt/homebrew/lib/libSDL2.dylib");
			}
			if(ret != sdlSupport){
				ret = loadSDL();  // Last resort - try default search
			}
		}
		version(linux){ 
				writeln("Searching for SDL on Linux");
				ret = loadSDL();
		}

		// Error if SDL cannot be loaded
		if(ret != sdlSupport){
				writeln("error loading SDL library");    
				foreach( info; loader.errors){
						writeln(info.error,':', info.message);
				}
		}
		if(ret == SDLSupport.noLibrary){
				writeln("error no library found");    
		}
		if(ret == SDLSupport.badLibrary){
				writeln("Eror badLibrary, missing symbols, perhaps an older or very new version of SDL is causing the problem?");
		}

		if(ret == sdlSupport){
				import std.conv;
				SDL_version sdlversion;
				SDL_GetVersion(&sdlversion);
				writeln(sdlversion);
				string msg = "Your SDL version loaded was: "~
						to!string(sdlversion.major)~"."~
						to!string(sdlversion.minor)~"."~
						to!string(sdlversion.patch);
				writeln(msg);
				if(sdlversion.major==2){
					writeln("Note: If SDL2 was loaded, it *may* be compatible with SDL3 function calls, but some are different.");
				}
		}
		// Initialize SDL
		if(SDL_Init(SDL_INIT_EVERYTHING) !=0){
				writeln("SDL_Init: ", fromStringz(SDL_GetError()));
		}

}

/**
 * Module destructor that performs SDL cleanup
 * 
 * Ensures SDL is properly shut down when the program terminates
 * by calling SDL_Quit() and logging the shutdown.
 */
shared static ~this(){
		// Quit the SDL Application 
		SDL_Quit();
		writeln("Shutting Down SDL");
}
