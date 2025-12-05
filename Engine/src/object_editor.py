"""!
@file object_editor.py
@brief Object editor GUI for the game engine, providing tools for scene and object management.
"""

import tkinter as tk
from tkinter import ttk, filedialog, simpledialog, messagebox
import json
import os
import time
from typing import Dict, Any, Optional
from dataclasses import dataclass
from contextlib import contextmanager

class FileFlags:
    """!
    @brief Static class containing flag file names used for inter-process communication.
    """
    RUNNING = "running.flag"
    PLACEMENT = "placement_mode.flag"
    SHOW_COLLIDERS = "show_colliders.flag"
    REQUEST_NODES = "request_nodes.flag"
    CLICK_EVENT = "click_event.flag"
    NODE_OPERATION = "node_operation.flag"
    SPAWN_OBJECT = "spawn_object.flag"
    SAVE_SCENE = "save_scene.flag"
    LOAD_SCENE = "load_scene.flag"
    REQUEST_SCENES = "request_scenes.flag"
    SCENE_OPERATION = "scene_operation.flag"
    SWITCH_SCENE = "switch_scene.flag"
    MODE_SWITCH = "mode_switch.flag"

class FileNames:
    """!
    @brief Static class containing JSON file names used for data exchange.
    """
    AVAILABLE_NODES = "available_nodes.json"
    CLICK_EVENT = "click_event.json"
    NODE_OPERATION = "node_operation.json"
    TEMP_OBJECT = "temp_object.json"
    LOAD_SCENE = "load_scene.json"
    AVAILABLE_SCENES = "available_scenes.json"
    SCENE_OPERATION = "scene_operation.json"
    SWITCH_SCENE = "switch_scene.json"
    MODE_SWITCH = "mode_switch.json"

@dataclass
class GameObjectData:
    """!
    @brief Data class representing a game object's properties.
    """
    name: str = ""
    position: Dict[str, int] = None
    texture_path: str = ""
    has_collision: bool = False
    show_colliders: bool = False
    parent_node: str = "root"
    script_path: str = ""
    has_script: bool = False

    def __post_init__(self):
        if self.position is None:
            self.position = {"x": 0, "y": 0}

class FileManager:
    """!
    @brief Utility class for handling file operations and JSON data exchange.
    """

    @staticmethod
    @contextmanager
    def write_flag(flag_name: str, content: str = "1"):
        """!
        @brief Context manager for creating and managing flag files.
        @param flag_name Name of the flag file to create
        @param content Content to write to the flag file
        """
        try:
            with open(flag_name, "w") as f:
                f.write(content)
            yield
        except Exception as e:
            print(f"Error writing flag {flag_name}: {e}")
        
    @staticmethod
    def read_json(filename: str) -> Optional[Dict]:
        try:
            if os.path.exists(filename):
                with open(filename, "r") as f:
                    return json.load(f)
        except Exception as e:
            print(f"Error reading JSON {filename}: {e}")
        return None

    @staticmethod
    def write_json(filename: str, data: Dict) -> bool:
        try:
            with open(filename, "w") as f:
                json.dump(data, f)
            return True
        except Exception as e:
            print(f"Error writing JSON {filename}: {e}")
            return False

    @staticmethod
    def flatten_hierarchy(nodes):
        """!
        @brief Converts a hierarchical node structure into a flat list of node names.
        @param nodes List of node dictionaries containing hierarchical structure
        @return List of node names in flat structure
        """
        flat_nodes = []
        def _flatten(nodes):
            for node in nodes:
                flat_nodes.append(node["name"])
                if "children" in node and node["children"]:
                    _flatten(node["children"])
        _flatten(nodes)
        return flat_nodes

