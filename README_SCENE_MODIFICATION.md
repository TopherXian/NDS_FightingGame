# Modifying dummy_ryu.tscn with AI Components

Since `.tscn` files are Godot's scene format and should be edited through the Godot Editor rather than as text files, follow these step-by-step instructions to add the AI system to the dummy_ryu character.

## Steps to Modify dummy_ryu.tscn

1. **Open the Godot Project and Scene**
   - Launch the Godot Engine
   - Open your fighting game project
   - Open the `dummy_ryu.tscn` scene from the Characters directory

2. **Add the AIController Node**
   - Right-click on the root `Dummy_Ryu` node in the scene tree
   - Select "Add Child Node"
   - Choose "Node" as the type
   - Name it "AIController"

3. **Add Script to AIController Node**
   - Select the new AIController node
   - In the Inspector panel, click on the "Script" dropdown
   - Select "New Script"
   - Name it "ai_controller.gd"
   - Click "Create"
   - Replace the default script content with the code below:

```gdscript
extends Node

# This node serves as a container for our AI system components
# The actual AI logic is implemented in the scripts we've created

func _ready():
	# The components are instantiated in test.gd, so this script
	# mainly serves as an organizational container
	print("AI Controller initialized")
```

4. **Add Data Collection Reference**
   - Right-click on the AIController node
   - Select "Add Child Node"
   - Choose "Node" as the type
   - Name it "DataCollectionRef"

5. **Add Difficulty Adjuster Reference**
   - Right-click on the AIController node
   - Select "Add Child Node"
   - Choose "Node" as the type
   - Name it "DifficultyAdjusterRef"

6. **Add Debug UI for AI Status (Optional)**
   - Right-click on the root `Dummy_Ryu` node
   - Select "Add Child Node"
   - Choose "CanvasLayer" as the type
   - Name it "DebugUI"
   
   - Right-click on the DebugUI node
   - Select "Add Child Node"
   - Choose "Label" as the type
   - Name it "AIStatusLabel"
   
   - In the Inspector panel for AIStatusLabel:
	 - Set Position to (10, 120)
	 - Set Size to (300, 100)
	 - Set Text to "AI Status: Initializing..."
	 - Set a readable font size and color

7. **Configure Export Variables (if needed)**
   - Select the root `Dummy_Ryu` node
   - In the Inspector panel, add the following export variables if they don't exist:
	 - `export var debug_mode: bool = true`
	 - `export var initial_difficulty: float = 0.5`

8. **Save the Scene**
   - Save the modified scene (Ctrl+S or File > Save)

## Verify Script Implementation

Make sure you've implemented all required scripts:
- `Scripts/training_data_collector.gd`
- `Scripts/dummy_ryu_ai.gd`
- `Scripts/difficulty_adjuster.gd`
- Modified `Scripts/test.gd`

## Post-Implementation Testing

After completing these modifications:

1. Run the game scene with both the player and dummy_ryu
2. Check the console for initialization messages
3. Verify that the dummy_ryu character responds with AI-driven behavior
4. Confirm that data collection is functioning (check user:// directory for saved data)
5. Test if difficulty adjustment works by winning/losing matches

## Debugging

If the AI system doesn't initialize properly:

1. Check for errors in the Godot output panel
2. Verify that all required scripts are in the correct locations
3. Ensure all nodes are named correctly and match the references in the scripts
4. Check that the test.gd script is properly attached to the Dummy_Ryu node

## Notes on Improving the System

- Add more animations for the different AI actions
- Implement proper attack animations with appropriate hitboxes
- Create a UI to display current difficulty and AI status
- Add training mode toggle to collect more data
- Consider implementing a separate thread for LSTM calculations
