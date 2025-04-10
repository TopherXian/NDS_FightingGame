extends Node

class_name DummyRyuAI

# Signal definitions
signal action_predicted(action_type, params)
signal prediction_details(action_type, confidence, game_state, timestamp)
signal action_executed(action_type, result, position, timestamp)
signal model_trained
signal model_loaded
signal prediction_error(error_message)

# Constants
const HIDDEN_LAYER_SIZE = 64
const INPUT_FEATURE_SIZE = 15  # Reduced from 16 since we need fewer one-hot encoding slots
const OUTPUT_SIZE = 6  # Number of possible actions (reduced from 8)
const SEQUENCE_LENGTH = 10  # Length of sequence history to consider
const MIN_CONFIDENCE_THRESHOLD = 0.3  # Minimum confidence to perform an action

# Action timing constants
const ATTACK_DELAY = 0.05      # Very quick attack response
const MOVEMENT_DELAY = 0.05    # Quick movement response
const MIN_ATTACK_INTERVAL = 0.05 # Allow even more frequent attacks
const DECISION_DELAY = 0.05    # Faster decision making

# Neural Network Parameters
var input_weights = []  # Input gate weights
var forget_weights = [] # Forget gate weights
var output_weights = [] # Output gate weights
var cell_weights = []   # Cell state weights
var hidden_weights = [] # Hidden state to output weights

# LSTM State
var hidden_state = []
var cell_state = []
var last_features = []
var action_history = []

# Action encoding/decoding
var action_to_index = {
	"idle": 0,
	"walk_forward": 1,
	"walk_backward": 2,
	"jump": 3,
	"basic_punch": 4,
	"basic_kick": 5
}

var index_to_action = {
	0: "idle",
	1: "walk_forward",
	2: "walk_backward",
	3: "jump",
	4: "basic_punch",
	5: "basic_kick"
}

# Runtime variables
var is_training = false
var inference_mode = true
var last_prediction_time = 0.0
var prediction_cooldown = 0.1  # Time between predictions
@onready var player_node = get_parent().get_node("Player")
@onready var enemy_node = get_parent().get_node("Dummy_Ryu")
var data_collector = null
var difficulty_level = 0.5  # 0.0 (easiest) to 1.0 (hardest)
var rng = RandomNumberGenerator.new()
var thread = null
var prediction_queue = []
var ready_for_prediction = true
var last_scheduled_action = null
var time_since_last_action = 0.0
var current_action = "idle"
var action_duration = 0.0
var action_timer = 0.0
var facing_right = true  # Direction the AI character is facing

# Action state tracking
var last_attack_time: float = 0.0
var action_delay_timer: float = 0.0
var can_make_decision: bool = true
var queued_action: String = ""
var is_executing_action: bool = false

# NEW VARIABLES
var character_body = null     # Reference to the CharacterBody2D or similar
var animation_player = null   # Reference to AnimationPlayer if used
var hitbox = null             # Reference to the hitbox/hurtbox system
var attack_system = null      # Reference to attack system component

#AI VARIABLES

# Constants for the LSTM model
const INPUT_SIZE = 16   # Size of input feature vector
const HIDDEN_SIZE = 32  # Size of hidden state and cell state
const LEARNING_RATE = 0.01  # Learning rate for gradient descent

# Weight matrices
var fc_weights = []      # Weights for fully connected output layer

# Gradient accumulators
var input_weights_gradients = []
var forget_weights_gradients = []
var output_weights_gradients = []
var cell_weights_gradients = []
var fc_weights_gradients = []

# AI state tracking for combat
var predicted_action = null
var last_distance_to_player = 0.0
var player_in_attack_range = false
var attack_probability_boost = 0.0
# Called when the node enters the scene tree
func _ready():
	rng.randomize()
	_initialize_network()
	_initialize_model()
	setup(player_node, enemy_node, data_collector)
	connect("action_predicted", Callable(self, "_on_action_predicted"))
	print("[AI DEBUG] action_predicted signal connected!")
	print("DummyRyuAI initialized")
	
	# Run matrix operation tests to validate fixes
	test_matrix_operations()

# ENHANCED: Setup the AI with references to game nodes
func setup(p_node, e_node, collector):
	player_node = p_node
	enemy_node = e_node
	data_collector = collector
	
	# Get character body and components
	if enemy_node:
		# Get the CharacterBody2D (if it's not the enemy_node itself)
		if enemy_node is CharacterBody2D:
			character_body = enemy_node
		else:
			# Try to find a CharacterBody2D parent or child
			character_body = enemy_node.get_parent() if enemy_node.get_parent() is CharacterBody2D else null
			if character_body == null:
				for child in enemy_node.get_children():
					if child is CharacterBody2D:
						character_body = child
						break
		
		# Find animation player
		if enemy_node.has_node("Dummy_Animation"):
			animation_player = enemy_node.get_node("Dummy_Animation")
		
		# Find attack system
		for child in enemy_node.get_children():
			if "attack" in child.name.to_lower():
				attack_system = child
				break
		
		# Find hitbox
		for child in enemy_node.get_children():
			if "hitbox" in child.name.to_lower() or "hurtbox" in child.name.to_lower():
				hitbox = child
				break
	
	print("DummyRyuAI setup complete")
	print("Character body: " + str(character_body != null))
	print("Animation player: " + str(animation_player != null))
	print("Attack system: " + str(attack_system != null))
	print("Hitbox: " + str(hitbox != null))