class SceneTreeManager(ttk.Frame):
    """!
    @brief GUI component for managing the scene hierarchy tree.
    
    This class provides a graphical interface for managing scene nodes, including:
    - Displaying the current scene hierarchy in a tree view
    - Adding new nodes to the scene
    - Removing existing nodes from the scene
    - Refreshing the node view to reflect current scene state
    """
    def __init__(self, parent):
        """!
        @brief Initialize the SceneTreeManager.
        @param parent The parent tkinter widget
        """
        super().__init__(parent)
        self.file_manager = FileManager()
        self.setup_ui()
        self.refresh_nodes()

    def setup_ui(self):
        """!
        @brief Set up the user interface components.
        
        Creates and arranges the following UI elements:
        - Refresh button
        - Tree view with scrollbar for displaying scene hierarchy
        - Node addition controls (name entry, parent selection)
        - Node removal controls
        """
        self.refresh_button = ttk.Button(self, text="Refresh Nodes", command=self.refresh_nodes)
        self.refresh_button.pack(fill="x", padx=5, pady=2)

        tree_frame = ttk.Frame(self)
        tree_frame.pack(fill="both", expand=True, padx=5, pady=2)

        self.tree = ttk.Treeview(tree_frame, height=10)
        self.tree.heading('#0', text='Scene Hierarchy', anchor='w')
        self.tree.pack(side="left", fill="both", expand=True)

        scrollbar = ttk.Scrollbar(tree_frame, orient="vertical", command=self.tree.yview)
        scrollbar.pack(side="right", fill="y")
        self.tree.configure(yscrollcommand=scrollbar.set)

        ops_frame = ttk.Frame(self)
        ops_frame.pack(fill="x", padx=5, pady=2)

        add_frame = ttk.LabelFrame(ops_frame, text="Add Node")
        add_frame.pack(fill="x", pady=2)

        ttk.Label(add_frame, text="Node Name:").pack(side="left", padx=2)
        self.new_node_name = ttk.Entry(add_frame, width=20)
        self.new_node_name.pack(side="left", padx=2)

        ttk.Label(add_frame, text="Parent:").pack(side="left", padx=2)
        self.parent_node_var = tk.StringVar()
        self.parent_node_combo = ttk.Combobox(add_frame, textvariable=self.parent_node_var)
        self.parent_node_combo.pack(side="left", padx=2)

        ttk.Button(add_frame, text="Add Node", command=self.add_node).pack(side="left", padx=2)

        remove_frame = ttk.LabelFrame(ops_frame, text="Remove Node")
        remove_frame.pack(fill="x", pady=2)

        ttk.Label(remove_frame, text="Select Node:").pack(side="left", padx=2)
        self.remove_node_var = tk.StringVar()
        self.remove_node_combo = ttk.Combobox(remove_frame, textvariable=self.remove_node_var)
        self.remove_node_combo.pack(side="left", padx=2)

        ttk.Button(remove_frame, text="Remove Node", command=self.remove_node).pack(side="left", padx=2)

    def refresh_nodes(self):
        """!
        @brief Updates the scene tree view with current node data from the engine.
        
        Requests current node data from the game engine and updates the tree view
        and combo boxes with the latest hierarchy information.
        
        @throws MessageBox error if node refresh operation fails
        """
        with self.file_manager.write_flag(FileFlags.REQUEST_NODES):
            time.sleep(0.1)

            try:
                node_data = self.file_manager.read_json(FileNames.AVAILABLE_NODES)
                if not node_data:
                    return

                for item in self.tree.get_children():
                    self.tree.delete(item)
                
                flat_nodes = self.file_manager.flatten_hierarchy(node_data)
                
                def build_tree(nodes, parent=''):
                    for node in nodes:
                        node_id = self.tree.insert(parent, 'end', text=node["name"], open=True)
                        if "children" in node and node["children"]:
                            build_tree(node["children"], node_id)
                
                build_tree(node_data)
                
                self.parent_node_combo['values'] = flat_nodes
                self.remove_node_combo['values'] = flat_nodes
                    
            except Exception as e:
                messagebox.showerror("Error", f"Failed to refresh nodes: {str(e)}")

    def add_node(self):
        """!
        @brief Creates a new node in the scene hierarchy.
        
        Validates input and creates a new node with the specified name and parent.
        Updates the scene hierarchy after successful node creation.
        
        @throws MessageBox error if:
        - Node name is empty
        - Parent node is not selected
        - Node name already exists
        """
        name = self.new_node_name.get().strip()
        parent = self.parent_node_var.get()

        if not name:
            messagebox.showerror("Error", "Please enter a node name")
            return

        if not parent:
            messagebox.showerror("Error", "Please select a parent node")
            return

        with self.file_manager.write_flag(FileFlags.REQUEST_NODES):
            time.sleep(0.1)
            
            node_data = self.file_manager.read_json(FileNames.AVAILABLE_NODES)
            if node_data:
                flat_nodes = self.file_manager.flatten_hierarchy(node_data)
                if name in flat_nodes:
                    messagebox.showerror("Error", "A node with this name already exists")
                    return

        data = {
            "action": "add_node",
            "name": name,
            "parent": parent
        }
        
        self.file_manager.write_json(FileNames.NODE_OPERATION, data)
        with self.file_manager.write_flag(FileFlags.NODE_OPERATION):
            self.new_node_name.delete(0, tk.END)
            time.sleep(0.1)
            self.refresh_nodes()

    def remove_node(self):
        """!
        @brief Removes a node from the scene hierarchy.
        
        Removes the selected node and optionally reparents its children.
        Updates the scene hierarchy after successful node removal.
        
        @throws MessageBox error if:
        - No node is selected for removal
        - Attempting to remove the root node
        """
        node = self.remove_node_var.get()
        if not node:
            messagebox.showerror("Error", "Please select a node to remove")
            return
        
        if node == "Root":
            messagebox.showerror("Error", "Cannot remove Root node")
            return

        data = {
            "action": "remove_node",
            "name": node,
            "reparent": True
        }
        
        self.file_manager.write_json(FileNames.NODE_OPERATION, data)
        with self.file_manager.write_flag(FileFlags.NODE_OPERATION):
            time.sleep(0.1)
            self.refresh_nodes()

