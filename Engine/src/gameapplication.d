/**
 * @file gameapplication.d
 * @brief Main game application structure handling initialization, updates, and rendering.
 */
module gameapplication;
// Import D standard libraries
import std.stdio;
import std.string;
import std.conv : to;
import std.random;
import std.algorithm;
import std.array;
import std.file : exists, readText, remove, write;
import std.json : parseJSON, JSONValue;

// Third-party libraries
import bindbc.sdl;

// Import our SDL Abstraction
import sdl_abstraction;
//import sprite;
import gameobject;
import component;
import tree;
import resourcemanager;
//import audio;

import std.file : exists, readText, remove;
import std.json : parseJSON;

import std.algorithm : filter, canFind;
import std.array : array;

import gameobject : GameObject;
import scenemanager;

import mode;

/**
 * Global flag to track update status.
 */
bool update_flag = true; 

/**
 * Main game application structure handling initialization, updates, and rendering.
 */
struct GameApplication{
		SDL_Window* mWindow = null;
		SDL_Renderer* mRenderer = null;
		bool mGameIsRunning = true;

		int num_frames = 0;
		uint last_timestamp = 0;

		// Game Data
		auto rnd = Random();

		SceneManager sceneManager;
		TreeNode* rootNode;

		bool mEditorMode = false;

		bool eKeyWasPressed = false;  // Track previous state of E key

		private {
			bool isMode7 = false;
			Mode7Engine mode7Engine;
		}

		/**
		 * Initializes the game application with a window title.
		 * 
		 * Params:
		 *     title = Window title for the game
		 */
		this(string title){
				// Create an SDL window
				mWindow = SDL_CreateWindow(title.toStringz, SDL_WINDOWPOS_UNDEFINED, 
																	SDL_WINDOWPOS_UNDEFINED, 800, 600, SDL_WINDOW_SHOWN);

				// Create a hardware accelerated mRenderer
				mRenderer = SDL_CreateRenderer(mWindow,-1,SDL_RENDERER_ACCELERATED);
				
				// Initialize Mode7 engine using the same window and renderer
				mode7Engine = new Mode7Engine(mWindow, mRenderer);
				if (!mode7Engine.initialize()) {
					throw new Exception("Failed to initialize Mode7 engine");
				}

				// Initialize scene management
				sceneManager = SceneManager.GetInstance();

				// Load all scenes from the saves directory
				import std.file : dirEntries, SpanMode;
				import std.path : baseName, stripExtension;
				
				try {
					foreach (string file; dirEntries("./saves", "*.json", SpanMode.shallow)) {
						string sceneName = baseName(file).stripExtension;
						writefln("Loading scene: %s", sceneName);
						auto scene = sceneManager.CreateScene(sceneName);
					}
					
					// Set main as the active scene
					sceneManager.SetActiveScene("main");
					rootNode = sceneManager.GetActiveScene().rootNode;
				} catch (Exception e) {
					writefln("Error loading scenes: %s", e.msg);
				}
		}

		// Destructor
		~this(){
				// Remove the running flag when the game closes
				import std.file : exists, remove;
				if (exists("running.flag")) {
					remove("running.flag");
				}
				
				// Destroy our renderer
				SDL_DestroyRenderer(mRenderer);
				// Destroy our window
				SDL_DestroyWindow(mWindow);
				
				ResourceManager.GetInstance().cleanup();
				//Audio.Cleanup();

				if (mode7Engine !is null) {
					destroy(mode7Engine);
				}
		}