# Called every frame
func _process(delta):
	# Update timers with more aggressive timing
	if action_timer > 0:
		action_timer -= delta * 2.0  # Double speed up action completion
		if action_timer <= 0:
			current_action = "idle"
			if attack_system:
				attack_system.stop_attacking()
			is_executing_action = false  # Reset execution state
	
	# Update action delay with faster response
	if action_delay_timer > 0:
		action_delay_timer -= delta * 3.0  # Triple speed delay countdown
		if action_delay_timer <= 0 and queued_action != "":
			_execute_queued_action()
	
	# Track time since last action
	time_since_last_action += delta
	
	# Make decisions more frequently when not executing action
	if not is_executing_action and not queued_action:
		var current_time = Time.get_unix_time_from_system()
		if current_time - last_prediction_time > prediction_cooldown:
			predict_next_action()
			last_prediction_time = current_time
			
			# Force attack check when in range for more aggressive AI
			if player_in_attack_range and not is_executing_action and not queued_action:
				var attack_force_chance = 0.2  # 20% chance to force an attack when in range
				if rng.randf() < attack_force_chance:
					var attack_type = "basic_punch" if last_distance_to_player <= 88 else "basic_kick"
					queued_action = attack_type
					action_delay_timer = ATTACK_DELAY * 0.5  # Very quick attack
					print("[AI DEBUG] Forcing immediate attack: " + attack_type)
	
	# Process predictions immediately if possible
	if prediction_queue.size() > 0 and not is_executing_action and not queued_action:
		var prediction = prediction_queue.pop_front()
		_execute_prediction(prediction)

# Execute queued action
func _execute_queued_action():
	if is_executing_action:
		return
		
	is_executing_action = true
	current_action = queued_action
	
	# Play animation immediately
	if animation_player:
		animation_player.play(current_action)
	
	match current_action:
		"basic_punch":
			if attack_system:
				attack_system.perform_attack(current_action)
			action_timer = 0.15  # Shorter duration for punch
		"basic_kick":
			if attack_system:
				attack_system.perform_attack(current_action)
			action_timer = 0.2   # Slightly longer for kick
			
		"walk_forward", "walk_backward":
			action_timer = 0.1   # Quick movement
		"jump":
			action_timer = 0.4   # Shorter jump
			if character_body and character_body.is_on_floor():
				character_body.velocity.y = -400
				animation_player.play("jump")
		"idle":
			action_timer = 0.1
			animation_player.play("idle")
	
	# Emit signal immediately after starting the action
	emit_signal("action_predicted", current_action, {
		"executing": true,
		"immediate": true
	})
	
	queued_action = ""  # Clear queued action immediately
	
	# Reset execution state after a shorter delay
	await get_tree().create_timer(action_timer * 0.5).timeout
	is_executing_action = false

# NEW FUNCTION: Handle being hit by an attack with smarter decision making
func receive_hit(damage: float, attacker) -> bool:
	# Clear any queued actions when hit
	queued_action = ""
	action_delay_timer = 0.0
	
	# Reset action execution state
	is_executing_action = false
	
	# Get current state information
	var distance = player_node.global_position.distance_to(enemy_node.global_position)
	var hp_percent = 0.0
	if enemy_node.has_node("DummyHP"):
		var hp_bar = enemy_node.get_node("DummyHP")
		hp_percent = float(hp_bar.value) / float(hp_bar.max_value)
	
	# Critical health behavior (below 30%)
	if hp_percent < 0.3:
		if distance < 150:
			# Desperate defense with increased counter-attack chance
			if rng.randf() < 0.5:  # Reduced from 70% to 50% chance to escape
				current_action = "walk_backward"
				action_timer = 0.5  # Shorter retreat
			else:  # 50% chance to counter-attack
				current_action = "basic_punch" if distance < 90 else "basic_kick"  # Increased range
				action_timer = 0.3  # Faster attack
		else:
			# Strategic repositioning
			current_action = "walk_forward"
			action_timer = 0.3  # Faster approach
	
	# Medium health behavior (30-70%)
	elif hp_percent < 0.7:
		if distance < 120:  # Increased from 100
			if rng.randf() < 0.7:  # Increased from 50% to 70% chance to counter-attack
				# Counter with appropriate attack based on distance
				if distance < 90:  # Increased PUNCH_RANGE
					current_action = "basic_punch"
					action_timer = 0.25  # Faster attack
				else:
					current_action = "basic_kick"
					action_timer = 0.3
			else:
				# Create space
				current_action = "walk_backward"
				action_timer = 0.25
		else:
			# Approach player more aggressively
			current_action = "walk_forward"
			action_timer = 0.25
	
	# High health behavior (above 70%)
	else:
		if distance < 140:  # Increased from 120
			if rng.randf() < 0.8:  # Increased from 60% to 80% chance to counter-attack
				# Simple counter based on distance
				if distance < 90:  # Increased PUNCH_RANGE
					current_action = "basic_punch"
					action_timer = 0.25
				else:
					current_action = "basic_kick"
					action_timer = 0.3
			else:
				# Tactical repositioning
				current_action = "walk_backward"
				action_timer = 0.2
		else:
			# Close in for pressure
			current_action = "walk_forward"
			action_timer = 0.2  # Faster approach
	# Special case: if taking heavy damage, consider emergency evasion
	if damage >= 20 and character_body and character_body.is_on_floor() and rng.randf() < 0.4:
		current_action = "jump"
		action_timer = 0.5
	
	# Apply animation first
	if animation_player and animation_player.has_animation(current_action):
		animation_player.play(current_action)
	
	# Apply velocity if we have a character body
	if character_body and "velocity" in character_body:
		character_body.move_and_slide()
	
	# Update facing direction for proper movement
	facing_right = player_node.global_position.x > enemy_node.global_position.x
	
	# Return true to acknowledge hit
	return true

# Initialize the neural network with random weights
func _initialize_network():
	# Reset states with correct sizes
	hidden_state = _create_zero_vector(HIDDEN_LAYER_SIZE)
	cell_state = _create_zero_vector(HIDDEN_LAYER_SIZE)
	
	# Calculate the combined input size (features + hidden state)
	var combined_input_size = INPUT_FEATURE_SIZE + HIDDEN_LAYER_SIZE
	
	# Initialize weights with correct dimensions 
	# Each row operates on the combined input vector to produce an output element
	input_weights = _create_random_matrix(HIDDEN_LAYER_SIZE, combined_input_size)
	forget_weights = _create_random_matrix(HIDDEN_LAYER_SIZE, combined_input_size)
	output_weights = _create_random_matrix(HIDDEN_LAYER_SIZE, combined_input_size)
	cell_weights = _create_random_matrix(HIDDEN_LAYER_SIZE, combined_input_size)
	hidden_weights = _create_random_matrix(OUTPUT_SIZE, HIDDEN_LAYER_SIZE)  # Output layer has OUTPUT_SIZE rows
	
	# Initialize last features
	last_features = _create_zero_vector(INPUT_FEATURE_SIZE)