class ObjectEditor(ttk.Frame):
    """!
    @brief Main editor interface for creating and modifying game objects.
    """
    def __init__(self, parent):
        """!
        @brief Initialize the object editor.
        @param parent Parent tkinter widget
        """
        super().__init__(parent)
        self.parent = parent
        self.file_manager = FileManager()
        self.current_object = GameObjectData()
        self.placement_mode = False
        self.is_mode7 = False
        
        self.setup_ui()
        
        with self.file_manager.write_flag(FileFlags.RUNNING, "running"):
            self.update_loop()

    def setup_ui(self):
        """!
        @brief Set up the user interface components for the object editor.
        @note Creates and arranges all UI elements including fields, buttons, and frames
        """
        editor_frame = ttk.LabelFrame(self)
        editor_frame.pack(fill="both", expand=True, padx=5, pady=5)

        # Name field
        name_frame = ttk.Frame(editor_frame)
        name_frame.pack(fill="x", padx=5, pady=2)
        ttk.Label(name_frame, text="Name:").pack(side="left")
        self.name_entry = ttk.Entry(name_frame)
        self.name_entry.pack(side="left", fill="x", expand=True)

        # Texture field
        texture_frame = ttk.Frame(editor_frame)
        texture_frame.pack(fill="x", padx=5, pady=2)
        ttk.Label(texture_frame, text="Texture:").pack(side="left")
        self.texture_label = ttk.Label(texture_frame, text="No texture selected")
        self.texture_label.pack(side="left")
        ttk.Button(texture_frame, text="Select Texture", command=self.select_texture).pack(side="right")

        # Parent node field
        parent_frame = ttk.Frame(editor_frame)
        parent_frame.pack(fill="x", padx=5, pady=2)
        ttk.Label(parent_frame, text="Parent:").pack(side="left")
        self.parent_label = ttk.Label(parent_frame, text="No parent selected")
        self.parent_label.pack(side="left")
        ttk.Button(parent_frame, text="Select Parent", command=self.select_parent_node).pack(side="right")

        # Script field
        script_frame = ttk.Frame(editor_frame)
        script_frame.pack(fill="x", padx=5, pady=2)
        ttk.Label(script_frame, text="Script:").pack(side="left")
        self.script_label = ttk.Label(script_frame, text="No script selected")
        self.script_label.pack(side="left")
        ttk.Button(script_frame, text="Select Script", command=self.select_script).pack(side="right")

        # Checkboxes
        checkbox_frame = ttk.Frame(editor_frame)
        checkbox_frame.pack(fill="x", padx=5, pady=2)
        
        self.collision_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(checkbox_frame, text="Add Collision Component", 
                       variable=self.collision_var, 
                       command=self.toggle_collision).pack(side="top", anchor="w")
        
        self.show_colliders_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(checkbox_frame, text="Show All Colliders", 
                       variable=self.show_colliders_var, 
                       command=self.toggle_show_colliders).pack(side="top", anchor="w")

        # Add mode switch button after checkbox_frame
        mode_frame = ttk.Frame(editor_frame)
        mode_frame.pack(fill="x", padx=5, pady=2)
        self.mode7_var = tk.BooleanVar(value=False)
        self.mode_button = ttk.Button(mode_frame, text="Switch to Mode7", 
                                    command=self.toggle_mode)
        self.mode_button.pack(fill="x")

        # Modify placement button frame to include coordinate inputs for Mode7
        self.placement_frame = ttk.LabelFrame(editor_frame, text="Object Placement")
        self.placement_frame.pack(fill="x", padx=5, pady=2)

        # 2D placement button
        self.placement_button = ttk.Button(self.placement_frame, 
                                         text="Click to Place Object",
                                         command=self.toggle_placement_mode)
        self.placement_button.pack(fill="x", pady=2)

        # Mode7 coordinate inputs (hidden by default)
        self.mode7_frame = ttk.Frame(self.placement_frame)
        coord_frame = ttk.Frame(self.mode7_frame)
        coord_frame.pack(fill="x", pady=2)
        
        ttk.Label(coord_frame, text="X:").pack(side="left")
        self.world_x = ttk.Entry(coord_frame, width=10)
        self.world_x.pack(side="left", padx=2)
        
        ttk.Label(coord_frame, text="Y:").pack(side="left")
        self.world_y = ttk.Entry(coord_frame, width=10)
        self.world_y.pack(side="left", padx=2)
        
        ttk.Button(self.mode7_frame, text="Place in World", 
                  command=self.place_mode7_object).pack(fill="x", pady=2)

        # Status message
        self.status_label = ttk.Label(editor_frame, text="", wraplength=250)
        self.status_label.pack(fill="x", padx=5, pady=2)

        # Add Mode7 settings frame (initially hidden)
        self.mode7_settings_frame = ttk.LabelFrame(editor_frame, text="Mode7 Settings")
        
        # Ground texture selection
        ground_frame = ttk.Frame(self.mode7_settings_frame)
        ground_frame.pack(fill="x", padx=5, pady=2)
        ttk.Label(ground_frame, text="Ground Texture:").pack(side="left")
        self.ground_texture_label = ttk.Label(ground_frame, text="No texture selected")
        self.ground_texture_label.pack(side="left")
        ttk.Button(ground_frame, text="Select Ground", 
                  command=self.select_ground_texture).pack(side="right")

        # Sky texture selection
        sky_frame = ttk.Frame(self.mode7_settings_frame)
        sky_frame.pack(fill="x", padx=5, pady=2)
        ttk.Label(sky_frame, text="Sky Texture:").pack(side="left")
        self.sky_texture_label = ttk.Label(sky_frame, text="No texture selected")
        self.sky_texture_label.pack(side="left")
        ttk.Button(sky_frame, text="Select Sky", 
                  command=self.select_sky_texture).pack(side="right")

        # Apply textures button
        ttk.Button(self.mode7_settings_frame, text="Apply Mode7 Textures",
                  command=self.apply_mode7_textures).pack(fill="x", padx=5, pady=2)

        # Add button for bitmap text
        bitmap_text_frame = ttk.Frame(editor_frame)
        bitmap_text_frame.pack(fill="x", padx=5, pady=2)
        ttk.Button(bitmap_text_frame, text="Add Bitmap Text", 
                  command=self.open_bitmap_text_window).pack(fill="x")

    def toggle_collision(self):
        """!
        @brief Toggle collision component for the current object.
        """
        self.current_object.has_collision = self.collision_var.get()
    
    def toggle_show_colliders(self):
        """!
        @brief Toggle visibility of all colliders in the scene.
        @note Creates or removes show_colliders flag file
        """
        is_checked = self.show_colliders_var.get()
        self.current_object.show_colliders = is_checked
        try:
            if is_checked:
                with self.file_manager.write_flag(FileFlags.SHOW_COLLIDERS, "show"):
                    pass
            elif os.path.exists(FileFlags.SHOW_COLLIDERS):
                os.remove(FileFlags.SHOW_COLLIDERS)
        except Exception as e:
            self.set_status(f"Error toggling collider visibility: {e}")

    def toggle_placement_mode(self):
        """!
        @brief Toggle object placement mode for 2D objects.
        @note Validates object properties before enabling placement
        """
        if not self.current_object.texture_path:
            self.set_status("Please select a texture first!")
            return
        if not self.name_entry.get():
            self.set_status("Please enter a name first!")
            return
        if not self.current_object.parent_node:
            self.set_status("Please select a parent node first!")
            return

        # Don't toggle placement mode if in Mode7
        if self.is_mode7:
            return

        self.placement_mode = not self.placement_mode
        if self.placement_mode:
            with self.file_manager.write_flag(FileFlags.PLACEMENT, "placing"):
                self.placement_button.configure(style="Accent.TButton")
                self.set_status("Click in game window to place object\nPress ESC to cancel")
        else:
            if os.path.exists(FileFlags.PLACEMENT):
                os.remove(FileFlags.PLACEMENT)
            self.placement_button.configure(style="TButton")
            self.set_status("")

    def select_texture(self):
        """!
        @brief Open file dialog to select a texture for the current object.
        """
        filename = filedialog.askopenfilename(
            initialdir="./assets/images",
            title="Select Texture File",
            filetypes=(("BMP files", "*.bmp"), ("All files", "*.*"))
        )
        if filename:
            self.current_object.texture_path = filename
            self.texture_label.configure(text=os.path.basename(filename))

    def select_script(self):
        """!
        @brief Open file dialog to select a script file for the current object.
        """
        filename = filedialog.askopenfilename(
            initialdir="./scripts",
            title="Select Script File",
            filetypes=(("D files", "*.d"), ("All files", "*.*"))
        )
        if filename:
            self.current_object.script_path = filename
            self.current_object.has_script = True
            self.script_label.configure(text=os.path.basename(filename))
            self.set_status(f"Script selected: {filename}")

    

    def select_parent_node(self):
        """!
        @brief Open dialog to select a parent node for the current object.
        @note Requests and displays available nodes from the engine
        """
        try:
            with self.file_manager.write_flag(FileFlags.REQUEST_NODES, "request"):
                time.sleep(0.1)
                
                node_data = self.file_manager.read_json(FileNames.AVAILABLE_NODES)
                if not node_data:
                    return
                
                flat_nodes = self.file_manager.flatten_hierarchy(node_data)
                parent = simpledialog.askstring("Select Parent Node", 
                                          "Enter parent node name\nAvailable nodes: " + ", ".join(flat_nodes))
                
                if parent:
                    self.current_object.parent_node = parent
                    self.parent_label.configure(text=parent)
                    self.set_status(f"Parent node set to: {parent}")
            
            if os.path.exists(FileNames.AVAILABLE_NODES):
                os.remove(FileNames.AVAILABLE_NODES)
        except Exception as e:
            self.set_status(f"Error selecting parent: {str(e)}")

    def create_game_object(self, x, y, is_mode7=False):
        """!
        @brief Creates a new game object at the specified coordinates.
        @param x X coordinate for object placement
        @param y Y coordinate for object placement
        @param is_mode7 Boolean indicating if object should be created in Mode7 space
        @throws MessageBox error if object creation fails
        """
        try:
            with self.file_manager.write_flag(FileFlags.REQUEST_NODES):
                time.sleep(0.1)
                
                node_data = self.file_manager.read_json(FileNames.AVAILABLE_NODES)
                if node_data:
                    flat_nodes = self.file_manager.flatten_hierarchy(node_data)
                    if self.name_entry.get() in flat_nodes:
                        messagebox.showerror("Error", "A node with this name already exists")
                        return

            # Convert coordinates to appropriate type based on mode
            position = {
                "x": float(x) if is_mode7 else int(x),
                "y": float(y) if is_mode7 else int(y)
            }

            object_data = {
                "type": "custom",
                "name": self.name_entry.get(),
                "position": position,
                "texture_path": self.current_object.texture_path,
                "has_collision": self.current_object.has_collision,
                "has_script": self.current_object.has_script,
                "script_path": self.current_object.script_path,
                "parent_node": self.current_object.parent_node,
                "is_mode7": is_mode7
            }

            self.file_manager.write_json(FileNames.TEMP_OBJECT, object_data)
            with self.file_manager.write_flag(FileFlags.SPAWN_OBJECT):
                time.sleep(0.1)
                
                # Check for spawn errors
                if os.path.exists("spawn_error.json"):
                    error_data = self.file_manager.read_json("spawn_error.json")
                    if error_data and "error" in error_data:
                        messagebox.showerror("Error", error_data["error"])
                        os.remove("spawn_error.json")
                        return

                self.set_status(f"Created object at ({x}, {y})")

        except Exception as e:
            self.set_status(f"Error: {str(e)}")

    def set_status(self, message: str):
        """!
        @brief Update the status message in the UI.
        @param message Status message to display
        """
        self.status_label.configure(text=message)

    def update_loop(self):
        """!
        @brief Main update loop for the editor.
        @note Handles click events and checks running status
        """
        if not os.path.exists(FileFlags.RUNNING):
            self.parent.quit()
            return

        if os.path.exists(FileFlags.CLICK_EVENT):
            try:
                click_data = self.file_manager.read_json(FileNames.CLICK_EVENT)
                if click_data and self.placement_mode:
                    self.create_game_object(click_data['x'], click_data['y'])
            finally:
                for file in [FileFlags.CLICK_EVENT, FileNames.CLICK_EVENT]:
                    if os.path.exists(file):
                        os.remove(file)

        self.after(16, self.update_loop)

    def toggle_mode(self):
        """!
        @brief Switches between 2D and Mode7 editing modes.
        """
        self.is_mode7 = not self.is_mode7
        mode_text = "Switch to 2D" if self.is_mode7 else "Switch to Mode7"
        self.mode_button.configure(text=mode_text)
        
        # Show/hide appropriate controls
        if self.is_mode7:
            self.placement_button.pack_forget()
            self.mode7_frame.pack(fill="x")
            self.mode7_settings_frame.pack(fill="x", padx=5, pady=2)  # Show Mode7 settings
        else:
            self.mode7_frame.pack_forget()
            self.mode7_settings_frame.pack_forget()  # Hide Mode7 settings
            self.placement_button.pack(fill="x")

        # Notify game about mode switch
        data = {"mode7": self.is_mode7}
        self.file_manager.write_json(FileNames.MODE_SWITCH, data)
        with self.file_manager.write_flag(FileFlags.MODE_SWITCH):
            self.set_status(f"Switched to {'Mode7' if self.is_mode7 else '2D'} mode")

    def place_mode7_object(self):
        """!
        @brief Place an object in Mode7 space using coordinate inputs.
        @note Validates object properties and coordinate range
        """
        if not self.current_object.texture_path:
            self.set_status("Please select a texture first!")
            return
        if not self.name_entry.get():
            self.set_status("Please enter a name first!")
            return
        if not self.current_object.parent_node:
            self.set_status("Please select a parent node first!")
            return

        try:
            x = float(self.world_x.get())
            y = float(self.world_y.get())
            
            if not (0 <= x <= 1 and 0 <= y <= 1):
                self.set_status("Coordinates must be between 0 and 1")
                return
            
            self.create_game_object(x, y, is_mode7=True)
            self.set_status(f"Created Mode7 object at ({x}, {y})")
            
        except ValueError:
            self.set_status("Please enter valid coordinates (0-1)")

    def select_ground_texture(self):
        """!
        @brief Open file dialog to select Mode7 ground texture.
        """
        filename = filedialog.askopenfilename(
            initialdir="./assets/images",
            title="Select Ground Texture",
            filetypes=(("BMP files", "*.bmp"), ("All files", "*.*"))
        )
        if filename:
            self.ground_texture_path = filename
            self.ground_texture_label.configure(text=os.path.basename(filename))

    def select_sky_texture(self):
        """!
        @brief Open file dialog to select Mode7 sky texture.
        """
        filename = filedialog.askopenfilename(
            initialdir="./assets/images",
            title="Select Sky Texture",
            filetypes=(("BMP files", "*.bmp"), ("All files", "*.*"))
        )
        if filename:
            self.sky_texture_path = filename
            self.sky_texture_label.configure(text=os.path.basename(filename))

    def apply_mode7_textures(self):
        """!
        @brief Apply selected ground and sky textures to Mode7 scene.
        @note Validates texture selection before applying
        """
        if not hasattr(self, 'ground_texture_path') or not hasattr(self, 'sky_texture_path'):
            self.set_status("Please select both ground and sky textures")
            return

        data = {
            "ground_texture": self.ground_texture_path,
            "sky_texture": self.sky_texture_path
        }
        self.file_manager.write_json("mode7_textures.json", data)
        with self.file_manager.write_flag("mode7_textures.flag"):
            self.set_status("Mode7 textures updated")

    def open_bitmap_text_window(self):
        """!
        @brief Open dialog window for creating bitmap text objects.
        """
        BitmapTextWindow(self)