		/**
		 * Handles input events and user interaction.
		 * 
		 * Processes keyboard, mouse, and editor-related events. Manages mode switching
		 * between 2D and Mode7 rendering.
		 */
		void Input(){
				SDL_Event event;
				const ubyte* state = SDL_GetKeyboardState(null);

				// Handle editor mode toggle (E key)
				if (state[SDL_SCANCODE_E]) {
					if (!eKeyWasPressed) {  // Only trigger if E wasn't pressed in previous frame
						try {
							import std.process : spawnProcess, Config;
							import std.file : exists;
							import std.path : buildPath;

							string editorPath = buildPath("src", "object_editor.py");
							if (exists(editorPath)) {
								auto pid = spawnProcess(["python3", editorPath], null, Config.detached);
							} else {
								writeln("Error: Could not find editor script at ", editorPath);
							}
						} catch (Exception e) {
							writeln("Error launching editor: ", e.msg);
						}
					}
					eKeyWasPressed = true;
				} else {
					eKeyWasPressed = false;
				}

				// Check for mode switch request
				if (exists("mode_switch.flag")) {
					try {
						auto jsonData = parseJSON(readText("mode_switch.json"));
						isMode7 = jsonData["mode7"].boolean;
						writeln("Switched to ", isMode7 ? "Mode7" : "2D", " mode");
						remove("mode_switch.flag");
						remove("mode_switch.json");
					} catch (Exception e) {
						writeln("Error switching modes: ", e.msg);
					}
				}

				// Handle events based on current mode
				if (isMode7) {
					mode7Engine.handleInput(1.0f / 60.0f);  // Pass fixed deltaTime for now
				} else {
					// Start our event loop
					while(SDL_PollEvent(&event)){
							// Handle each specific event
							if(event.type == SDL_QUIT){
									mGameIsRunning= false;
							}
							if(event.type == SDL_MOUSEBUTTONDOWN) {
								// Check if editor is in placement mode
								if (exists("placement_mode.flag")) {
									// Write click coordinates to a file
									import std.stdio : File;
									auto clickData = File("click_event.json", "w");
									clickData.writeln(`{"x": `, event.button.x, `, "y": `, event.button.y, `}`);
									clickData.close();
									
									// Create trigger file
									auto triggerFile = File("click_event.flag", "w");
									triggerFile.write("click");
									triggerFile.close();
								}
							}
					}
				}
		}