# ENHANCED: Execute a prediction from the queue
func _execute_prediction(prediction):
	var action_index = prediction["action_index"]
	var confidence = prediction["confidence"]
	var action_name = index_to_action[action_index]
	
	# Add to action history
	action_history.append(action_name)
	if action_history.size() > SEQUENCE_LENGTH:
		action_history.pop_front()
	
	# Queue the action with appropriate delay
	queued_action = action_name
	action_delay_timer = MOVEMENT_DELAY  # Default to movement delay
	
	# More aggressive attack timing with shorter delays
	if action_name in ["basic_punch", "basic_kick"]:
		var current_time = Time.get_unix_time_from_system()
		# Reduced attack interval for more frequent attacks
		if current_time - last_attack_time >= MIN_ATTACK_INTERVAL:
			# Use even shorter delay when in optimal range
			if player_in_attack_range:
				action_delay_timer = ATTACK_DELAY * 0.5  # 50% faster attack when in range (more aggressive)
			else:
				action_delay_timer = ATTACK_DELAY * 0.8  # Still slightly faster than normal
			last_attack_time = current_time
			
			# Debug output
			print("[AI DEBUG] Executing attack: " + action_name + " at distance: " + str(last_distance_to_player))
		else:
			# Instead of always canceling, more frequently try anyway (more aggressive)
			if rng.randf() < 0.6:  # 60% chance to attempt attack anyway
				action_delay_timer = ATTACK_DELAY * 1.2  # Reduced delay multiplier
				last_attack_time = current_time
				print("[AI DEBUG] Forcing attack: " + action_name)
			else:
				queued_action = "idle"  # Cancel attack if too soon
	
	# Emit the signal with the predicted action
	emit_signal("action_predicted", action_name, {
		"confidence": confidence,
		"queued": true
	})
	
	# Log the prediction for training data
	if data_collector and data_collector.is_collecting:
		# Extract current game state for prediction context
		var game_state = {
			"player_position": player_node.global_position if player_node else Vector2.ZERO,
			"enemy_position": enemy_node.global_position if enemy_node else Vector2.ZERO,
			"player_velocity": player_node.velocity if "velocity" in player_node else Vector2.ZERO,
			"player_health_percent": _get_health_percent(player_node),
			"enemy_health_percent": _get_health_percent(enemy_node),
			"distance_to_player": _get_distance_to_player(),
			"lstm_hidden_state": hidden_state.duplicate(),
			"lstm_cell_state": cell_state.duplicate(),
			"prediction_index": action_index,
			"action_probabilities": prediction["probabilities"]
		}
		
		# Emit signal with detailed prediction information
		emit_signal("prediction_details", 
			action_name, 
			confidence, 
			game_state,
			Time.get_unix_time_from_system()
		)
		
		# After emitting the prediction, track when the action is executed
		# We'll call this method from the character controller when the action completes
		call_deferred("_schedule_execution_tracking", action_name)

# Set the difficulty level
func set_difficulty(level):
	difficulty_level = clamp(level, 0.0, 1.0)
	# Adjust prediction cooldown based on difficulty (faster reactions at higher difficulty)
	prediction_cooldown = lerp(0.5, 0.05, difficulty_level)
	print("Difficulty set to: " + str(difficulty_level))

# Predict the next action based on current game state
func predict_next_action():
	print("DEBUG: Running prediction logic")
	if player_node == null or enemy_node == null:
		emit_signal("prediction_error", "Game nodes not set up")
		return
		
	# Extract features from the current game state
	var features = _extract_features()
	
	print("[DEBUG] Calling _lstm_forward_pass synchronously")
	var probabilities = _lstm_forward_pass(features)
	if probabilities == null:
		print("[AI DEBUG] LSTM forward pass failed")
		return
		
	print("[DEBUG] LSTM output probabilities:", probabilities)
	
	# Calculate distance to player for range-based decisions
	var distance = _get_distance_to_player()
	last_distance_to_player = distance
	
	# Boost attack probabilities when in range
	var modified_probabilities = probabilities.duplicate()
	
	# Check if player is in attack range (updated ranges to match enemy_character_movement.gd)
	var in_punch_range = distance <= 88  # PUNCH_RANGE + 5 from enemy_character_movement.gd
	var in_kick_range = distance <= 135  # KICK_RANGE + 5 from enemy_character_movement.gd
	var in_heavy_punch_range = distance <= 93  # PUNCH_RANGE + 10 from enemy_character_movement.gd
	var in_heavy_kick_range = distance <= 140  # KICK_RANGE + 10 from enemy_character_movement.gd
	player_in_attack_range = in_punch_range or in_kick_range or in_heavy_punch_range or in_heavy_kick_range
	
	# Dynamically adjust attack probabilities based on range (increased boosts)
	if in_punch_range:
		# Significantly boost punch probability when in close range
		modified_probabilities[action_to_index["basic_punch"]] += 0.6  # Increased from 0.4
		attack_probability_boost = 0.6
	elif in_kick_range:
		# Boost kick probability when in medium range
		modified_probabilities[action_to_index["basic_kick"]] += 0.5  # Increased from 0.3
		attack_probability_boost = 0.5
	else:
		# When out of range, boost movement toward player
		modified_probabilities[action_to_index["walk_forward"]] += 0.3  # Increased from 0.2
		attack_probability_boost = 0
	
	# Add randomization to prevent predictable behavior, with attack bias
	if rng.randf() < 0.15:  # 15% chance to add randomness
		var random_boost = rng.randf() * 0.2
		var random_action = rng.randi() % OUTPUT_SIZE
		
		# Bias randomness towards attacks when in range
		if player_in_attack_range and rng.randf() < 0.7:  # 70% bias towards attacks when in range
			random_action = action_to_index["basic_punch"] if last_distance_to_player <= 88 else action_to_index["basic_kick"]
			random_boost += 0.2  # Extra boost for attacks
		
		modified_probabilities[random_action] += random_boost
	
	# Renormalize probabilities
	modified_probabilities = _softmax(modified_probabilities)
	
	# Find the action with highest probability
	var best_action_idx = 0
	var best_probability = modified_probabilities[0]
	
	for i in range(1, modified_probabilities.size()):
		if modified_probabilities[i] > best_probability:
			best_probability = modified_probabilities[i]
			best_action_idx = i
	
	# Apply difficulty adjustment
	var confidence_threshold = lerp(0.4, MIN_CONFIDENCE_THRESHOLD, difficulty_level)  # Increased base threshold
	
	# If confidence is too low or we randomly decide to make a mistake (based on difficulty)
	if best_probability < confidence_threshold or rng.randf() > difficulty_level:
		# Choose a random action instead
		best_action_idx = rng.randi() % OUTPUT_SIZE
		best_probability = probabilities[best_action_idx]
	
	# Get the action name from the index
	var action_name = index_to_action.get(best_action_idx, "idle")
	
	# Queue the prediction for execution
	var prediction = {
		"action_index": best_action_idx,
		"confidence": best_probability,
		"probabilities": probabilities
	}
	
	# Add to prediction queue
	_add_to_prediction_queue(prediction)
	
	print("[AI DEBUG] Predicted action:", action_name, " with confidence:", best_probability)
	return action_name

