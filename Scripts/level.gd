# sample_level.gd (or whatever your level's root script is)
extends Node2D

# --- Existing @onready vars ---
@onready var label = $TimerLabel
@onready var timer = $Timer
@onready var player1_health = get_node("Player/PlayerHP")
@onready var player2_health = get_node("Dummy_Ryu/DummyHP")
# ... other @onready vars ...
var round_active := true
# --- Add reference to the Pause Menu ---
@onready var pause_menu: Control = $PauseLayer/PauseMenu # Adjust path if needed

# --- Paths ---
const MAIN_MENU_PATH = "res://main_menu.tscn"

func _ready():
	timer.start()
	# Ensure pause menu is hidden at start (redundant if unchecked in editor, but safe)
	pause_menu.hide()

	# --- Connect Pause Menu Button Signals ---
	var resume_button = pause_menu.find_child("ResumeButton") # Find button by name
	var quit_button = pause_menu.find_child("QuitButton")

	if resume_button:
		if not resume_button.is_connected("pressed", Callable(self, "_on_resume_button_pressed")):
			resume_button.connect("pressed", Callable(self, "_on_resume_button_pressed"))
	else:
		printerr("ResumeButton not found in PauseMenu!")

	if quit_button:
		if not quit_button.is_connected("pressed", Callable(self, "_on_quit_button_pressed")):
			quit_button.connect("pressed", Callable(self, "_on_quit_button_pressed"))
	else:
		printerr("QuitButton not found in PauseMenu!")

# --- Existing _process ---
func _process(_delta):
	label.text = "%02d" % int(timer.time_left)
	if round_active and (player1_health.value <= 0 or player2_health.value <= 0):
		round_active = false
		on_round_end()

func on_round_end():
	if GameSettings.match_count > 1:
		GameSettings.match_count -= 1
		print("Match remaining:", GameSettings.match_count)
		reset_round()
	else:
		end_game()
		
func reset_round():
	print("Resetting round...")
	player1_health.value = player1_health.max_value
	player2_health.value = player2_health.max_value
	timer.stop()
	timer.start()
	$Player.global_position = Vector2(327.933, 264.9326)
	$Dummy_Ryu.global_position = Vector2(479.5, 239.0833)

	# Delay before next round starts
	await get_tree().create_timer(1.5).timeout
	round_active = true

# --- Input Handling for Pause ---
func _unhandled_input(event: InputEvent):
	# Check if the game is already over or transitioning (optional)
	# if game_is_over: return

	if event.is_action_pressed("pause"): # Check for the input action defined earlier
		toggle_pause()
		# Mark the event as handled so other nodes don't process it for pausing
		get_viewport().set_input_as_handled()

# --- Pause Control Functions ---
func toggle_pause():
	var is_paused = not get_tree().paused # Check the *next* state
	get_tree().paused = is_paused # Apply the pause/unpause

	if is_paused:
		pause_menu.show()
		# Optional: You might want to stop certain sounds or music here
	else:
		pause_menu.hide()
		# Optional: Resume sounds/music

# --- Pause Menu Button Callbacks ---
func _on_resume_button_pressed():
	# We might be paused, so ensure we unpause
	if get_tree().paused:
		toggle_pause() # Use the toggle function to hide the menu and unpause

func _on_quit_button_pressed():
	# Ensure we unpause the game *before* changing scenes
	get_tree().paused = false
	# Transition back to the main menu
	var result = get_tree().change_scene_to_file(MAIN_MENU_PATH)
	if result != OK:
		print("Failed to change scene to main menu: ", MAIN_MENU_PATH)

	
func end_game():
	print("Game Over!")
	get_tree().quit()
	# Or use get_tree().change_scene_to_file("res://MainMenu.tscn")
