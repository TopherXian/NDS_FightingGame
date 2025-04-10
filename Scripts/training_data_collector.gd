extends Node

# Signal definitions for game events
signal data_saved
signal training_started
signal training_completed

# Constants
const MAX_SEQUENCE_LENGTH = 50  # Maximum length of action sequence to record
const SAVE_INTERVAL = 60.0      # Auto-save data every 60 seconds
const DATA_PATH = "user://training_data/"  # Path to save data files

# Data structures to store gameplay information
var player_actions = []    # Sequence of player actions with timestamps
var enemy_actions = []     # Sequence of enemy (AI) actions with timestamps
var ai_predictions = []    # AI prediction data with game state context
var ai_executions = []     # Results of AI action executions
var combat_outcomes = {}   # Map of combat sequence IDs to outcomes
var session_stats = {
	"hits_landed": 0,
	"hits_taken": 0,
	"combos_executed": 0,
	"damage_dealt": 0,
	"damage_taken": 0,
	"session_duration": 0.0,
	"matches_won": 0,
	"matches_lost": 0
}

# Runtime variables
var session_id = ""
var session_start_time = 0.0
var last_save_time = 0.0
var is_collecting = false
var current_sequence_id = ""
var distance_history = []  # Store distance between characters over time
var health_history = []    # Store health values over time
var last_player_position = Vector2.ZERO
var last_enemy_position = Vector2.ZERO
var last_action_time = 0.0

# Called when the node enters the scene tree for the first time
func _ready():
	# Create a unique session ID based on timestamp
	session_id = "session_" + str(int(Time.get_unix_time_from_system()))
	session_start_time = Time.get_unix_time_from_system()
	last_save_time = session_start_time
	
	# Create data directory if it doesn't exist
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists(DATA_PATH.trim_suffix("/")):
			dir.make_dir_recursive(DATA_PATH.trim_suffix("/"))
	
	print("Training data collector initialized with session ID: " + session_id)

# Called every frame
func _process(delta):
	if is_collecting:
		# Update session duration
		session_stats["session_duration"] += delta
		
		# Auto-save data periodically
		if Time.get_unix_time_from_system() - last_save_time > SAVE_INTERVAL:
			save_training_data()
			last_save_time = Time.get_unix_time_from_system()

# Start collecting training data
func start_collection(player_node, enemy_node):
	if player_node == null or enemy_node == null:
		push_error("Cannot start data collection: Invalid player or enemy node")
		return
		
	is_collecting = true
	current_sequence_id = session_id + "_seq_" + str(int(Time.get_unix_time_from_system()))
	
	# Connect signals from player and enemy nodes
	# For player attacks
	if player_node.has_signal("attack_executed"):
		player_node.connect("attack_executed", Callable(self, "_on_player_attack_executed"))
	
	# For player movement
	if player_node.has_signal("movement_changed"):
		player_node.connect("movement_changed", Callable(self, "_on_player_movement_changed"))
	
	# For enemy hits on player
	if enemy_node.has_signal("attack_executed"):
		enemy_node.connect("attack_executed", Callable(self, "_on_enemy_attack_executed"))
	
	# For health changes
	if player_node.has_signal("health_changed"):
		player_node.connect("health_changed", Callable(self, "_on_player_health_changed"))
	
	if enemy_node.has_signal("health_changed"):
		enemy_node.connect("health_changed", Callable(self, "_on_enemy_health_changed"))
	
	# Connect AI prediction signals if available
	if enemy_node.has_node("AIController"):
		var ai_controller = enemy_node.get_node("AIController")
		
		# Connect to the AI model if available
		if ai_controller.has_method("get_ai_controller"):
			var ai_model = ai_controller.get_ai_controller()
			if ai_model:
				if ai_model.has_signal("prediction_details"):
					ai_model.connect("prediction_details", Callable(self, "_on_ai_prediction_made"))
				if ai_model.has_signal("action_executed"):
					ai_model.connect("action_executed", Callable(self, "_on_ai_action_executed"))
	
	print("Data collection started for sequence: " + current_sequence_id)

# Stop collecting training data
func stop_collection():
	is_collecting = false
	save_training_data()
	print("Data collection stopped for sequence: " + current_sequence_id)
	
	# Disconnect all signals
	var signals = get_incoming_connections()
	for sig in signals:
		if sig.source and sig.signal_name:
			sig.source.disconnect(sig.signal_name, Callable(self, sig.callable_name))