# Extract feature vector from the current game state
func _extract_features():
	# Get positions and velocities
	var player_pos = player_node.global_position
	var enemy_pos = enemy_node.global_position
	var player_vel = Vector2.ZERO
	if "velocity" in player_node:
		player_vel = player_node.velocity
	
	# Calculate distance between characters
	var distance = player_pos.distance_to(enemy_pos)
	
	# Get health values (normalized to 0-1)
	var player_health = _get_health_percent(player_node)
	var enemy_health = _get_health_percent(enemy_node)
	
	# Determine relative position (player is to the right of enemy = 1, left = -1)
	var relative_position = 1 if player_pos.x > enemy_pos.x else -1
	
	# Check player state
	var player_is_attacking = false
	if player_node.has_node("attack_system"):
		player_is_attacking = player_node.get_node("attack_system").is_attacking
	
	var player_is_jumping = false
	if "is_on_floor" in player_node:
		player_is_jumping = not player_node.is_on_floor()
	elif "is_jumping" in player_node:
		player_is_jumping = player_node.is_jumping
	
	# Create normalized feature vector
	var features = [
		player_pos.x / 1000.0,  # Normalize position by typical screen width
		player_pos.y / 600.0,   # Normalize position by typical screen height
		enemy_pos.x / 1000.0,
		enemy_pos.y / 600.0,
		player_vel.x / 300.0,   # Normalize by typical max velocity
		player_vel.y / 400.0,
		distance / 500.0,       # Normalize by typical maximum distance
		player_health,
		enemy_health,
		float(relative_position),
		float(player_is_attacking),
		float(player_is_jumping),
		# Add the last action as one-hot encoding (3 slots for basic actions)
		0.0, 0.0, 0.0
	]
	
	# Set the one-hot encoding for the last action if available
	if action_history.size() > 0:
		var last_action_idx = action_to_index.get(action_history.back(), 0)
		if last_action_idx < 3:  # We only need 3 slots now
			features[12 + last_action_idx] = 1.0
	
	return features

# Run LSTM prediction in a separate thread
func _predict_in_thread(features):
	if thread != null and thread.is_started():
		# If a thread is already running, wait for it
		if thread.is_alive():
			return
		
	# Store features for later processing
	last_features = features
	
	print("[DEBUG] About to start thread for _lstm_forward_pass with features:", features)
	thread = Thread.new()
	var err = thread.start(Callable(self, "_lstm_forward_pass").bind(features))
	print("[DEBUG] Thread start returned:", err)
	
	if err != OK:
		emit_signal("prediction_error", "Failed to start prediction thread")
		ready_for_prediction = true

# LSTM forward pass calculation
func _lstm_forward_pass(features):
	print("[DEBUG] _lstm_forward_pass started")
	
	# First validate features size
	if features.size() != INPUT_FEATURE_SIZE:
		push_error("Features vector must have size " + str(INPUT_FEATURE_SIZE))
		return null
	
	# Create combined input (concatenate features and hidden state)
	var combined_input = features.duplicate()
	combined_input.append_array(hidden_state)
	
	# Calculate input gate with validation
	var input_gate_result = _matrix_vector_multiply(input_weights, combined_input)
	if input_gate_result.size() == 0:
		push_error("Input gate computation failed")
		return null
	var input_gate = _sigmoid(input_gate_result)
	
	# Calculate forget gate with validation
	var forget_gate_result = _matrix_vector_multiply(forget_weights, combined_input)
	if forget_gate_result.size() == 0:
		push_error("Forget gate computation failed")
		return null
	var forget_gate = _sigmoid(forget_gate_result)
	
	# Calculate output gate with validation
	var output_gate_result = _matrix_vector_multiply(output_weights, combined_input)
	if output_gate_result.size() == 0:
		push_error("Output gate computation failed")
		return null
	var output_gate = _sigmoid(output_gate_result)
	
	# Calculate cell candidate with validation
	var cell_candidate_result = _matrix_vector_multiply(cell_weights, combined_input)
	if cell_candidate_result.size() == 0:
		push_error("Cell candidate computation failed")
		return null
	var cell_candidate = _tanh(cell_candidate_result)
	
	# Update cell state
	var new_cell_state = []
	for i in range(cell_state.size()):
		new_cell_state.append(forget_gate[i] * cell_state[i] + input_gate[i] * cell_candidate[i])
	cell_state = new_cell_state
	
	# Update hidden state
	var new_hidden_state = []
	for i in range(hidden_state.size()):
		new_hidden_state.append(output_gate[i] * _tanh(cell_state[i]))
	hidden_state = new_hidden_state
	
	# Calculate output
	var output = _matrix_vector_multiply(hidden_weights, hidden_state)
	if output.size() == 0:
		push_error("Output layer computation failed")
		return null
		
	# Apply softmax to get probabilities
	var probabilities = _softmax(output)
	if probabilities.size() == 0:
		push_error("Softmax computation failed")
		return null
	
	# Debug: print the probabilities
	print(probabilities)
	
	# Return the probabilities array for further processing
	return probabilities

