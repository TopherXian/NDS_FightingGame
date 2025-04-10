extends Node

class_name DifficultyAdjuster

# Signal definitions
signal difficulty_changed(new_level, reason)
signal player_skill_updated(skill_level)
signal adjustment_log(message)

# Constants for difficulty scaling
const MIN_DIFFICULTY = 0.1  # Minimum difficulty level (easiest)
const MAX_DIFFICULTY = 0.95  # Maximum difficulty level (hardest)
const DEFAULT_DIFFICULTY = 0.5  # Default starting difficulty
const ADJUSTMENT_RATE = 0.05   # How quickly difficulty changes (per evaluation)
const DIFFICULTY_SMOOTHING = 0.7  # Higher values = smoother transitions (0.0-1.0)
const EVALUATION_INTERVAL = 5.0  # Seconds between difficulty evaluations

# Skill evaluation weights
const WEIGHTS = {
	"hit_ratio": 0.25,        # Importance of player's hit/miss ratio
	"health_management": 0.2,  # Importance of health difference
	"combo_skill": 0.25,       # Importance of combo execution
	"reaction_time": 0.15,     # Importance of player reaction time
	"spatial_control": 0.15    # Importance of positional advantage
}

# Skill metrics
var skill_metrics = {
	"hit_ratio": 0.5,        # Player hit success rate (0.0-1.0)
	"health_management": 0.5, # Health preserved vs opponent (0.0-1.0)
	"combo_skill": 0.5,       # Combo execution frequency (0.0-1.0)
	"reaction_time": 0.5,     # Normalized reaction time (0.0-1.0)
	"spatial_control": 0.5    # Player's control of space (0.0-1.0)
}

# Runtime variables
var current_difficulty = DEFAULT_DIFFICULTY
var target_difficulty = DEFAULT_DIFFICULTY
var player_skill_level = 0.5  # Overall skill assessment (0.0-1.0)
var evaluation_timer = 0.0
var data_collector = null
var ai_controller = null
var ai_params = {
	"reaction_time": 0.3,     # Base time in seconds for AI to react
	"attack_complexity": 0.5,  # Complexity of attack patterns (0.0-1.0)
	"defensive_behavior": 0.5, # Tendency to prioritize defense (0.0-1.0)
	"aggression": 0.5         # Tendency to approach and attack (0.0-1.0)
}
var match_history = []        # Track recent match performances
var last_evaluation_time = 0.0
var debug_mode = false

# Called when the node enters the scene tree
func _ready():
	log_message("Difficulty Adjuster initialized at level: " + str(current_difficulty))

# Called every frame
func _process(delta):
	# Update timer for periodic evaluation
	evaluation_timer += delta
	
	# Check if it's time for a difficulty evaluation
	if evaluation_timer >= EVALUATION_INTERVAL:
		evaluate_player_skill()
		evaluation_timer = 0.0
	
	# Smoothly transition current difficulty toward target
	if abs(current_difficulty - target_difficulty) > 0.01:
		current_difficulty = lerp(current_difficulty, target_difficulty, 
			(1.0 - DIFFICULTY_SMOOTHING) * delta * 3.0)
		_update_ai_parameters()

# Connect to necessary components
func setup(collector, ai_ctrl):
	data_collector = collector
	ai_controller = ai_ctrl
	
	if data_collector == null or ai_controller == null:
		push_error("Difficulty Adjuster: Missing required components")
		return false
	
	# Apply initial difficulty setting
	ai_controller.set_difficulty(current_difficulty)
	
	log_message("Difficulty Adjuster setup complete")
	return true

# Set the difficulty level directly (for manual control)
func set_difficulty(level, reason = "manual"):
	target_difficulty = clamp(level, MIN_DIFFICULTY, MAX_DIFFICULTY)
	log_message("Difficulty target set to " + str(target_difficulty) + " (" + reason + ")")
	emit_signal("difficulty_changed", target_difficulty, reason)
	_update_ai_parameters()