# Record player attack actions
func _on_player_attack_executed(attack_type, position, is_hit, damage):
	if not is_collecting:
		return
		
	var current_time = Time.get_unix_time_from_system()
	var time_since_last = current_time - last_action_time
	last_action_time = current_time
	
	var action_data = {
		"type": "attack",
		"attack_type": attack_type,
		"position": position,
		"timestamp": current_time,
		"time_since_last": time_since_last,
		"is_hit": is_hit,
		"damage": damage,
		"distance_to_enemy": last_player_position.distance_to(last_enemy_position)
	}
	
	player_actions.append(action_data)
	
	if is_hit:
		session_stats["hits_landed"] += 1
		session_stats["damage_dealt"] += damage
		
	# Check if part of a combo (actions within 0.5 seconds)
	if player_actions.size() >= 2:
		var prev_action = player_actions[player_actions.size() - 2]
		if current_time - prev_action["timestamp"] < 0.5 and prev_action["is_hit"] and is_hit:
			session_stats["combos_executed"] += 1
	
	# Trim sequence if too long
	if player_actions.size() > MAX_SEQUENCE_LENGTH:
		player_actions.pop_front()

# Record player movement actions
func _on_player_movement_changed(movement_type, position, velocity):
	if not is_collecting:
		return
		
	var current_time = Time.get_unix_time_from_system()
	var time_since_last = current_time - last_action_time
	last_action_time = current_time
	last_player_position = position
	
	var action_data = {
		"type": "movement",
		"movement_type": movement_type,
		"position": position,
		"velocity": velocity,
		"timestamp": current_time,
		"time_since_last": time_since_last,
		"distance_to_enemy": position.distance_to(last_enemy_position)
	}
	
	player_actions.append(action_data)
	
	# Track character distance
	distance_history.append({
		"timestamp": current_time,
		"distance": position.distance_to(last_enemy_position)
	})
	
	# Trim sequences if too long
	if player_actions.size() > MAX_SEQUENCE_LENGTH:
		player_actions.pop_front()
		
	if distance_history.size() > MAX_SEQUENCE_LENGTH * 2:
		distance_history.pop_front()

# Record enemy attack actions
func _on_enemy_attack_executed(attack_type, position, is_hit, damage):
	if not is_collecting:
		return
		
	var current_time = Time.get_unix_time_from_system()
	last_enemy_position = position
	
	var action_data = {
		"type": "attack",
		"attack_type": attack_type,
		"position": position,
		"timestamp": current_time,
		"is_hit": is_hit,
		"damage": damage,
		"distance_to_player": position.distance_to(last_player_position)
	}
	
	enemy_actions.append(action_data)
	
	if is_hit:
		session_stats["hits_taken"] += 1
		session_stats["damage_taken"] += damage
	
	# Trim sequence if too long
	if enemy_actions.size() > MAX_SEQUENCE_LENGTH:
		enemy_actions.pop_front()

# Record player health changes
func _on_player_health_changed(health, max_health):
	if not is_collecting:
		return
		
	health_history.append({
		"timestamp": Time.get_unix_time_from_system(),
		"entity": "player",
		"health": health,
		"max_health": max_health
	})
	
	# Trim sequence if too long
	if health_history.size() > MAX_SEQUENCE_LENGTH * 2:
		health_history.pop_front()

# Record enemy health changes
func _on_enemy_health_changed(health, max_health):
	if not is_collecting:
		return
		
	health_history.append({
		"timestamp": Time.get_unix_time_from_system(),
		"entity": "enemy",
		"health": health,
		"max_health": max_health
	})
	
	# Trim sequence if too long
	if health_history.size() > MAX_SEQUENCE_LENGTH * 2:
		health_history.pop_front()