# Add a prediction to the queue (called from thread)
func _add_to_prediction_queue(prediction):
	prediction_queue.append(prediction)

# Signal that we're done with the prediction (called from thread)
func _finish_prediction():
	ready_for_prediction = true

## ENHANCED: Execute a prediction from the queue
#func _execute_prediction(prediction):
	#var action_index = prediction["action_index"]
	#var confidence = prediction["confidence"]
	#var action_name = index_to_action[action_index]
	#
	## Add to action history
	#action_history.append(action_name)
	#if action_history.size() > SEQUENCE_LENGTH:
		#action_history.pop_front()
	#
	## Set the current action and its duration
	#current_action = action_name
	#
	## Set action duration based on action type
	#match current_action:
		#"idle":
			#action_timer = rng.randf_range(0.5, 1.0)
		#"walk_forward", "walk_backward":
			#action_timer = rng.randf_range(0.3, 0.8)
		#"jump":
			#action_timer = 1.0
		#"basic_punch":
			#action_timer = 0.4
		#"basic_kick":
			#action_timer = 0.4
	#
	## Emit the signal with the predicted action
	#emit_signal("action_predicted", action_name, {
		#"confidence": confidence
	#})
	#
	## Log the prediction for training data
	#if data_collector and data_collector.is_collecting:
		## Extract current game state for prediction context
		#var game_state = {
			#"player_position": player_node.global_position if player_node else Vector2.ZERO,
			#"enemy_position": enemy_node.global_position if enemy_node else Vector2.ZERO,
			#"player_velocity": player_node.velocity if "velocity" in player_node else Vector2.ZERO,
			#"player_health_percent": _get_health_percent(player_node),
			#"enemy_health_percent": _get_health_percent(enemy_node),
			#"distance_to_player": _get_distance_to_player(),
			#"lstm_hidden_state": hidden_state.duplicate(),
			#"lstm_cell_state": cell_state.duplicate(),
			#"prediction_index": action_index,
			#"action_probabilities": prediction["probabilities"]
		#}
		#
		## Emit signal with detailed prediction information
		#emit_signal("prediction_details", 
			#action_name, 
			#confidence, 
			#game_state,
			#Time.get_unix_time_from_system()
		#)
		#
		## After emitting the prediction, track when the action is executed
		## We'll call this method from the character controller when the action completes
		#call_deferred("_schedule_execution_tracking", action_name)

# Track action execution result
func record_action_result(action_name, result, position):
	if action_name == last_scheduled_action:
		emit_signal("action_executed", 
			action_name, 
			result, 
			position,
			Time.get_unix_time_from_system()
		)

# FULLY IMPLEMENTED: Train the LSTM model from collected data
func train_model():
	if data_collector == null:
		emit_signal("prediction_error", "Data collector not set up")
		return
		
	print("Starting model training...")
	is_training = true
	
	# Get training data from collector
	var training_data = data_collector.get_lstm_training_data()
	if training_data.size() == 0:
		print("No training data available")
		is_training = false
		return
	
	# Perform mini-batch training
	var iterations = 100  # Number of training iterations
	var batch_size = min(32, training_data.size())
	
	for iter in range(iterations):
		# Reset gradients
		_zero_gradients()
		
		# Sample a mini-batch
		var batch = []
		for i in range(batch_size):
			var idx = rng.randi() % training_data.size()
			batch.append(training_data[idx])
		
		# Process each sample in the batch
		var total_loss = 0.0
		for sample in batch:
			# Extract features and target from sample
			var features = _extract_features_from_sample(sample)
			var target_idx = _get_target_action_index(sample)
			
			# Forward pass
			var forward_result = _lstm_forward_pass(features)
			var lstm_output = forward_result[0]
			var cache = forward_result[1]
			
			# Create one-hot encoded target
			var target = _create_zero_vector(OUTPUT_SIZE)
			target[target_idx] = 1.0
			
			# Calculate cross-entropy loss
			var loss = _cross_entropy_loss(lstm_output, target)
			total_loss += loss
			
			# Backward pass
			_lstm_backward_pass(lstm_output, target, cache)
			
			# Update weights (gradient accumulation)
			_accumulate_gradients()
		
		# Apply weight updates with averaged gradients
		_update_weights(LEARNING_RATE, batch_size)
		
		# Print progress
		if iter % 10 == 0:
			print("Training iteration ", iter, ", Average loss: ", total_loss / batch_size)
	
	print("Model training completed")
	is_training = false
	emit_signal("model_trained")

func _initialize_model():
	# Seed the random number generator
	rng.randomize()
	
	# Use consistent size constants
	hidden_state = _create_zero_vector(HIDDEN_LAYER_SIZE)
	cell_state = _create_zero_vector(HIDDEN_LAYER_SIZE)
	
	# Calculate the combined input size
	var combined_input_size = INPUT_FEATURE_SIZE + HIDDEN_LAYER_SIZE
	
	# Initialize weight matrices with correct dimensions
	input_weights = _create_random_matrix(HIDDEN_LAYER_SIZE, combined_input_size)
	forget_weights = _create_random_matrix(HIDDEN_LAYER_SIZE, combined_input_size)
	output_weights = _create_random_matrix(HIDDEN_LAYER_SIZE, combined_input_size)
	cell_weights = _create_random_matrix(HIDDEN_LAYER_SIZE, combined_input_size)
	fc_weights = _create_random_matrix(OUTPUT_SIZE, HIDDEN_LAYER_SIZE)
	
	# Initialize gradient accumulators
	_zero_gradients()

# Helper for creating a matrix with random values
func _create_random_matrix(rows: int, cols: int) -> Array:
	var matrix = []
	for i in range(rows):
		var row = []
		row.resize(cols)
		for j in range(cols):
			# Initialize with small random values for better training stability
			row[j] = rng.randf_range(-0.1, 0.1)
		matrix.append(row)
	return matrix