		/**
		 * Updates game state each frame.
		 * 
		 * Handles:
		 * - Node list requests
		 * - Scene management operations
		 * - Game object updates
		 * - Node operations (add/remove)
		 * - Scene saving/loading
		 * - Mode7 updates
		 */
		void Update() {
			static int frameCounter = 0;
			frameCounter++;

			// Check for node list request
			if (exists("request_nodes.flag")) {
				remove("request_nodes.flag");

				import std.json : JSONValue, JSONType;
				
				// Create hierarchical node data
				JSONValue[] nodeData;
				
				JSONValue buildNodeJson(TreeNode* node) {
					if (node is null || node.gameObject is null) {
						return JSONValue(null);
					}
					
					JSONValue[] childrenData;
					foreach (child; node.children) {
						JSONValue childJson = buildNodeJson(child);
						if (childJson.type != JSONType.null_) {
							childrenData ~= childJson;
						}
					}
					
					return JSONValue([
						"name": JSONValue(node.gameObject.GetName()),
						"children": JSONValue(childrenData)
					]);
				}
				
				// Start with root node
				nodeData ~= buildNodeJson(rootNode);
				
				// Write hierarchical data to file
				write("available_nodes.json", JSONValue(nodeData).toString());
			}

			// Handle scene list requests
			if (exists("request_scenes.flag")) {
				remove("request_scenes.flag");
				
				// Create array of scene names
				string[] sceneNames = sceneManager.GetSceneNames();
				
				// Create JSON response
				JSONValue response = JSONValue([
					"scenes": JSONValue(sceneNames)
				]);
				
				// Write to file
				write("available_scenes.json", response.toString());
			}

			// Handle scene operations
			if (exists("scene_operation.flag")) {
				remove("scene_operation.flag");
				
				if (exists("scene_operation.json")) {
					try {
						auto jsonData = parseJSON(readText("scene_operation.json"));
						string action = jsonData["action"].str;
						string name = jsonData["name"].str;
						
						if (action == "create") {
							sceneManager.CreateScene(name);
						} else if (action == "delete") {
							sceneManager.RemoveScene(name);
						}
						
						remove("scene_operation.json");
					} catch (Exception e) {
						writeln("Error handling scene operation: ", e.msg);
					}
				}
			}

			// Update all game objects in the scene tree (every frame)
			auto activeScene = sceneManager.GetActiveScene();
			if (activeScene) {
				activeScene.sceneTree.traverse((TreeNode* node) {
					if (node !is null && node.gameObject !is null) {
						node.gameObject.Update();
					}
				});
			}

			// Handle node operations
			if (exists("node_operation.flag")) {
				remove("node_operation.flag");
				
				if (exists("node_operation.json")) {
					try {
						auto jsonData = parseJSON(readText("node_operation.json"));
						string action = jsonData["action"].str;
						
						if (action == "add_node") {
							string nodeName = jsonData["name"].str;
							string parentName = jsonData["parent"].str;
							
							// Check if name already exists
							bool nameExists = false;
							sceneManager.GetActiveScene().sceneTree.traverse((TreeNode* node) {
								if (node !is null && node.gameObject !is null && 
									node.gameObject.GetName() == nodeName) {
									nameExists = true;
								}
							});
							
							if (nameExists) {
								writeln("Error: Node name already exists: ", nodeName);
								return;
							}
							
							// Create new empty game object
							auto newGameObject = new GameObject(nodeName, 0, 0);
							auto newNode = new TreeNode(newGameObject);
							
							// Find parent node
							TreeNode* parentNode;
							if (parentName == "root") {
								parentNode = rootNode;
							} else {
								parentNode = sceneManager.GetActiveScene().sceneTree.findNode(parentName);
							}
							
							if (parentNode !is null) {
								parentNode.children ~= newNode;
								newNode.parent = parentNode;
							}
						}
						else if (action == "remove_node") {
							string nodeName = jsonData["name"].str;
							bool reparent = "reparent" in jsonData ? jsonData["reparent"].boolean : false;
							
							if (nodeName != "Root") {  // Prevent removing root
								TreeNode* nodeToRemove = sceneManager.GetActiveScene().sceneTree.findNode(nodeName);
								if (nodeToRemove !is null && nodeToRemove.parent !is null) {
									TreeNode* parentNode = nodeToRemove.parent;
									
									if (reparent && nodeToRemove.children.length > 0) {
										// Reparent all children to the parent of the removed node
										foreach (child; nodeToRemove.children) {
											child.parent = parentNode;
											parentNode.children ~= child;
										}
										
										// Remove the node's children array to prevent double-free
										nodeToRemove.children = [];
									}
									
									// Remove the node from its parent's children
									parentNode.children = parentNode.children.filter!(child => child != nodeToRemove).array;
									
									// Clean up the removed node
									destroy(nodeToRemove.gameObject);
									destroy(nodeToRemove);
								}
							}
						}
						
						remove("node_operation.json");
					} catch (Exception e) {
						writeln("Error handling node operation: ", e.msg);
					}
				}
			}

			// Handle scene saving
			if (exists("save_scene.flag")) {
				remove("save_scene.flag");
				
				// Get save path from the editor
				if (exists("load_scene.json")) {  // We're reusing this JSON file for the path
					try {
						auto jsonData = parseJSON(readText("load_scene.json"));
						SaveScene(jsonData["path"].str);
						remove("load_scene.json");
					} catch (Exception e) {
						writeln("Error getting save path: ", e.msg);
					}
				}
			}

			// Handle scene loading
			if (exists("load_scene.flag")) {
				remove("load_scene.flag");
				if (exists("load_scene.json")) {
					try {
						auto jsonData = parseJSON(readText("load_scene.json"));
						LoadScene(jsonData["path"].str);
						remove("load_scene.json");
					} catch (Exception e) {
						writeln("Error loading scene: ", e.msg);
					}
				}
			}

			if (isMode7) {
				mode7Engine.update(1.0f / 60.0f);
			}

			// Add scene switching support
			if (exists("switch_scene.flag")) {
				remove("switch_scene.flag");
				if (exists("switch_scene.json")) {
					try {
						auto jsonData = parseJSON(readText("switch_scene.json"));
						string sceneName = jsonData["scene"].str;
						sceneManager.SetActiveScene(sceneName);
						rootNode = sceneManager.GetActiveScene().rootNode;
						remove("switch_scene.json");
					} catch (Exception e) {
						writeln("Error switching scene: ", e.msg);
					}
				}
			}

			// Write active scene name to file for editor
			if (sceneManager.GetActiveScene()) {
				write("active_scene.json", JSONValue([
					"activeName": JSONValue(sceneManager.GetActiveScene().name)
				]).toString());
			}

			if (exists("mode7_textures.flag")) {
				remove("mode7_textures.flag");
				if (exists("mode7_textures.json")) {
					try {
						auto jsonData = parseJSON(readText("mode7_textures.json"));
						if (mode7Engine !is null) {
							mode7Engine.updateTextures(
								jsonData["ground_texture"].str,
								jsonData["sky_texture"].str
							);
						}
						remove("mode7_textures.json");
					} catch (Exception e) {
						writeln("Error updating Mode7 textures: ", e.msg);
					}
				}
			}
		}

