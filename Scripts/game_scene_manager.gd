extends Node2D

# References to key nodes
@onready var player = $Player
@onready var ai_opponent = $AIOpponent
@onready var camera = $Camera2D
@onready var ai_status_label = $GameUI/AIStatusPanel/AIStatusLabel
@onready var difficulty_label = $GameUI/AIStatusPanel/DifficultyLabel
@onready var round_timer_label = $GameUI/RoundTimer
@onready var player_health_bar = $GameUI/PlayerHealth
@onready var opponent_health_bar = $GameUI/OpponentHealth

# Game variables
var match_timer = 99.0
var match_active = true
var match_ended = false
var round_count = 1
var player_wins = 0
var opponent_wins = 0

# AI tracking
var difficulty_adjuster = null
var current_difficulty = 0.5
var ai_state = "Initializing"

func _ready():
	# Initialize UI
	update_ui()
	
	# Set up initial positions
	player.global_position = Vector2(300, 500)
	ai_opponent.global_position = Vector2(800, 500)
	
	# Connect AI signals if available
	if ai_opponent.has_node("AIController"):
		var ai_controller = ai_opponent.get_node("AIController")
		
		if ai_controller.has_method("get_difficulty_adjuster"):
			difficulty_adjuster = ai_controller.get_difficulty_adjuster()
			
			if difficulty_adjuster and difficulty_adjuster.has_signal("difficulty_changed"):
				difficulty_adjuster.connect("difficulty_changed", Callable(self, "_on_difficulty_changed"))
				current_difficulty = difficulty_adjuster.current_difficulty
		
		if ai_controller.has_method("get_ai_controller"):
			var lstm_ai = ai_controller.get_ai_controller()
			if lstm_ai:
				# Connect to action prediction signal
				if lstm_ai.has_signal("action_predicted"):
					lstm_ai.connect("action_predicted", Callable(self, "_on_ai_action_predicted"))
				
				# Connect to prediction details signal for more detailed logging
				if lstm_ai.has_signal("prediction_details"):
					lstm_ai.connect("prediction_details", Callable(self, "_on_ai_prediction_details"))
				
				# Connect to action execution signal
				if lstm_ai.has_signal("action_executed"):
					lstm_ai.connect("action_executed", Callable(self, "_on_ai_action_executed"))
	
	print("Game scene initialized")

func _process(delta):
	if match_active and not match_ended:
		# Update match timer
		match_timer -= delta
		if match_timer <= 0:
			end_match(player_health_bar.value > opponent_health_bar.value)
			match_timer = 0
		
		# Update UI
		update_ui()
		
		# Check for match end conditions
		if player_health_bar.value <= 0:
			end_match(false)  # AI wins
		elif opponent_health_bar.value <= 0:
			end_match(true)   # Player wins
		
		# Update camera position
		var center_pos = (player.global_position + ai_opponent.global_position) / 2
		camera.global_position = center_pos

# Update UI elements
func update_ui():
	# Update round timer
	var minutes = int(match_timer) / 60
	var seconds = int(match_timer) % 60
	round_timer_label.text = "%d:%02d" % [minutes, seconds]
	
	# Update AI status
	ai_status_label.text = "AI State: " + ai_state
	difficulty_label.text = "Difficulty: %.1f" % (current_difficulty * 10)
	
	# Update health bars from character states if available
	if player.has_node("PlayerHP"):
		player_health_bar.value = player.get_node("PlayerHP").value
		player_health_bar.max_value = player.get_node("PlayerHP").max_value
	
	if ai_opponent.has_node("DummyHP"):
		opponent_health_bar.value = ai_opponent.get_node("DummyHP").value
		opponent_health_bar.max_value = ai_opponent.get_node("DummyHP").max_value

# End the current match
func end_match(player_won):
	match_active = false
	match_ended = true
	
	if player_won:
		player_wins += 1
		print("Player wins round " + str(round_count))
	else:
		opponent_wins += 1
		print("AI wins round " + str(round_count))
	
	# Report result to difficulty adjuster if available
	if difficulty_adjuster and difficulty_adjuster.has_method("record_match_result"):
		var player_health_ratio = float(player_health_bar.value) / player_health_bar.max_value
		var opponent_health_ratio = float(opponent_health_bar.value) / opponent_health_bar.max_value
		
		difficulty_adjuster.record_match_result(
			player_won,
			player_health_ratio,
			opponent_health_ratio,
			99.0 - match_timer
		)
	
	# Start next round after delay
	$GameUI/RoundEndPanel.visible = true
	$GameUI/RoundEndPanel/ResultLabel.text = "Player Wins!" if player_won else "AI Wins!"
	
	await get_tree().create_timer(3.0).timeout
	start_next_round()

# Start a new round
func start_next_round():
	$GameUI/RoundEndPanel.visible = false
	
	# Reset characters
	player.global_position = Vector2(300, 500)
	ai_opponent.global_position = Vector2(800, 500)
	
	# Reset match variables
	match_timer = 99.0
	match_active = true
	match_ended = false
	round_count += 1
	
	# Reset health
	if player.has_node("PlayerHP"):
		player.get_node("PlayerHP").value = player.get_node("PlayerHP").max_value
	
	if ai_opponent.has_node("DummyHP"):
		ai_opponent.get_node("DummyHP").value = ai_opponent.get_node("DummyHP").max_value

# AI signal callbacks
func _on_difficulty_changed(new_difficulty, reason):
	current_difficulty = new_difficulty
	print("AI Difficulty adjusted to: " + str(new_difficulty) + " (" + reason + ")")

func _on_ai_action_predicted(action_type, params):
	ai_state = action_type
	
func _on_ai_prediction_details(action_type, confidence, game_state, timestamp):
	# Log detailed prediction info - useful for debugging
	print("AI prediction: " + action_type + " with confidence " + str(confidence))
	
	# We could display more detailed info in the UI if desired
	ai_status_label.text = "AI State: " + action_type + " (" + str(int(confidence * 100)) + "%)"

func _on_ai_action_executed(action_type, result, position, timestamp):
	# Log execution results
	if result:
		print("AI successfully executed: " + action_type)
	else:
		print("AI failed to execute: " + action_type)