class SceneTreeWindow(tk.Toplevel):
    """!
    @brief Top-level window for managing the scene hierarchy tree.
    """
    def __init__(self, parent):
        """!
        @brief Initialize the SceneTreeWindow.
        @param parent The parent tkinter widget
        """
        super().__init__(parent)
        self.parent = parent
        self.title("Scene Tree Manager")
        self.scene_tree = SceneTreeManager(self)
        self.scene_tree.pack(fill="both", expand=True)
        self.protocol("WM_DELETE_WINDOW", self.parent.on_closing)

class ObjectEditorWindow(tk.Toplevel):
    """!
    @brief Top-level window for editing game object properties.
    """
    def __init__(self, parent):
        """!
        @brief Initialize the ObjectEditorWindow.
        @param parent The parent tkinter widget
        """
        super().__init__(parent)
        self.parent = parent
        self.title("Object Editor")
        self.object_editor = ObjectEditor(self)
        self.object_editor.pack(fill="both", expand=True)
        self.protocol("WM_DELETE_WINDOW", self.parent.on_closing)

class SceneManagerWindow(tk.Toplevel):
    """!
    @brief Top-level window for managing game scenes.
    """
    def __init__(self, parent):
        """!
        @brief Initialize the SceneManagerWindow.
        @param parent The parent tkinter widget
        """
        super().__init__(parent)
        self.parent = parent
        self.title("Scene Manager")
        self.object_editor = SceneManager(self)
        self.object_editor.pack(fill="both", expand=True)
        self.protocol("WM_DELETE_WINDOW", self.parent.on_closing)