		/**
		 * Saves the current scene state to a file.
		 * 
		 * Params:
		 *     filename = Path where the scene should be saved
		 * 
		 * The save format includes:
		 * - Scene name
		 * - Game objects with positions
		 * - Component data (textures, scripts, collisions)
		 * - Scene hierarchy
		 */
		void SaveScene(string filename) {
			import std.path : dirName, buildPath;
			import std.file : exists, mkdirRecurse;

			// Create saves directory if it doesn't exist
			string saveDir = dirName(filename);
			if (!exists(saveDir)) {
				mkdirRecurse(saveDir);
			}

			JSONValue[] sceneData;
			
			// Add scene name to the save data
			auto activeScene = sceneManager.GetActiveScene();
			sceneData ~= JSONValue([
				"sceneName": JSONValue(activeScene.name)
			]);
			
			// Traverse scene tree and save all objects, but skip the root node
			activeScene.sceneTree.traverse((TreeNode* node) {
				if (node !is null && node.gameObject !is null && node != rootNode) {  // Skip root node
					JSONValue objData = JSONValue([
						"name": JSONValue(node.gameObject.GetName()),
						"position": JSONValue([
							"x": JSONValue(node.gameObject.GetX()),
							"y": JSONValue(node.gameObject.GetY())
						]),
						"parent": JSONValue(node.parent !is null ? node.parent.gameObject.GetName() : "root")
					]);

					// Save components
					JSONValue[string] components;

					// Texture component
					auto texture = node.gameObject.GetComponent!ComponentTexture();
					if (texture !is null) {
						components["texture"] = JSONValue([
							"path": JSONValue(texture.GetPath())
						]);
					}

					// Script component
					auto script = node.gameObject.GetComponent!ComponentScript();
					if (script !is null) {
						components["script"] = JSONValue([
							"path": JSONValue(script.GetPath())
						]);
					}

					// Collision component
					auto collision = node.gameObject.GetComponent!ComponentCollision();
					if (collision !is null) {
						components["collision"] = JSONValue(true);
					}

					objData["components"] = JSONValue(components);
					sceneData ~= objData;
				}
			});

			// Write to file
			write(filename, JSONValue(sceneData).toString());
		}

		/**
		 * Loads a scene from a saved file.
		 * 
		 * Params:
		 *     filename = Path to the scene file to load
		 * 
		 * Throws: Exception if the file cannot be read or contains invalid data
		 */
		void LoadScene(string filename) {
			if (!exists(filename)) {
				writeln("Error: Save file does not exist: ", filename);
				return;
			}

			try {
				auto jsonData = parseJSON(readText(filename));
				writeln("Loading scene from: ", filename);
				
				// Get scene name from save data
				string sceneName = jsonData.array[0]["sceneName"].str;
				
				// Create new scene or get existing one
				Scene scene;
				try {
					scene = sceneManager.CreateScene(sceneName);
				} catch (Exception e) {
					// Scene already exists, get the existing one
					scene = sceneManager.GetScene(sceneName);
					
					// Clear existing scene except root
					foreach (child; scene.rootNode.children) {
						child.parent = null;
					}
					scene.rootNode.children = [];
				}
				
				// Set as active scene
				sceneManager.SetActiveScene(sceneName);
				rootNode = scene.rootNode;

				// Skip the scene name entry when processing objects
				foreach (objData; jsonData.array[1..$]) {
					// Skip if this is a Root node
					if (objData["name"].str == "Root") continue;
					
					writeln("Creating object: ", objData["name"].str);
					
					// Create game object
					GameObject* gameObject = new GameObject(
						objData["name"].str,
						cast(int)objData["position"]["x"].integer,
							cast(int)objData["position"]["y"].integer
					);

					// Create node
					TreeNode* node = new TreeNode(gameObject);

					// Add components if they exist
					if ("components" in objData) {
						auto components = objData["components"];

						// Add texture component
						if ("texture" in components) {
							auto texture = new ComponentTexture(
								gameObject.GetID(),
								components["texture"]["path"].str,
								mRenderer
							);
							gameObject.AddComponent!(ComponentType.TEXTURE)(texture);
						}

						// Add script component
						if ("script" in components) {
							auto script = new ComponentScript(
								gameObject,
								components["script"]["path"].str
							);
							gameObject.AddComponent!(ComponentType.SCRIPT)(script);
						}

						// Add collision component
						if ("collision" in components && components["collision"].boolean) {
							auto texture = gameObject.GetComponent!ComponentTexture();

							auto collision = new ComponentCollision(
								gameObject.GetID(),
								cast(int)objData["position"]["x"].integer,
								cast(int)objData["position"]["y"].integer,
								texture.GetWidth(),
								texture.GetHeight()
							);
							gameObject.AddComponent!(ComponentType.COLLISION)(collision);
						}
					}

					// Add to the validated parent
					scene.sceneTree.addChild(scene.rootNode, node);
				}

				writeln("Scene '", sceneName, "' loaded successfully");
			} catch (Exception e) {
				writeln("Error loading scene: ", e.msg);
			}
		}