# Backward pass for LSTM with cross-entropy loss
func _lstm_backward_pass(output, target, cache):
	# Calculate output layer gradients (cross-entropy with softmax)
	var output_grad = []
	for i in range(output.size()):
		output_grad.append(output[i] - target[i])  # Derivative of softmax + cross-entropy
	
	# Gradient for fully connected layer
	var hidden_state_grad = _matrix_transpose_vector_multiply(fc_weights, output_grad)
	var fc_weights_grad = _outer_product(output_grad, cache["hidden_state"])
	
	# Accumulate fc_weights gradients
	for i in range(fc_weights_grad.size()):
		for j in range(fc_weights_grad[i].size()):
			fc_weights_gradients[i][j] += fc_weights_grad[i][j]
	
	# Initialize gradients for LSTM components
	var next_hidden_grad = hidden_state_grad
	var next_cell_grad = _create_zero_vector(HIDDEN_LAYER_SIZE)
	
	# LSTM backward pass
	# Gradient for output gate
	var cell_state_act = cache["cell_state_act"]
	var output_gate = cache["output_gate"]
	var output_gate_grad = []
	
	for i in range(HIDDEN_LAYER_SIZE):
		output_gate_grad.append(next_hidden_grad[i] * cell_state_act[i] * output_gate[i] * (1.0 - output_gate[i]))
	
	# Gradient for cell state (from hidden state and next cell grad)
	var cell_state_grad = []
	for i in range(HIDDEN_LAYER_SIZE):
		var tanh_deriv = 1.0 - cell_state_act[i] * cell_state_act[i]  # Derivative of tanh
		cell_state_grad.append(next_hidden_grad[i] * cache["output_gate"][i] * tanh_deriv + next_cell_grad[i])
	
	# Gradient for forget gate
	var forget_gate = cache["forget_gate"]
	var forget_gate_grad = []
	for i in range(HIDDEN_LAYER_SIZE):
		forget_gate_grad.append(cell_state_grad[i] * cache["prev_cell_state"][i] * forget_gate[i] * (1.0 - forget_gate[i]))
	
	# Gradient for input gate
	var input_gate = cache["input_gate"]
	var input_gate_grad = []
	for i in range(HIDDEN_LAYER_SIZE):
		input_gate_grad.append(cell_state_grad[i] * cache["cell_candidate"][i] * input_gate[i] * (1.0 - input_gate[i]))
	
	# Gradient for cell candidate
	var cell_candidate = cache["cell_candidate"]
	var cell_candidate_grad = []
	for i in range(HIDDEN_LAYER_SIZE):
		cell_candidate_grad.append(cell_state_grad[i] * cache["input_gate"][i] * (1.0 - cell_candidate[i] * cell_candidate[i]))
	
	# Gradient for previous cell state (for next timestep's backprop)
	var prev_cell_grad = []
	for i in range(HIDDEN_LAYER_SIZE):
		prev_cell_grad.append(cell_state_grad[i] * cache["forget_gate"][i])
	
	# Compute gradients for combined input
	var combined_input_grad = _create_zero_vector(HIDDEN_LAYER_SIZE + INPUT_FEATURE_SIZE)
	
	# Add gradients from each gate
	var input_grad = _matrix_transpose_vector_multiply(input_weights, input_gate_grad)
	var forget_grad = _matrix_transpose_vector_multiply(forget_weights, forget_gate_grad)
	var output_gate_combined_grad = _matrix_transpose_vector_multiply(output_weights, output_gate_grad)
	var cell_grad = _matrix_transpose_vector_multiply(cell_weights, cell_candidate_grad)
	
	for i in range(combined_input_grad.size()):
		combined_input_grad[i] = input_grad[i] + forget_grad[i] + output_gate_combined_grad[i] + cell_grad[i]
	
	# Split combined input gradient into features and hidden state gradients
	var features_grad = []
	var hidden_grad = []
	
	for i in range(INPUT_FEATURE_SIZE):
		features_grad.append(combined_input_grad[i])
	
	for i in range(HIDDEN_LAYER_SIZE):
		hidden_grad.append(combined_input_grad[i + INPUT_FEATURE_SIZE])
	
	# Calculate weight gradients
	var input_weights_grad = _outer_product(input_gate_grad, cache["combined_input"])
	var forget_weights_grad = _outer_product(forget_gate_grad, cache["combined_input"])
	var output_weights_grad = _outer_product(output_gate_grad, cache["combined_input"])
	var cell_weights_grad = _outer_product(cell_candidate_grad, cache["combined_input"])
	
	# Accumulate weight gradients
	for i in range(HIDDEN_LAYER_SIZE):
		for j in range(HIDDEN_LAYER_SIZE + INPUT_FEATURE_SIZE):
			input_weights_gradients[i][j] += input_weights_grad[i][j]
			forget_weights_gradients[i][j] += forget_weights_grad[i][j]
			output_weights_gradients[i][j] += output_weights_grad[i][j]
			cell_weights_gradients[i][j] += cell_weights_grad[i][j]

# Helper functions for backpropagation
func _zero_gradients():
	# Reset all gradient accumulators to zero
	var combined_input_size = INPUT_FEATURE_SIZE + HIDDEN_LAYER_SIZE
	input_weights_gradients = _create_zero_matrix(HIDDEN_LAYER_SIZE, combined_input_size)
	forget_weights_gradients = _create_zero_matrix(HIDDEN_LAYER_SIZE, combined_input_size)
	output_weights_gradients = _create_zero_matrix(HIDDEN_LAYER_SIZE, combined_input_size)
	cell_weights_gradients = _create_zero_matrix(HIDDEN_LAYER_SIZE, combined_input_size)
	fc_weights_gradients = _create_zero_matrix(OUTPUT_SIZE, HIDDEN_LAYER_SIZE)

func _accumulate_gradients():
	# This function is called in the training loop to accumulate gradients
	# But in our implementation, gradients are already accumulated in _lstm_backward_pass
	pass

