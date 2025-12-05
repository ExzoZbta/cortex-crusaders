# Mike's Mode7 Massacre

A 2D/3D hybrid game engine built in D with SDL2, featuring Mode7 rendering capabilities and a comprehensive component-based architecture.

**Team:** Richard Corrente, Archit Kumar, and Sachin Thakrar  
**Course:** CPSC 411 - Game Engines

## About the Project

Mike's Mode7 Massacre is a custom game engine developed from scratch that showcases advanced rendering techniques and modern game engine architecture. The engine powers a pseudo-3D exploration game where players navigate a Mode7-rendered world collecting capsules while avoiding obstacles.

[**View Project Website**](https://exzoz.github.io/cortex-crusaders/)

## Core Features

### Rendering System
- **Mode7 Graphics Engine**: Pseudo-3D rendering technique for creating depth effects with 2D textures
- **Sprite Rendering**: Support for both static and animated sprites with sprite sheet management
- **Texture Management**: Efficient resource loading and caching system
- **Multi-layer Rendering**: Sky, ground, and sprite layers with proper depth sorting

### Component-Based Architecture
The engine uses a flexible component system where game objects can have multiple behaviors:
- **Texture Component**: Handles sprite rendering with animation support
- **Collision Component**: Manages bounding box collision detection
- **Script Component**: Enables custom game logic through D scripts
- **Animation Component**: Controls frame-based sprite animations
- **Hover Component**: Provides floating/hovering movement effects

### Scene Management
- **Hierarchical Scene Tree**: Organize game objects in parent-child relationships
- **Scene Serialization**: Save and load scenes to/from JSON format
- **Multi-Scene Support**: Create and switch between multiple game scenes
- **Scene Manager**: Centralized scene lifecycle management

### Editor Integration
- **Python-based Editor Interface**: In-engine editor for scene manipulation
- **Object Editor**: Create, modify, and delete game objects at runtime
- **Scene Tree Viewer**: Visualize and navigate the scene hierarchy
- **Live Editing**: Make changes while the game is running

### Resource Management
- **Singleton Resource Manager**: Centralized asset loading and caching
- **Image Loading**: Support for BMP and PNG textures
- **Sound Support**: Audio playback capabilities through SDL_mixer
- **Memory Efficient**: Automatic resource reuse and cleanup

### Animation System
- **JSON-based Animation Definitions**: Define animations with frame sequences
- **Sprite Sheet Support**: Load and parse sprite sheets with multiple frames
- **Animation Sequences**: Create named animation states (idle, walk, etc.)
- **Frame-based Playback**: Control animation speed and looping

### Scripting System
Custom script components for game logic:
- Movement scripts for player and NPC control
- Timer-based scene transitions
- Mode7 rendering toggles
- Debug visualization tools

## Game Features

The included game demonstrates the engine's capabilities:
- **Mode7 Exploration**: Navigate a pseudo-3D world with keyboard controls
- **Collectible System**: Find and collect capsules scattered throughout the world
- **Score Tracking**: Real-time score display using bitmap fonts
- **Dynamic Spawning**: Procedural capsule placement with spawn timers
- **Character Sprites**: Multiple character options with directional animations

## Technical Stack

- **Language**: D Programming Language
- **Graphics**: SDL2
- **Build System**: DUB package manager
- **Documentation**: Doxygen-generated API docs
- **Editor**: Python 3 with tkinter

## Installation

### Prerequisites
- D compiler (DMD, LDC, or GDC)
- DUB package manager
- SDL2 (version 2.0.16 or higher)
- Python 3 with tkinter (for editor)

### Building from Source

```bash
cd Engine
dub run
```

### Platform-Specific Notes

**macOS:**
```bash
brew install python-tk
```

**Windows/Linux:**
Ensure SDL2 development libraries are installed and accessible.

## How to Play

1. Launch the game engine
2. Press **E** to open the in-engine editor
3. In the Scene Manager window, click "Load Scene"
4. Select `mainmenu.json` from the saves directory
5. Close the editor and start playing!

**Controls:**
- Arrow keys or WASD: Move player
- E: Toggle editor mode

## Documentation

Full API documentation is available in the `docs/` folder. Open `docs/index.html` in your browser to explore the complete codebase documentation.

Key modules:
- `gameapplication.d` - Main application loop and initialization
- `mode.d` - Mode7 rendering engine implementation
- `gameobject.d` - Game object and component management
- `scenemanager.d` - Scene lifecycle and switching
- `component.d` - All component type definitions
- `animation.d` - Animation system implementation

## Engine Architecture

The engine follows a modular, component-based design:

```
Game Application
├── Resource Manager (Singleton)
├── Scene Manager
│   └── Scene Tree
│       └── Game Objects
│           └── Components (Texture, Collision, Script, etc.)
├── Mode7 Rendering Engine
└── Editor Interface (Python)
```

See `images/engine_diagram.svg` for a detailed architecture diagram.

## Assets

The engine includes:
- Custom pixel art sprites for multiple characters
- Mode7-compatible ground and sky textures
- Bitmap font for text rendering
- Sound effects for gameplay events

## Post Mortem

Implementing Mode7 proved more challenging than anticipated, particularly with sprite positioning relative to the camera. Despite spending considerable time on this issue, the team successfully integrated Mode7 rendering into the engine and created a functional game demonstrating the technology.

**What Went Well:**
- Successfully implemented Mode7 rendering from scratch
- Created a flexible component-based architecture
- Built a functional in-engine editor
- Achieved scene serialization and loading

**Challenges:**
- Static sprite positioning in Mode7 space required compromises
- Time constraints limited full feature implementation
- Some editor features incomplete for Mode7 mode

**Lessons Learned:**
- Importance of time management and feature prioritization
- Value of modular architecture for game engines
- Complexity of pseudo-3D rendering techniques
- Benefits of component-based design patterns

Given more time, the team would have refined the Mode7 sprite system, enhanced the editor UI, and implemented additional gameplay features.

## License

This project was created as a final for CPSC 411 at Yale College.

## Links

- [Project Website](https://exzoz.github.io/cortex-crusaders/)
- [Video Description](https://www.youtube.com/embed/Ndv4Np7hmxY)
- [API Documentation](docs/index.html)