		/**
		 * Renders the current game state.
		 * 
		 * Handles both 2D and Mode7 rendering paths:
		 * - 2D: Renders game objects, textures, bitmap fonts, and optional colliders
		 * - Mode7: Delegates to Mode7Engine for 3D perspective rendering
		 */
		void Render() {
			if (isMode7) {
				if (exists("show_colliders.flag")) {
					SDL_SetRenderDrawColor(mRenderer, 255, 0, 0, 100);
					foreach (obj; mode7Engine.worldObjects) {
						if (obj.gameObject !is null) {
							auto collision = cast(ComponentCollision)obj.gameObject.GetComponent!ComponentCollision();
							if (collision !is null) {
								collision.Render(mRenderer);
							}
						}
					}
				}
				
				mode7Engine.renderScene();
			} else {
				// Change back to white background
				SDL_SetRenderDrawColor(mRenderer, 255, 255, 255, SDL_ALPHA_OPAQUE);
				SDL_RenderClear(mRenderer);

				// Render game objects
				sceneManager.GetActiveScene().sceneTree.traverse((TreeNode* node) {
					if (node.gameObject !is null) {
						// Render texture components
						auto texture = cast(ComponentTexture)node.gameObject.GetComponent!ComponentTexture();
						if (texture !is null) {
							float angle = 0.0f;
							if (node.gameObject.GetName() == "alien") {
								auto script = node.gameObject.GetComponent!ComponentScript();
								if (script !is null) {
									angle = script.GetRotation();
								}
							}
							texture.Render(mRenderer, angle);
						}

						// Render bitmap font components
						auto bitmapFont = cast(ComponentBitmapFont)node.gameObject.GetComponent!ComponentBitmapFont();
						if (bitmapFont !is null) {
							bitmapFont.Render(mRenderer, 0.0f);  // Pass 0 angle for now
						}
					}
				});

				// Check if we should render colliders
				if (exists("show_colliders.flag")) {
					SDL_SetRenderDrawColor(mRenderer, 255, 0, 0, 100);
					sceneManager.GetActiveScene().sceneTree.traverse((TreeNode* node) {
						if (node.gameObject !is null) {
							auto collision = cast(ComponentCollision)node.gameObject.GetComponent!ComponentCollision();
							if (collision !is null) {
								collision.Render(mRenderer);
							}
						}
					});
				}

				SDL_RenderPresent(mRenderer);
			}
		}

		// Advance world one frame at a time
		enum FPS = 60;
		//Logic to round up
		enum FRAMETIME = (1000 + FPS - 1) / FPS;