# Main function to evaluate player skill and adjust difficulty
func evaluate_player_skill():
	if data_collector == null:
		push_error("Cannot evaluate player skill: Data collector not available")
		return
	
	# Extract metrics from the data collector
	_calculate_hit_ratio()
	_calculate_health_management()
	_calculate_combo_skill()
	_calculate_reaction_time()
	_calculate_spatial_control()
	
	# Calculate overall skill level as weighted average of metrics
	var new_skill_level = 0.0
	for metric in skill_metrics:
		new_skill_level += skill_metrics[metric] * WEIGHTS[metric]
	
	# Update player skill level with some smoothing
	player_skill_level = lerp(player_skill_level, new_skill_level, 0.3)
	emit_signal("player_skill_updated", player_skill_level)
	
	# Determine target difficulty based on skill level
	_adjust_difficulty_based_on_skill()
	
	last_evaluation_time = Time.get_unix_time_from_system()
	log_message("Player skill evaluated: " + str(player_skill_level) + ", Difficulty: " + str(current_difficulty))

# Record match result for difficulty adjustment
func record_match_result(player_won, player_health, enemy_health, match_duration):
	var result = {
		"timestamp": Time.get_unix_time_from_system(),
		"player_won": player_won,
		"player_health": player_health,
		"enemy_health": enemy_health,
		"duration": match_duration,
		"difficulty": current_difficulty
	}
	
	match_history.append(result)
	
	# Keep only the last 5 matches for trend analysis
	if match_history.size() > 5:
		match_history.pop_front()
	
	# Immediate adjustment based on match outcome
	_adjust_after_match(result)

# Calculate hit success ratio from collected data
func _calculate_hit_ratio():
	if not data_collector or data_collector.session_stats.size() == 0:
		return
	
	var hits_attempted = data_collector.session_stats["hits_landed"] + data_collector.player_actions.size() * 0.2
	if hits_attempted > 0:
		skill_metrics["hit_ratio"] = min(1.0, float(data_collector.session_stats["hits_landed"]) / hits_attempted)
	else:
		skill_metrics["hit_ratio"] = 0.5  # Default if no data

# Calculate health management effectiveness
func _calculate_health_management():
	if not data_collector or data_collector.health_history.size() == 0:
		return
	
	# Get the latest health values
	var player_health = 1.0
	var enemy_health = 1.0
	
	for entry in data_collector.health_history:
		if entry["entity"] == "player":
			player_health = float(entry["health"]) / float(entry["max_health"])
		elif entry["entity"] == "enemy":
			enemy_health = float(entry["health"]) / float(entry["max_health"])
	
	# Calculate ratio of player health to enemy health
	if enemy_health > 0:
		var health_ratio = player_health / max(0.1, enemy_health)
		skill_metrics["health_management"] = clamp(health_ratio, 0.0, 1.0)
	else:
		skill_metrics["health_management"] = 1.0

# Calculate combo execution skill
func _calculate_combo_skill():
	if not data_collector or data_collector.session_stats.size() == 0:
		return
	
	var hits_landed = data_collector.session_stats["hits_landed"]
	var combos_executed = data_collector.session_stats["combos_executed"]
	
	if hits_landed > 0:
		skill_metrics["combo_skill"] = min(1.0, float(combos_executed) / max(1, hits_landed / 3))
	else:
		skill_metrics["combo_skill"] = 0.5  # Default if no data

# Calculate player reaction time
func _calculate_reaction_time():
	if not data_collector or data_collector.player_actions.size() < 2:
		return
	
	# Calculate average time between player actions
	var total_time = 0.0
	var count = 0
	
	for i in range(1, min(10, data_collector.player_actions.size())):
		var action = data_collector.player_actions[data_collector.player_actions.size() - i]
		if "time_since_last" in action:
			total_time += action["time_since_last"]
			count += 1
	
	if count > 0:
		var avg_time = total_time / count
		# Normalize: faster reaction = higher skill (inverse relationship)
		# Typical reaction time range: 0.2s (very fast) to 1.0s (slow)
		skill_metrics["reaction_time"] = clamp(1.0 - (avg_time - 0.2) / 0.8, 0.0, 1.0)
	else:
		skill_metrics["reaction_time"] = 0.5  # Default if no data

# Calculate spatial control (positioning skill)
func _calculate_spatial_control():
	if not data_collector or data_collector.distance_history.size() == 0:
		return
	
	# Calculate average distance maintained
	var optimal_distance = 150.0  # Typical good fighting distance
	var total_deviation = 0.0
	var count = 0
	
	for i in range(min(20, data_collector.distance_history.size())):
		var entry = data_collector.distance_history[data_collector.distance_history.size() - 1 - i]
		var deviation = abs(entry["distance"] - optimal_distance)
		total_deviation += deviation
		count += 1
	
	if count > 0:
		var avg_deviation = total_deviation / count
		# Normalize: closer to optimal = higher skill
		skill_metrics["spatial_control"] = clamp(1.0 - avg_deviation / 300.0, 0.0, 1.0)
	else:
		skill_metrics["spatial_control"] = 0.5  # Default if no data