# Record a match outcome
func record_match_outcome(player_won, remaining_health, time_taken):
	if player_won:
		session_stats["matches_won"] += 1
	else:
		session_stats["matches_lost"] += 1
	
	combat_outcomes[current_sequence_id] = {
		"player_won": player_won,
		"remaining_health": remaining_health,
		"time_taken": time_taken,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Generate a new sequence ID for the next match
	current_sequence_id = session_id + "_seq_" + str(int(Time.get_unix_time_from_system()))
	save_training_data()

# Record AI predictions
func _on_ai_prediction_made(action_type, confidence, game_state, timestamp):
	if not is_collecting:
		return
	
	var prediction_data = {
		"action_type": action_type,
		"confidence": confidence,
		"game_state": game_state,
		"timestamp": timestamp,
		"player_position": last_player_position if "player_position" not in game_state else game_state["player_position"],
		"enemy_position": last_enemy_position if "enemy_position" not in game_state else game_state["enemy_position"]
	}
	
	ai_predictions.append(prediction_data)
	
	# Trim sequence if too long
	if ai_predictions.size() > MAX_SEQUENCE_LENGTH:
		ai_predictions.pop_front()

# Record AI action execution results
func _on_ai_action_executed(action_type, successful, position, timestamp):
	if not is_collecting:
		return
	
	var execution_data = {
		"action_type": action_type,
		"successful": successful,
		"position": position,
		"timestamp": timestamp,
		"distance_to_player": position.distance_to(last_player_position)
	}
	
	ai_executions.append(execution_data)
	
	# Try to correlate with the prediction that led to this execution
	if ai_predictions.size() > 0:
		var last_matching_prediction = null
		var min_time_diff = INF
		
		# Find the closest prediction by timestamp for this action type
		for prediction in ai_predictions:
			if prediction["action_type"] == action_type:
				var time_diff = timestamp - prediction["timestamp"]
				if time_diff >= 0 and time_diff < min_time_diff:
					min_time_diff = time_diff
					last_matching_prediction = prediction
		
		if last_matching_prediction:
			execution_data["corresponding_prediction"] = last_matching_prediction
	
	# Trim sequence if too long
	if ai_executions.size() > MAX_SEQUENCE_LENGTH:
		ai_executions.pop_front()

# Save the collected training data to disk
func save_training_data():
	if player_actions.size() == 0 and enemy_actions.size() == 0:
		print("No data to save")
		return
		
	var data = {
		"session_id": session_id,
		"timestamp": Time.get_unix_time_from_system(),
		"session_duration": session_stats["session_duration"],
		"player_actions": player_actions,
		"enemy_actions": enemy_actions,
		"ai_predictions": ai_predictions,
		"ai_executions": ai_executions,
		"combat_outcomes": combat_outcomes,
		"session_stats": session_stats,
		"distance_history": distance_history,
		"health_history": health_history
	}
	
	var file_path = DATA_PATH + session_id + ".json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		file.close()
		emit_signal("data_saved")
		print("Training data saved to: " + file_path)
	else:
		push_error("Failed to save training data to: " + file_path)

# Get training data in a format suitable for LSTM training
func get_lstm_training_data():
	var training_data = []
	
	# Process each player action and its surrounding context
	for i in range(player_actions.size()):
		var action = player_actions[i]
		
		# Create a window of previous actions for context (up to 5)
		var context = []
		for j in range(max(0, i-5), i):
			context.append(player_actions[j])
		
		# Find the next action (for supervised learning)
		var next_action = null
		if i < player_actions.size() - 1:
			next_action = player_actions[i + 1]
		
		# Find the nearest enemy action in time
		var nearest_enemy_action = null
		var min_time_diff = INF
		for enemy_action in enemy_actions:
			var time_diff = abs(enemy_action["timestamp"] - action["timestamp"])
			if time_diff < min_time_diff:
				min_time_diff = time_diff
				nearest_enemy_action = enemy_action
		
		# Find the nearest health readings
		var player_health = 100.0  # Default value
		var enemy_health = 100.0   # Default value
		for health_entry in health_history:
			if health_entry["timestamp"] <= action["timestamp"]:
				if health_entry["entity"] == "player":
					player_health = health_entry["health"]
				elif health_entry["entity"] == "enemy":
					enemy_health = health_entry["health"]
		
		# Create a feature vector for LSTM input
		var feature_vector = {
			"action_type": action["type"],
			"specific_action": action["attack_type"] if action["type"] == "attack" else action["movement_type"],
			"position_x": action["position"].x,
			"position_y": action["position"].y,
			"distance_to_enemy": action["distance_to_enemy"] if "distance_to_enemy" in action else 0.0,
			"time_since_last": action["time_since_last"],
			"player_health_percent": player_health,
			"enemy_health_percent": enemy_health,
			"context": context,
			"next_action": next_action,
			"nearest_enemy_action": nearest_enemy_action
		}
		
		training_data.append(feature_vector)
	
	return training_data

# Load previously saved training data
func load_training_data(file_path = ""):
	if file_path.is_empty():
		file_path = DATA_PATH + session_id + ".json"
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var parse_result = JSON.parse_string(content)
		if parse_result:
			# Restore the loaded data into our current session
			if "player_actions" in parse_result:
				player_actions = parse_result["player_actions"]
			if "enemy_actions" in parse_result:
				enemy_actions = parse_result["enemy_actions"]
			if "combat_outcomes" in parse_result:
				combat_outcomes = parse_result["combat_outcomes"]
			if "session_stats" in parse_result:
				session_stats = parse_result["session_stats"]
			if "distance_history" in parse_result:
				distance_history = parse_result["distance_history"]
			if "health_history" in parse_result:
				health_history = parse_result["health_history"]
				
			print("Training data loaded from: " + file_path)
			return true
	
	push_error("Failed to load training data from: " + file_path)
	return false

# Function to normalize action types for feature vectors
func _normalize_action_type(action_type):
	match action_type:
		"attack": return 1.0
		"movement": return 0.0
		_: return 0.0

# Function to normalize specific actions into feature vectors
func _normalize_specific_action(specific_action):
	# Define action mappings with one-hot encoding
	var action_mapping = {
		# Movement actions
		"idle": [1, 0, 0, 0, 0, 0, 0, 0],
		"walk_forward": [0, 1, 0, 0, 0, 0, 0, 0],
		"walk_backward": [0, 0, 1, 0, 0, 0, 0, 0],
		"jump": [0, 0, 0, 1, 0, 0, 0, 0],
		# Attack actions
		"basic_punch": [0, 0, 0, 0, 1, 0, 0, 0],
		"heavy_punch": [0, 0, 0, 0, 0, 1, 0, 0],
		"basic_kick": [0, 0, 0, 0, 0, 0, 1, 0],
		"heavy_kick": [0, 0, 0, 0, 0, 0, 0, 1]
	}
	
	# Return the one-hot encoded vector for the action, or a default vector for unknown actions
	return action_mapping.get(specific_action, [1, 0, 0, 0, 0, 0, 0, 0])

# Function to convert normalized vectors back to action names
func _denormalize_action_vector(vector):
	# Find the index with the highest value
	var max_idx = 0
	var max_val = vector[0]
	
	for i in range(1, vector.size()):
		if vector[i] > max_val:
			max_val = vector[i]
			max_idx = i
	
	# Map index back to action name
	var idx_to_action = {
		0: "idle",
		1: "walk_forward",
		2: "walk_backward",
		3: "jump",
		4: "basic_punch",
		5: "heavy_punch",
		6: "basic_kick",
		7: "heavy_kick"
	}
	
	return idx_to_action.get(max_idx, "idle")

# Function to normalize position values
func _normalize_position(pos: Vector2, screen_size: Vector2) -> Vector2:
	return Vector2(
		pos.x / screen_size.x,
		pos.y / screen_size.y
	)

# Function to normalize velocity values
func _normalize_velocity(vel: Vector2, max_velocity: float) -> Vector2:
	return Vector2(
		vel.x / max_velocity,
		vel.y / max_velocity
	)

# Convert data for export to other ML tools
func export_data_for_external_training():
	var export_data = {
		"features": [],
		"labels": []
	}
	
	var training_data = get_lstm_training_data()
	for entry in training_data:
		if entry["next_action"] != null:
			# Feature vector with normalized values
			var features = [
				_normalize_action_type(entry["action_type"]),
				entry["position_x"],
				entry["position_y"],
				entry["distance_to_enemy"],
				entry["time_since_last"],
				entry["player_health_percent"],
				entry["enemy_health_percent"]
			]
			
			# Add one-hot encoded current action
			features.append_array(_normalize_specific_action(entry["specific_action"]))
			
			# Target is the next action (as one-hot vector)
			var target = _normalize_specific_action(entry["next_action"]["specific_action"])
			
			export_data["features"].append(features)
			export_data["labels"].append(target)
	
	return export_data