		/**
		 * Advances the game world by one frame.
		 * 
		 * Maintains consistent frame timing and handles:
		 * - Input processing
		 * - Object spawning
		 * - State updates
		 * - Rendering
		 * - FPS calculation
		 */
		void AdvanceFrame(){
				uint current_timestamp = SDL_GetTicks();

				if(current_timestamp - last_timestamp >= 1000){
					int fps = num_frames;
					string FPS_text = "FPS: " ~ to!string(num_frames);
					SDL_SetWindowTitle(mWindow, FPS_text.toStringz);
					num_frames = 0;
					last_timestamp = current_timestamp;
				}

				Input();
				//writeln("input donw");

				// Check for object spawn requests before updating
				// In the GameApplication struct, add handling for Mode7 objects

				// Add to the spawn object handling section:
				if (exists("spawn_object.flag")) {
					remove("spawn_object.flag");

					if (exists("temp_object.json")) {
						try {
							auto jsonData = parseJSON(readText("temp_object.json"));
							
							// Check if this is a Mode7 object
							bool isMode7 = "is_mode7" in jsonData ? jsonData["is_mode7"].boolean : false;

							// Create the game object with appropriate coordinate handling
							GameObject* gameObject;
							if (isMode7) {
								// For Mode7 objects, use the floating point values directly
								float x = jsonData["position"]["x"].floating;
								float y = jsonData["position"]["y"].floating;
								gameObject = new GameObject(
									jsonData["name"].str,
									cast(int)(x * 800),  // Convert to screen coordinates for initial placement
									cast(int)(y * 600)   // Convert to screen coordinates for initial placement
								);
							} else {
								// For regular 2D objects, use integer coordinates
								gameObject = new GameObject(
									jsonData["name"].str,
									cast(int)jsonData["position"]["x"].integer,
									cast(int)jsonData["position"]["y"].integer
								);
							}

							// Handle bitmap text type specifically
							if ("type" in jsonData && jsonData["type"].str == "bitmap_text") {
								auto bitmapFont = new ComponentBitmapFont(
									gameObject.GetID(),
									jsonData["texture_path"].str,
									mRenderer
								);
								if ("initial_score" in jsonData) {
									bitmapFont.SetScore(cast(int)jsonData["initial_score"].integer);
								}
								gameObject.AddComponent!(ComponentType.TEXT)(bitmapFont);
							} else {

								if (isMode7) {
									// For Mode7 objects, store world coordinates as floats
									float worldX = cast(float)jsonData["position"]["x"].floating;
									float worldY = cast(float)jsonData["position"]["y"].floating;

									// Add to Mode7Engine's world objects
									if (mode7Engine !is null) {
										mode7Engine.worldObjects ~= Mode7Engine.WorldObject(
											worldX,
											worldY,
											gameObject
										);
									}
								} else {
									// For 2D objects, use integer screen coordinates
									gameObject.mX = cast(int)jsonData["position"]["x"].integer;
									gameObject.mY = cast(int)jsonData["position"]["y"].integer;
								}

								// Add components (texture, collision, script)
								if ("texture_path" in jsonData) {
									auto texture = new ComponentTexture(
										gameObject.GetID(),
										jsonData["texture_path"].str,
										mRenderer
									);
									gameObject.AddComponent!(ComponentType.TEXTURE)(texture);
								}

								if ("has_collision" in jsonData && jsonData["has_collision"].boolean) {
									auto texture = gameObject.GetComponent!ComponentTexture();

									auto collision = new ComponentCollision(
										gameObject.GetID(),
										gameObject.mX,
										gameObject.mY,
										texture.GetWidth(),
										texture.GetHeight()
									);
									gameObject.AddComponent!(ComponentType.COLLISION)(collision);
								}

								if ("has_script" in jsonData && jsonData["has_script"].boolean) {
									auto script = new ComponentScript(
										gameObject,
										jsonData["script_path"].str
									);
									gameObject.AddComponent!(ComponentType.SCRIPT)(script);
								}
							}

							if (isMode7) {
								// Add to Mode7Engine's world objects with original float coordinates
								mode7Engine.worldObjects ~= Mode7Engine.WorldObject(
									jsonData["position"]["x"].floating,
									jsonData["position"]["y"].floating,
									gameObject
								);
							}

							// Create and add node to scene tree
							auto node = new TreeNode(gameObject);
							
							// Find parent node
							TreeNode* parentNode = rootNode;
							if ("parent_node" in jsonData && jsonData["parent_node"].str != "root") {
								string parentName = jsonData["parent_node"].str;
								sceneManager.GetActiveScene().sceneTree.traverse((TreeNode* n) {
									if (n.gameObject && n.gameObject.GetName() == parentName) {
										parentNode = n;
									}
								});
							}

							// Add to scene tree
							sceneManager.GetActiveScene().sceneTree.addChild(parentNode, node);

							remove("temp_object.json");
							writeln("Created new game object: ", jsonData["name"].str);

						} catch (Exception e) {
							writeln("Error creating game object: ", e.line);
							writeln("Error creating game object: ", e.file);
							writeln("Error creating game object: ", e.info);
							writeln("Error creating game object: ", e.msg);
							write("spawn_error.json", JSONValue([
								"error": JSONValue(e.msg)
							]).toString());
						}
					}
				}

				Update();
				Render();
				
				num_frames++;

				uint time_diff = SDL_GetTicks() - current_timestamp;
				if(time_diff < FRAMETIME){
					SDL_Delay(FRAMETIME - time_diff);
				}
		}

		/**
		 * Runs the main game loop.
		 * 
		 * Continuously calls AdvanceFrame until the game is stopped.
		 */
		void RunLoop(){
				// Main application loop
				while(mGameIsRunning){
						AdvanceFrame();	
				}
		}
}