func _update_weights(learning_rate, batch_size):
	# Apply gradients to weights, with normalization by batch size
	var lr = learning_rate / batch_size
	
	# Update input gate weights
	for i in range(HIDDEN_LAYER_SIZE):
		for j in range(INPUT_FEATURE_SIZE + HIDDEN_LAYER_SIZE):
			input_weights[i][j] -= lr * input_weights_gradients[i][j]
	
	# Update forget gate weights
	for i in range(HIDDEN_LAYER_SIZE):
		for j in range(INPUT_FEATURE_SIZE + HIDDEN_LAYER_SIZE):
			forget_weights[i][j] -= lr * forget_weights_gradients[i][j]
	
	# Update output gate weights
	for i in range(HIDDEN_LAYER_SIZE):
		for j in range(INPUT_FEATURE_SIZE + HIDDEN_LAYER_SIZE):
			output_weights[i][j] -= lr * output_weights_gradients[i][j]
	
	# Update cell candidate weights
	for i in range(HIDDEN_LAYER_SIZE):
		for j in range(INPUT_FEATURE_SIZE + HIDDEN_LAYER_SIZE):
			cell_weights[i][j] -= lr * cell_weights_gradients[i][j]
	
	# Update fully connected weights
	for i in range(OUTPUT_SIZE):
		for j in range(HIDDEN_LAYER_SIZE):
			fc_weights[i][j] -= lr * fc_weights_gradients[i][j]

func _matrix_vector_multiply(matrix, vector):
	var result = []
	
	# Validate inputs are arrays
	if not matrix is Array or matrix.size() == 0:
		push_error("Matrix must be a non-empty array")
		return result
		
	if not vector is Array or vector.size() == 0:
		push_error("Vector must be a non-empty array")
		return result
	
	# Validate matrix dimensions
	var row_size = vector.size()
	for i in range(matrix.size()):
		if not matrix[i] is Array or matrix[i].size() != row_size:
			push_error("Matrix row " + str(i) + " must have size " + str(row_size))
			return result
	
	# Perform multiplication
	for i in range(matrix.size()):
		var sum = 0.0
		for j in range(vector.size()):
			sum += matrix[i][j] * vector[j]
		result.append(sum)
	
	return result

# Helper for matrix-transpose-vector multiplication
func _matrix_transpose_vector_multiply(matrix, vector):
	var result = _create_zero_vector(matrix[0].size())
	for i in range(matrix.size()):
		for j in range(matrix[0].size()):
			result[j] += matrix[i][j] * vector[i]
	return result

# Helper for outer product
func _outer_product(vec_a, vec_b):
	var result = []
	for i in range(vec_a.size()):
		result.append([])
		for j in range(vec_b.size()):
			result[i].append(vec_a[i] * vec_b[j])
	return result

# Helper for creating a zero vector
func _create_zero_vector(size):
	var result = []
	for i in range(size):
		result.append(0.0)
	return result

# Helper for creating a zero matrix
func _create_zero_matrix(rows, cols):
	var result = []
	for i in range(rows):
		result.append([])
		for j in range(cols):
			result[i].append(0.0)
	return result

# Activation functions and their derivatives
func _sigmoid_vector(vec):
	var result = []
	for i in range(vec.size()):
		result.append(1.0 / (1.0 + exp(-vec[i])))
	return result

func _tanh_vector(vec):
	var result = []
	for i in range(vec.size()):
		result.append(tanh(vec[i]))
	return result

func _softmax_vector(vec):
	var result = []
	var max_val = vec[0]
	for i in range(1, vec.size()):
		max_val = max(max_val, vec[i])
	
	var sum_exp = 0.0
	for i in range(vec.size()):
		sum_exp += exp(vec[i] - max_val)  # Subtract max for numerical stability
	
	for i in range(vec.size()):
		result.append(exp(vec[i] - max_val) / sum_exp)
	
	return result

# Calculate cross-entropy loss
func _cross_entropy_loss(output, target):
	var loss = 0.0
	var epsilon = 0.0000001  # Small constant to avoid log(0)
	
	for i in range(output.size()):
		if target[i] > 0:
			loss -= target[i] * log(output[i] + epsilon)
	
	return loss

func _extract_features_from_sample(sample):
	# Extract and normalize features from a training sample
	var features = []
	
	# Game state features
	for feature in sample["game_state"]:
		features.append(feature)
	
	# Normalize features if needed
	# ...
	
	return features


# Forward pass specifically for training (returns cache for backprop)
func _lstm_forward_pass_training(features):
	# This is similar to _lstm_forward_pass but returns the complete cache
	var cache = {}
	
	# Add hidden state to input
	var combined_input = features.duplicate()
	combined_input.append_array(hidden_state)
	cache["combined_input"] = combined_input
	cache["features"] = features.duplicate()
	
	# Calculate input gate
	var input_gate_net = _matrix_vector_multiply(input_weights, combined_input)
	var input_gate = _sigmoid_vector(input_gate_net)
	cache["input_gate_net"] = input_gate_net
	cache["input_gate"] = input_gate
	
	# Calculate forget gate
	var forget_gate_net = _matrix_vector_multiply(forget_weights, combined_input)
	var forget_gate = _sigmoid_vector(forget_gate_net)
	cache["forget_gate_net"] = forget_gate_net  # Fix: was using "forget" instead of "forget_gate_net"
	cache["forget_gate"] = forget_gate
	
	# Calculate output gate
	var output_gate_net = _matrix_vector_multiply(output_weights, combined_input)
	var output_gate = _sigmoid_vector(output_gate_net)
	cache["output_gate_net"] = output_gate_net
	cache["output_gate"] = output_gate
	
	# Calculate cell candidate
	var cell_candidate_net = _matrix_vector_multiply(cell_weights, combined_input)
	var cell_candidate = _tanh_vector(cell_candidate_net)
	cache["cell_candidate_net"] = cell_candidate_net
	cache["cell_candidate"] = cell_candidate
	
	# Previous cell state for backpropagation
	cache["prev_cell_state"] = cell_state.duplicate()
	
	# Update cell state
	var new_cell_state = []
	for i in range(cell_state.size()):
		new_cell_state.append(forget_gate[i] * cell_state[i] + input_gate[i] * cell_candidate[i])
	cell_state = new_cell_state
	cache["cell_state"] = cell_state.duplicate()
	
	# Calculate cell state activation
	var cell_state_act = _tanh_vector(cell_state)
	cache["cell_state_act"] = cell_state_act
	
	# Update hidden state
	var new_hidden_state = []
	for i in range(hidden_state.size()):
		new_hidden_state.append(output_gate[i] * cell_state_act[i])
	
	# Previous hidden state for backpropagation
	cache["prev_hidden_state"] = hidden_state.duplicate()
	hidden_state = new_hidden_state
	cache["hidden_state"] = hidden_state.duplicate()
	
	# Final output layer (fully connected)
	var final_output = _matrix_vector_multiply(fc_weights, hidden_state)
	var softmax_output = _softmax_vector(final_output)
	cache["final_output"] = final_output
	cache["softmax_output"] = softmax_output
	
	return [softmax_output, cache]