class SceneManager(ttk.Frame):
    """!
    @brief Interface for managing game scenes, including creation, loading, and switching.
    """
    def __init__(self, parent):
        super().__init__(parent)
        self.file_manager = FileManager()
        self.setup_ui()

    def setup_ui(self):
        """!
        @brief Initializes and arranges all UI components for scene management.
        """
        list_frame = ttk.LabelFrame(self, text="Scenes")
        list_frame.pack(fill="both", expand=True, padx=5, pady=5)

        self.scene_listbox = tk.Listbox(list_frame, height=6)
        self.scene_listbox.pack(side="left", fill="both", expand=True)
        
        scrollbar = ttk.Scrollbar(list_frame, orient="vertical", command=self.scene_listbox.yview)
        scrollbar.pack(side="right", fill="y")
        self.scene_listbox.configure(yscrollcommand=scrollbar.set)

        # Buttons Frame
        button_frame = ttk.Frame(self)
        button_frame.pack(fill="x", padx=5, pady=5)

        # New Scene
        new_frame = ttk.Frame(button_frame)
        new_frame.pack(fill="x", pady=2)
        self.new_scene_entry = ttk.Entry(new_frame)
        self.new_scene_entry.pack(side="left", fill="x", expand=True)
        ttk.Button(new_frame, text="New Scene", command=self.create_scene).pack(side="right", padx=2)

        # Save/Load buttons
        save_load_frame = ttk.Frame(button_frame)
        save_load_frame.pack(fill="x", pady=2)
        ttk.Button(save_load_frame, text="Save Scene", command=self.save_scene).pack(side="left", padx=2, expand=True, fill="x")
        ttk.Button(save_load_frame, text="Load Scene", command=self.load_scene).pack(side="right", padx=2, expand=True, fill="x")

        # Switch/Delete buttons
        switch_delete_frame = ttk.Frame(button_frame)
        switch_delete_frame.pack(fill="x", pady=2)
        ttk.Button(switch_delete_frame, text="Switch to Scene", command=self.switch_scene).pack(side="left", padx=2, expand=True, fill="x")
        ttk.Button(switch_delete_frame, text="Delete Scene", command=self.delete_scene).pack(side="right", padx=2, expand=True, fill="x")
        ttk.Button(button_frame, text="Refresh Scene List", command=self.refresh_scenes).pack(fill="x", pady=2)

        self.refresh_scenes()

    def refresh_scenes(self):
        """!
        @brief Updates the scene list by requesting current scenes from the engine.
        """
        with self.file_manager.write_flag(FileFlags.REQUEST_SCENES):
            time.sleep(0.1)
            scenes = self.file_manager.read_json(FileNames.AVAILABLE_SCENES)
            if scenes:
                self.scene_listbox.delete(0, tk.END)
                for scene in scenes["scenes"]:
                    self.scene_listbox.insert(tk.END, scene)

    def create_scene(self):
        """!
        @brief Creates a new scene with the specified name.
        @throws MessageBox error if name is empty
        """
        name = self.new_scene_entry.get().strip()
        if not name:
            messagebox.showerror("Error", "Please enter a scene name")
            return

        data = {"action": "create", "name": name}
        self.file_manager.write_json(FileNames.SCENE_OPERATION, data)
        with self.file_manager.write_flag(FileFlags.SCENE_OPERATION):
            time.sleep(0.1)
            self.new_scene_entry.delete(0, tk.END)
            self.refresh_scenes()

    def switch_scene(self):
        """!
        @brief Switches to the selected scene in the game engine.
        @throws MessageBox error if no scene is selected
        """
        selection = self.scene_listbox.curselection()
        if not selection:
            messagebox.showerror("Error", "Please select a scene")
            return

        scene_name = self.scene_listbox.get(selection[0])
        data = {"scene": scene_name}
        self.file_manager.write_json(FileNames.SWITCH_SCENE, data)
        with self.file_manager.write_flag(FileFlags.SWITCH_SCENE):
            time.sleep(0.1)  # Give the engine time to process
            # Refresh the scene tree after switching
            if hasattr(self.master, 'scene_tree_manager'):
                self.master.scene_tree_manager.refresh_nodes()

    def delete_scene(self):
        """!
        @brief Deletes the selected scene after confirmation.
        @throws MessageBox error if main scene or no scene selected
        """
        selection = self.scene_listbox.curselection()
        if not selection:
            messagebox.showerror("Error", "Please select a scene")
            return

        scene_name = self.scene_listbox.get(selection[0])
        if scene_name == "main":
            messagebox.showerror("Error", "Cannot delete the main scene")
            return

        if messagebox.askyesno("Confirm Delete", f"Delete scene '{scene_name}'?"):
            data = {"action": "delete", "name": scene_name}
            self.file_manager.write_json(FileNames.SCENE_OPERATION, data)
            with self.file_manager.write_flag(FileFlags.SCENE_OPERATION):
                time.sleep(0.1)
                self.refresh_scenes()

    def save_scene(self):
        """!
        @brief Saves the current scene to a JSON file.
        @throws MessageBox error if save operation fails
        """
        try:
            # Get active scene name from JSON file
            active_scene = None
            if os.path.exists("active_scene.json"):
                scene_data = self.file_manager.read_json("active_scene.json")
                if scene_data and "activeName" in scene_data:
                    active_scene = scene_data["activeName"]
            
            if not active_scene:
                messagebox.showerror("Error", "Could not determine active scene")
                return
            
            # Create saves directory if it doesn't exist
            save_dir = "./saves"
            if not os.path.exists(save_dir):
                os.makedirs(save_dir)
            
            # Open file dialog with default name based on scene
            filename = filedialog.asksaveasfilename(
                initialdir=save_dir,
                title="Save Scene",
                initialfile=f"{active_scene}.json",
                defaultextension=".json",
                filetypes=(("JSON files", "*.json"), ("All files", "*.*"))
            )
            
            if filename:  # User didn't cancel
                self.file_manager.write_json(FileNames.LOAD_SCENE, {"path": filename})
                with self.file_manager.write_flag(FileFlags.SAVE_SCENE, "save"):
                    time.sleep(0.1)
                    messagebox.showinfo("Success", f"Scene saved as: {filename}")
        except Exception as e:
            messagebox.showerror("Error", f"Error saving scene: {str(e)}")

    def load_scene(self):
        """!
        @brief Loads a scene from a JSON file.
        @throws MessageBox error if load operation fails
        """
        filename = filedialog.askopenfilename(
            initialdir="./saves",
            title="Load Scene",
            filetypes=(("JSON files", "*.json"), ("All files", "*.*"))
        )
        if filename:
            self.file_manager.write_json(FileNames.LOAD_SCENE, {"path": filename})
            with self.file_manager.write_flag(FileFlags.LOAD_SCENE, "load"):
                time.sleep(0.1)
                self.refresh_scenes()
                messagebox.showinfo("Success", "Scene loaded successfully")

