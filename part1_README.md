# Final Project

This is it--the final course project!

# Final Project - Description

<img width="400px" src="./media/greats.png">

The industry is getting positive buzz as [Nolan Bushnell](https://en.wikipedia.org/wiki/Nolan_Bushnell) and [Shigeru Miyamoto](https://en.wikipedia.org/wiki/Shigeru_Miyamoto) have been talking about your game development skills. But dynamics change rapidly in the game industry--you have decided to form a new game studio of your own. From your previous projects, your team has developed a nice codebase with your own intellectual property, and has decided to form a 'game making' studio around this technology. Building an impressive piece of middleware (i.e. a tool or technology that is not a game) to showcase at the giant tradeshows ([PAX East](http://east.paxsite.com/), [GDC](https://www.gdconf.com/), and [E3](https://www.e3expo.com/), etc.) is your next task!

<!-- 
# Final Project Option(s) -->

# Final Project

## Game Maker

For your final project, you will make a 'game maker'. That is, you will build a data-driven tool to generate a game. Your game maker may also incorporate 'pybind' to further enable anyone to use your engine (Note: you are allowed to explore other technologies like [lua](https://www.lua.org/) or [Angelscript](https://www.angelcode.com/angelscript/)).

With your engine **you will also** implement either a classic game (that we have not previously implemented (e.g. pacman, asteroids, snake, super mario, etc.)) or an original game using your engine to demonstrate how your engine is used.

### Some notes on building a game maker

1. Very likely you may need to integrate some GUI library into your system to make it useable.
   - Think about this early--even draw a picture of what you think it should look like.
   - Think about if this GUI needs to be in a scripting language (e.g. Python) or in the C++ code.
      - At the end of the day, you just need a tool that generates data.
2. *Think* data-driven
   - This means your C++ handles your engine, and your scripting language should handle the game logic.
3. You should be able to utilize many of the game programming patterns discussed in the course with this system.  
4. You need to implement at least one classic or original game using your game maker that includes '3' scenes.
   - The game need not span hours, but should at least demonstrate that a game with objectives can be played and won, and new data can be loaded and handled in the engine.

### Examples

See below some example game making tools for inspiration:

- Look on the left panel to see the API for the Love2D engine: 
   - https://love2d.org/wiki/Main_Page
- Look at Gamemakers API for inspiration of what commands are exposed. 
   - http://docs2.yoyogames.com/
- Here is an example showing integrating an API (through a console interface) with a script language to make changes and build a game in realtime.
   - https://www.youtube.com/watch?v=b8RyQSvmrEU
- Here is the GODDOT engine. I would look to GoDot and GameMaker as inspiration.
   -  https://www.youtube.com/watch?v=5ZuQIbMEjLw

<!--
## Option 2 - Pitch the Professor

On occassion someone taking this class has a different idea of something they are excited about tangentially related. If the game maker option does not satisfy you--**talk to the instructor if there is something you are more excited about** (i.e. you **must** get approval from me first). Generally speaking, most folks should be attempting or targeting projects closer to option 1's for the final project, and the more likely I am to agree to alternative accomadations is within the week the project is releasted.

### Alternate Pitch 1 - Engine API Tech Demo (2D or 3D)

You may implement an API (e.g. a physics engine, or a sound engine) that could be plugged into another technology. For your final project you will then build a high powered tech demo showing off this API. This tech demo would be a short showcase of your engine API showcaseing your technology with signficant engineering, such as advanced spatial partioning data structures, a concurrent job system, or a custom renderer. This option may be viable for folks with lots of previous experience in another tool (e.g. OGRE3D) or technology (e.g. OpenGL or Vulkan) and want to build on top of it.

I **will not** accept any project that utilizes other game engines like Unity3D however.
-->

<!--
#### Some notes on building an engine API

1. For this project you are building a C/C++ API to solve a specific game engine need (e.g. a physics engine, a sound engine).
2. You need to demonstrate its usefulness in a concrete way.
   - Building your engine as a shared library(.so, .dylib, .dll) and using it in another engine.
   - Concrete examples:
      - You build a physics engine as a .dll, and use it with OGRE3D.
      - You build a physics engine and use it with pygame and all of the physics are handled by your library.
3. You need to demonstrate useful game programming patterns with this system.
4. You need to implement at least one classic or original game using your engine API.

## Examples

See below some examples engine apis for inspiration.

- A physics engine with many samples
   - https://www.youtube.com/watch?v=ni-SmkCY-Sw (2D game demo showing off only 1 feature that is sufficiently complex)
- This is a illumination/lighting engine 
   - https://www.youtube.com/watch?v=4W8zxAV8RRY (2D game engine lighting effects)
   - This project does not however have much *wow* factor. (Probably a B- project)
- Here is another illumination engine
   - https://www.youtube.com/watch?v=LseTVMkG7V8 
   - An even better 2D game engine lighting effects, something like this is final project worthy if incorporated into platformer. (Probably in the B+/A- range as it looks like some actual physics are being used, and there is a neat 'debugging' mode to show where light is reaching)
- Here is another lighting engine 
   - https://www.youtube.com/watch?v=jVlxmC2qBGU (Unity3D Tech demo showing off one simple but high powered toggable feature in an editor).
   - This project has a nice GUI, updates in realtime, and looks like it could 
- https://www.youtube.com/watch?v=wB1pcXtEwIs Shows off a subset of a physics engine in use.
   - Here is a more concrete example of the API that would be implemented in tutorial form: https://www.youtube.com/watch?v=3Oay1YxkP5c&list=PLEETnX-uPtBXm1KEr_2zQ6K_0hoGH6JJ0
-->

<!--
# Constraints on Option 1 or option 2
-->

# Project Constraints

<!--
For any option you choose, you have the following constraints:
-->

1. Your must build the majority of your technology.
   - If you use 3rd party code (Say a compression library for example--which would be fine), then cite your source.
2. It is expected/permissable that you reuse some code from previous assignments.
3. 3rd party libraries for a physics engine (e.g. Box2D) are okay if you want to incorporate it into the engine.
4. You cannot build a tech demo with Unity3D, Unreal Engine -- that is not in the spirit of the course, we are building things from scratch.

Note--if you have not taken computer graphics, you should not be attempting to learn 3D graphics during this duration -- I am expecting most engines will be 2D. It is highly recommended (and to some extent expected) that most students will work on 2D projects leveraging their previous codebase.