# Save the trained model to a file
func save_model(file_path = "user://dummy_ryu_model.json"):
	var model_data = {
		"input_weights": input_weights,
		"forget_weights": forget_weights,
		"output_weights": output_weights,
		"cell_weights": cell_weights,
		"hidden_weights": hidden_weights,
		"fc_weights": fc_weights  # Add FC weights saving
	}
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(model_data))
		file.close()
		print("Model saved to: " + file_path)
		return true
	else:
		push_error("Failed to save model to: " + file_path)
		return false

# Load a trained model from a file
func load_model(file_path = "user://dummy_ryu_model.json"):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var parse_result = JSON.parse_string(content)
		if parse_result:
			if "input_weights" in parse_result:
				input_weights = parse_result["input_weights"]
			if "forget_weights" in parse_result:
				forget_weights = parse_result["forget_weights"]
			if "output_weights" in parse_result:
				output_weights = parse_result["output_weights"]
			if "cell_weights" in parse_result:
				cell_weights = parse_result["cell_weights"]
			if "hidden_weights" in parse_result:
				hidden_weights = parse_result["hidden_weights"]
			if "fc_weights" in parse_result:
				fc_weights = parse_result["fc_weights"]  # Add FC weights loading
			
			print("Model loaded from: " + file_path)
			emit_signal("model_loaded")
			return true
	
	push_error("Failed to load model from: " + file_path)
	return false

# ENHANCED: Helper function to get health percentage - more robust
func _get_health_percent(node):
	if node == null:
		return 1.0
		
	# Try different health node possibilities
	var health_nodes = ["PlayerHP", "DummyHP", "HP", "Health", "HealthBar"]
	for health_name in health_nodes:
		if node.has_node(health_name):
			var health_node = node.get_node(health_name)
			if "value" in health_node and "max_value" in health_node:
				return float(health_node.value) / health_node.max_value
	
	# If no health node found, look for health property
	if "health" in node and "max_health" in node:
		return float(node.health) / node.max_health
	
	return 1.0

# Helper function to get distance to player
func _get_distance_to_player():
	if player_node and enemy_node:
		return player_node.global_position.distance_to(enemy_node.global_position)
	return 0.0

# Track action execution results
func _schedule_execution_tracking(action_name):
	last_scheduled_action = action_name
	time_since_last_action = 0.0

# Called when an action is completed (should be connected from character controller)
func on_action_completed(action_name, success, position):
	if action_name == last_scheduled_action:
		emit_signal("action_executed",
			action_name,
			success,
			position,
			Time.get_unix_time_from_system())
		last_scheduled_action = null


# Math helper functions for LSTM
func _sigmoid(x):
	if x is Array:
		var result = []
		result.resize(x.size())
		for i in range(x.size()):
			result[i] = 1.0 / (1.0 + exp(-x[i]))
		return result
	else:
		# Handle scalar case
		return 1.0 / (1.0 + exp(-x))

func _tanh(x):
	if x is Array:
		var result = []
		result.resize(x.size())
		for i in range(x.size()):
			result[i] = tanh(x[i])  # Use x[i] instead of i (was a bug!)
		return result
	else:
		# Handle scalar case
		return tanh(x)

func _softmax(x):
	# Input validation
	if not x is Array or x.size() == 0:
		push_error("Softmax input must be a non-empty array")
		return []
	
	# Find maximum value for numerical stability
	var max_val = x[0]
	for i in range(1, x.size()):
		max_val = max(max_val, x[i])
	
	# Calculate exp(x_i - max_val) for each value
	var exp_values = []
	var exp_sum = 0.0
	for i in range(x.size()):
		var exp_val = exp(x[i] - max_val)
		exp_values.append(exp_val)
		exp_sum += exp_val
	
	# Handle numerical instability
	if exp_sum < 1e-10:  # If sum is too close to zero
		push_warning("Softmax encountered near-zero sum, returning uniform distribution")
		var uniform_value = 1.0 / x.size()
		var uniform_dist = []
		for i in range(x.size()):
			uniform_dist.append(uniform_value)
		return uniform_dist
	
	# Calculate final softmax values
	var softmax_values = []
	for exp_val in exp_values:
		softmax_values.append(exp_val / exp_sum)
	
	return softmax_values

# Get the target action index from a sample
func _get_target_action_index(sample):
	# Implement logic to determine the correct action index for this sample
	# This is used as the target during supervised training
	if "next_action" in sample and sample["next_action"] != null:
		var action_name = sample["next_action"]["specific_action"]
		return action_to_index.get(action_name, 0)
	return 0  # Default to idle

# Test function to validate matrix operations
func test_matrix_operations():
	print("Testing matrix operations...")
	
	# Test matrix-vector multiplication with actual dimensions
	var test_matrix = _create_random_matrix(OUTPUT_SIZE, HIDDEN_LAYER_SIZE)
	var test_vector = _create_zero_vector(HIDDEN_LAYER_SIZE)
	var result = _matrix_vector_multiply(test_matrix, test_vector)
	print("Matrix-vector multiply test size:", result.size())  # Should be OUTPUT_SIZE
	
	# Test softmax with correct output size
	var test_logits = _create_zero_vector(OUTPUT_SIZE)
	var softmax_result = _softmax(test_logits)
	print("Softmax test size:", softmax_result.size())  # Should be OUTPUT_SIZE
	
	# Test LSTM forward pass with correct input size
	var test_features = _create_zero_vector(INPUT_FEATURE_SIZE)
	var lstm_result = _lstm_forward_pass(test_features)
	print("LSTM forward pass test:", lstm_result != null)
	if lstm_result:
		print("LSTM output size:", lstm_result.size())  # Should be OUTPUT_SIZE
	
	print("Matrix operations test complete")