# Adjust difficulty based on calculated skill level
func _adjust_difficulty_based_on_skill():
	# Calculate target difficulty based on player skill
	# Map player skill (0.0-1.0) to difficulty (MIN-MAX)
	# Using a slightly curved mapping - better players get more challenge
	var skill_factor = pow(player_skill_level, 1.2)  # Slight curve
	var new_target = lerp(MIN_DIFFICULTY, MAX_DIFFICULTY, skill_factor)
	
	# Apply a maximum change limit for smoother transitions
	var max_change = ADJUSTMENT_RATE
	var diff_change = clamp(new_target - target_difficulty, -max_change, max_change)
	target_difficulty = clamp(target_difficulty + diff_change, MIN_DIFFICULTY, MAX_DIFFICULTY)
	
	log_message("Difficulty adjustment: " + str(target_difficulty) + " based on skill: " + str(player_skill_level))
	emit_signal("difficulty_changed", target_difficulty, "skill_evaluation")

# Quick adjustment after match results
func _adjust_after_match(result):
	var adjustment = 0.0
	
	# Player won - make it harder, player lost - make it easier
	if result["player_won"]:
		# Player won with high health - significant increase
		if result["player_health"] > 0.7:
			adjustment = 0.1
		# Player won with medium health - moderate increase
		elif result["player_health"] > 0.3:
			adjustment = 0.05
		# Player barely won - small increase
		else:
			adjustment = 0.02
	else:
		# Player was demolished - significant decrease
		if result["player_health"] < 0.2:
			adjustment = -0.15
		# Player lost badly - moderate decrease
		elif result["player_health"] < 0.5:
			adjustment = -0.08
		# Player almost won - small decrease
		else:
			adjustment = -0.03
	
	# Quick balance for match duration
	var expected_duration = 60.0  # Expected match duration in seconds
	if result["duration"] < expected_duration * 0.5:
		# Match ended too quickly, amplify adjustment
		adjustment *= 1.5
	
	# Apply the adjustment
	target_difficulty = clamp(target_difficulty + adjustment, MIN_DIFFICULTY, MAX_DIFFICULTY)
	log_message("Post-match adjustment: " + str(adjustment) + ", New target: " + str(target_difficulty))
	emit_signal("difficulty_changed", target_difficulty, "match_result")

# Update AI parameters based on current difficulty
func _update_ai_parameters():
	if ai_controller == null:
		return
	
	# Apply current difficulty to the AI controller
	ai_controller.set_difficulty(current_difficulty)
	
	# Calculate specific AI behavioral parameters
	ai_params["reaction_time"] = lerp(0.5, 0.1, current_difficulty)  # Faster reactions at higher difficulty
	ai_params["attack_complexity"] = current_difficulty  # More complex attacks at higher difficulty
	ai_params["defensive_behavior"] = lerp(0.3, 0.7, current_difficulty)  # More defensive at higher difficulty
	ai_params["aggression"] = lerp(0.4, 0.8, current_difficulty)  # More aggressive at higher difficulty
	
	# You could add these as properties to the AI controller if implemented
	if ai_controller.has_method("set_reaction_time"):
		ai_controller.set_reaction_time(ai_params["reaction_time"])
	
	if ai_controller.has_method("set_attack_complexity"):
		ai_controller.set_attack_complexity(ai_params["attack_complexity"])
	
	if ai_controller.has_method("set_defensive_behavior"):
		ai_controller.set_defensive_behavior(ai_params["defensive_behavior"])
	
	if ai_controller.has_method("set_aggression"):
		ai_controller.set_aggression(ai_params["aggression"])

# Get current difficulty assessment for UI or other systems
func get_difficulty_stats():
	return {
		"current_difficulty": current_difficulty,
		"target_difficulty": target_difficulty,
		"player_skill_level": player_skill_level,
		"skill_metrics": skill_metrics,
		"ai_params": ai_params
	}

# Enable/disable debug mode for additional logging
func set_debug_mode(enabled):
	debug_mode = enabled
	log_message("Debug mode " + ("enabled" if enabled else "disabled"))

# Log a message and emit signal
func log_message(message):
	if debug_mode:
		print("DifficultyAdjuster: " + message)
	emit_signal("adjustment_log", message)
