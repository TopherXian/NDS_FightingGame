# main_menu.gd
extends Node2D # Or Node2D, whatever your root node is

# Define the available control types
enum ControlType { HUMAN, DYNAMIC_SCRIPTING, DECISION_TREE, NEURO_DYNAMIC }
const CONTROL_TYPE_STRINGS = ["Human", "Dynamic Scripting", "Decision Tree", "Neuro-Dynamic"]

# --- Node References ---
@onready var p1_selector: OptionButton = $Player1Options/P1ControlSelector
@onready var p2_selector: OptionButton = $Player2Options/P2ControlSelector
@onready var start_button: Button = $StartButton
#@onready var error_label: Label = $ErrorLabel # Optional

# --- Scene Path ---
const GAME_LEVEL_PATH = "res://Levels/sample_level.tscn" # Verify this path is correct

func _ready():
	# Populate the OptionButtons
	populate_selector(p1_selector)
	populate_selector(p2_selector)

	# Set default selections based on requirements
	p1_selector.select(ControlType.HUMAN) # Ryu defaults to Human
	p2_selector.select(ControlType.DYNAMIC_SCRIPTING) # Dummy Ryu defaults to Dynamic Scripting

	# Connect button signal
	start_button.pressed.connect(_on_start_button_pressed)

func populate_selector(selector: OptionButton):
	selector.clear()
	for i in range(CONTROL_TYPE_STRINGS.size()):
		selector.add_item(CONTROL_TYPE_STRINGS[i], i)

func _on_start_button_pressed():
	# Get selected control types as strings
	var p1_control_str = CONTROL_TYPE_STRINGS[p1_selector.selected]
	var p2_control_str = CONTROL_TYPE_STRINGS[p2_selector.selected]

	# Store selections in the global GameSettings
	# Ensure GameSettings Autoload is set up (See step 3)
	if not ProjectSettings.has_setting("autoload/GameSettings"):
		print("ERROR: GameSettings autoload not found. Please configure it in Project Settings.")
		#if error_label: error_label.text = "Error: GameSettings not configured."
		return

	GameSettings.player1_control_type = p1_control_str
	GameSettings.player2_control_type = p2_control_str

	print("Starting game:")
	print("  Player 1 (Ryu) Control: ", GameSettings.player1_control_type)
	print("  Player 2 (Dummy Ryu) Control: ", GameSettings.player2_control_type)

	# Change scene to the game level
	var result = get_tree().change_scene_to_file(GAME_LEVEL_PATH)
	if result != OK:
		print("ERROR: Failed to change scene to ", GAME_LEVEL_PATH)
		#if error_label: error_label.text = "Error: Could not load game level."
