# main_menu.gd
extends Node2D # Or Node2D, whatever your root node is

# Define the available control types
enum ControlType_P1 { HUMAN, DECISION_TREE }
enum ControlType_P2 { DYNAMIC_SCRIPTING, NEURO_DYNAMIC }
const CONTROL_TYPE_STRINGS_P1 = ["Human", "Decision Tree"]
const CONTROL_TYPE_STRINGS_P2 = ["Dynamic Scripting", "Neuro-Dynamic"]

# --- Node References ---
@onready var p1_selector: OptionButton = $Player1Options/P1ControlSelector
@onready var p2_selector: OptionButton = $Player2Options/P2ControlSelector
@onready var start_button: Button = $StartButton
@onready var match_count_input: LineEdit = $MatchCount_Input
#@onready var error_label: Label = $ErrorLabel # Optional

# --- Scene Path ---
const GAME_LEVEL_PATH = "res://Levels/sample_level.tscn" # Verify this path is correct

func _ready():
	
	p1_selector.clear()
	p2_selector.clear()
	
	p1_selector.add_item(CONTROL_TYPE_STRINGS_P1[0], 0)
	p1_selector.add_item(CONTROL_TYPE_STRINGS_P1[1], 1)
	p2_selector.add_item(CONTROL_TYPE_STRINGS_P2[0], 0)
	p2_selector.add_item(CONTROL_TYPE_STRINGS_P2[1], 1)
	
	# Set default selections based on requirements
	p1_selector.select(ControlType_P1.HUMAN) # Ryu defaults to Human
	p2_selector.select(ControlType_P2.DYNAMIC_SCRIPTING) # Dummy Ryu defaults to Dynamic Scripting

	# Connect button signal
	start_button.pressed.connect(_on_start_button_pressed)
	
func _on_start_button_pressed():
	var input_text = match_count_input.text
	
	if input_text.is_valid_int():
		var parsed_count = input_text.to_int()
		GameSettings.match_count = parsed_count
		print("Match count entered:", parsed_count)
	else:
		print("Invalid input. Please enter a whole number.")
	# Get selected control types as strings
	var p1_control_str = CONTROL_TYPE_STRINGS_P1[p1_selector.selected]
	var p2_control_str = CONTROL_TYPE_STRINGS_P2[p2_selector.selected]

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