class BitmapTextWindow(tk.Toplevel):
    """!
    @brief Dialog window for creating bitmap text objects in the scene.
    """
    def __init__(self, parent):
        super().__init__(parent)
        self.parent = parent
        self.title("Add Bitmap Text")
        self.file_manager = parent.file_manager
        
        # Window settings
        self.geometry("300x200")
        self.resizable(False, False)
        
        # Create UI elements
        self.setup_ui()
    
    def setup_ui(self):
        """!
        @brief Initializes and arranges all UI components for bitmap text creation.
        """
        name_frame = ttk.Frame(self)
        name_frame.pack(fill="x", padx=5, pady=2)
        ttk.Label(name_frame, text="Name:").pack(side="left")
        self.name_entry = ttk.Entry(name_frame)
        self.name_entry.pack(side="left", fill="x", expand=True)

        # Parent node selection
        parent_frame = ttk.Frame(self)
        parent_frame.pack(fill="x", padx=5, pady=2)
        ttk.Label(parent_frame, text="Parent:").pack(side="left")
        self.parent_label = ttk.Label(parent_frame, text="No parent selected")
        self.parent_label.pack(side="left")
        ttk.Button(parent_frame, text="Select Parent", command=self.select_parent_node).pack(side="right")

        # Position fields
        pos_frame = ttk.Frame(self)
        pos_frame.pack(fill="x", padx=5, pady=2)
        
        # X position
        ttk.Label(pos_frame, text="X:").pack(side="left")
        self.x_entry = ttk.Entry(pos_frame, width=6)
        self.x_entry.pack(side="left", padx=2)
        self.x_entry.insert(0, "10")
        
        # Y position
        ttk.Label(pos_frame, text="Y:").pack(side="left")
        self.y_entry = ttk.Entry(pos_frame, width=6)
        self.y_entry.pack(side="left", padx=2)
        self.y_entry.insert(0, "10")

        # Initial score
        score_frame = ttk.Frame(self)
        score_frame.pack(fill="x", padx=5, pady=2)
        ttk.Label(score_frame, text="Initial Score:").pack(side="left")
        self.score_entry = ttk.Entry(score_frame, width=6)
        self.score_entry.pack(side="left", padx=2)
        self.score_entry.insert(0, "0")

        # Create button
        ttk.Button(self, text="Create Bitmap Text", command=self.create_bitmap_text).pack(pady=10)

        # Status message
        self.status_label = ttk.Label(self, text="", wraplength=250)
        self.status_label.pack(fill="x", padx=5, pady=2)

    def select_parent_node(self):
        """!
        @brief Opens dialog to select parent node for bitmap text object.
        @throws Exception if node selection fails
        """
        try:
            with self.file_manager.write_flag(FileFlags.REQUEST_NODES, "request"):
                time.sleep(0.1)
                
                node_data = self.file_manager.read_json(FileNames.AVAILABLE_NODES)
                if not node_data:
                    return
                
                flat_nodes = self.file_manager.flatten_hierarchy(node_data)
                parent = simpledialog.askstring("Select Parent Node", 
                                          "Enter parent node name\nAvailable nodes: " + ", ".join(flat_nodes))
                
                if parent:
                    self.parent_node = parent
                    self.parent_label.configure(text=parent)
                    self.status_label.configure(text=f"Parent node set to: {parent}")
        except Exception as e:
            self.status_label.configure(text=f"Error selecting parent: {str(e)}")

    def create_bitmap_text(self):
        """!
        @brief Creates a new bitmap text object with specified properties.
        @throws Exception if required fields are missing or invalid
        """
        try:
            if not hasattr(self, 'parent_node'):
                self.status_label.configure(text="Please select a parent node first!")
                return

            if not self.name_entry.get():
                self.status_label.configure(text="Please enter a name!")
                return

            object_data = {
                "type": "bitmap_text",
                "name": self.name_entry.get(),
                "position": {
                    "x": int(self.x_entry.get()),
                    "y": int(self.y_entry.get())
                },
                "initial_score": int(self.score_entry.get()),
                "parent_node": self.parent_node,
                "texture_path": "./assets/images/textspritesheet.bmp"  # Updated path
            }

            self.file_manager.write_json(FileNames.TEMP_OBJECT, object_data)
            with self.file_manager.write_flag(FileFlags.SPAWN_OBJECT):
                time.sleep(0.1)
                self.status_label.configure(text="Bitmap text created successfully!")

        except Exception as e:
            self.status_label.configure(text=f"Error: {str(e)}")

class MainApplication(tk.Tk):
    """!
    @brief Main application window managing editor components and cleanup.
    """
    def __init__(self):
        super().__init__()
        self.withdraw()
        
        self.scene_tree_window = SceneTreeWindow(self)
        self.object_editor_window = ObjectEditorWindow(self)
        self.scene_manager_window = SceneManagerWindow(self)
        
        self.scene_tree_window.geometry("+50+50")
        self.object_editor_window.geometry("+400+50")
        self.scene_manager_window.geometry("+750+50")
        
        self.protocol("WM_DELETE_WINDOW", self.on_closing)
    
    def on_closing(self):
        """!
        @brief Handles cleanup operations when closing the application.
        @note Removes all flag files and terminates the application
        """
        try:
            for flag_file in [
                FileFlags.SHOW_COLLIDERS,
                FileFlags.RUNNING,
                FileFlags.PLACEMENT
            ]:
                if os.path.exists(flag_file):
                    os.remove(flag_file)
        except Exception as e:
            print(f"Error during cleanup: {e}")
        finally:
            self.quit()

if __name__ == "__main__":
    try:
        app = MainApplication()
        app.mainloop()
    except Exception as e:
        print(f"Error starting editor: {e}")