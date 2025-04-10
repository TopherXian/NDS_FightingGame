# Setting Up the Fighting Game with AI

This guide will help you set up and run the main game scene with the AI opponent.

## Setting Up the Game Scene

1. **Open the Godot Project**
   - Launch the Godot Engine
   - Open your fighting game project

2. **Create the Game Scene**
   - Follow these steps to create a new game scene:

## Step-by-Step Scene Creation

1. **Create a New Scene**
   - Click File > New Scene
   - Select "Node2D" as the root node
   - Rename it to "GameScene"

2. **Add the Game Manager Script**
   - With the GameScene node selected, attach the game_scene_manager.gd script
   - Click the script icon in the inspector and select "New Script"
   - Name it "game_scene_manager.gd" and click "Create"
   - Replace the default script content with the provided script

3. **Add Ground/Arena**
   - Right-click on GameScene and select "Add Child Node"
   - Choose "StaticBody2D" and name it "Ground"
   - Add a CollisionShape2D as a child of Ground
   - Add a Sprite2D as a child of Ground for visuals
   - Set up the collision shape (e.g., RectangleShape2D with size 1200x20)
   - Position the ground at around (600, 550)

4. **Add the Player Character**
   - Right-click on GameScene and select "Add Child Node"
   - Choose "InstancedScene" as the type
   - Find and select the ryu.tscn file
   - Rename the node to "Player"
   - Set its position to (300, 500)
   - Add the Player node to a group called "Player" (in Inspector > Node > Groups)

5. **Add the AI Opponent**
   - Right-click on GameScene and select "Add Child Node"
   - Choose "InstancedScene" as the type
   - Find and select the dummy_ryu.tscn file
   - Rename the node to "AIOpponent"
   - Set its position to (800, 500)
   - Add the AIOpponent node to a group called "Dummy" (in Inspector > Node > Groups)

6. **Add Camera**
   - Right-click on GameScene and select "Add Child Node"
   - Choose "Camera2D" as the type
   - Enable "Current" in the Inspector
   - Set position to (600, 400)

7. **Add Game UI**
   - Right-click on GameScene and select "Add Child Node"
   - Choose "CanvasLayer" as the type
   - Name it "GameUI"
   
   - **Add Health Bars**
     - Add ProgressBar nodes for player and opponent health
     - Name them "PlayerHealth" and "OpponentHealth"
     - Style and position them appropriately
   
   - **Add Round Timer**
     - Add a Label node and name it "RoundTimer"
     - Set its position to (600, 50)
     - Set alignment to center
   
   - **Add AI Status Panel**
     - Add a Panel node and name it "AIStatusPanel"
     - Position it in a corner of the screen
     - Add two Labels inside it: "AIStatusLabel" and "DifficultyLabel"
   
   - **Add Round End Panel**
     - Add a Panel node and name it "RoundEndPanel"
     - Center it on screen
     - Add a Label child named "ResultLabel"
     - Set ResultLabel's text to "Round Over"
     - Make RoundEndPanel initially invisible

8. **Save the Scene**
   - Save the scene as "game_scene.tscn" in the Scenes folder

## Running the Game

1. **Set as Main Scene**
   - In the Godot Project Settings, set game_scene.tscn as the main scene
   - Project > Project Settings > Application > Run > Main Scene

2. **Run the Game**
   - Click the Play button or press F5
   - You should see the player and AI opponent facing each other
   - The AI should react based on the LSTM model

## Troubleshooting

- **AI Not Responding**: Check if the AIController node is properly set up in dummy_ryu.tscn
- **Missing Health Bars**: Verify that the PlayerHP and DummyHP nodes exist in the character scenes
- **Animation Issues**: Make sure all required animations are available in the AnimationPlayer nodes

## Game Controls

- **Player Character**:
  - Arrow keys for movement
  - Z, X, C for different attacks
  - Space for jump

- **Debug Controls**:
  - F1: Toggle AI debug information
  - F2: Reset round
  - ESC: Exit game

## Next Steps

- Add more detailed backgrounds and arena elements
- Implement sound effects and music
- Add character selection menu
- Create a training mode for the AI

