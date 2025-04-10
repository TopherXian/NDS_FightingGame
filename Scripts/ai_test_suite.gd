extends Node

# UI References
@onready var output_label = $CanvasLayer/OutputLabel
@onready var test_status_label = $CanvasLayer/StatusLabel
@onready var progress_bar = $CanvasLayer/ProgressBar

# Test Components
var data_collector = null
var ai_controller = null
var difficulty_adjuster = null
var dummy_character = null
var player_character = null

# Test variables
var current_test = ""
var tests_completed = 0
var tests_passed = 0
var total_tests = 16
var is_testing = false
var test_data = {}
var test_start_time = 0

# Test sequence - all test functions should start with "test_"
var test_sequence = [
	"test_data_collector_initialization",
	"test_data_storage",
	"test_action_logging",
	"test_combat_metrics_tracking",
	"test_ai_controller_initialization",
	"test_feature_extraction",
	"test_lstm_prediction",
	"test_action_execution",
	"test_difficulty_adjuster_initialization",
	"test_difficulty_calculation",
	"test_skill_metrics",
	"test_difficulty_response",
	"test_animation_syncing",
	"test_hitbox_activation",
	"test_signal_connections",
	"test_performance"
]

# Called when the node enters the scene tree
func _ready():
	# Initialize UI
	output_label.text = "AI Test Suite Ready\nPress Start to begin tests"
	test_status_label.text = "Status: Ready"
	progress_bar.max_value = total_tests
	progress_bar.value = 0

# Start running all tests
func start_tests():
	if is_testing:
		return
		
	is_testing = true
	tests_completed = 0
	tests_passed = 0
	test_data = {}
	test_start_time = Time.get_unix_time_from_system()
	
	output_label.text = "Starting AI system tests...\n"
	test_status_label.text = "Status: Testing"
	
	# Find character references
	_find_character_references()
	
	# Run first test
	call_deferred("run_next_test")

# Find the player and dummy character nodes
func _find_character_references():
	# Try to find dummy_ryu
	var dummy_nodes = get_tree().get_nodes_in_group("Dummy")
	if dummy_nodes.size() > 0:
		dummy_character = dummy_nodes[0]
		log_output("Found dummy character: " + dummy_character.name)
	else:
		log_output("WARNING: Dummy character not found!")
	
	# Try to find player
	var player_nodes = get_tree().get_nodes_in_group("Player")
	if player_nodes.size() > 0:
		player_character = player_nodes[0]
		log_output("Found player character: " + player_character.name)
	else:
		log_output("WARNING: Player character not found!")
	
	# Get AI components from dummy if available
	if dummy_character:
		if dummy_character.has_node("AIController") and dummy_character.get_node("AIController").has_method("get_ai_controller"):
			ai_controller = dummy_character.get_node("AIController").get_ai_controller()
			log_output("Found AI controller")
		
		if dummy_character.has_node("AIController") and dummy_character.get_node("AIController").has_method("get_data_collector"):
			data_collector = dummy_character.get_node("AIController").get_data_collector()
			log_output("Found data collector")
			
		if dummy_character.has_node("AIController") and dummy_character.get_node("AIController").has_method("get_difficulty_adjuster"):
			difficulty_adjuster = dummy_character.get_node("AIController").get_difficulty_adjuster()
			log_output("Found difficulty adjuster")

# Run the next test in the sequence
func run_next_test():
	if tests_completed >= test_sequence.size():
		_finish_tests()
		return
	
	current_test = test_sequence[tests_completed]
	log_output("\n--- Running Test: " + current_test + " ---")
	
	# Call the test function
	call(current_test)
	
	# Update progress
	tests_completed += 1
	progress_bar.value = tests_completed
	
	# Schedule next test
	await get_tree().create_timer(0.5).timeout
	call_deferred("run_next_test")

# Finish testing and show results
func _finish_tests():
	is_testing = false
	var test_duration = Time.get_unix_time_from_system() - test_start_time
	
	var result_text = "\n--- Test Results ---\n"
	result_text += "Tests Passed: " + str(tests_passed) + "/" + str(total_tests) + "\n"
	result_text += "Duration: " + str(test_duration) + " seconds\n"
	
	if tests_passed == total_tests:
		result_text += "\nAll tests PASSED! The AI system is functioning correctly."
		test_status_label.text = "Status: PASSED"
	else:
		result_text += "\nSome tests FAILED. Check the log for details."
		test_status_label.text = "Status: FAILED"
	
	log_output(result_text)

# Log output to the UI
func log_output(text):
	output_label.text += text + "\n"
	# Auto-scroll to bottom
	await get_tree().process_frame
	output_label.scroll_to_line(output_label.get_line_count())

# Mark a test as passed
func test_passed(message = ""):
	tests_passed += 1
	log_output("✅ PASSED: " + (message if message else current_test))

# Mark a test as failed
func test_failed(message = ""):
	log_output("❌ FAILED: " + (message if message else current_test))

# Create simulated data for testing
func _create_test_data():
	# Create test player actions
	var player_actions = []
	for i in range(10):
		player_actions.append({
			"type": "attack" if i % 2 == 0 else "movement",
			"attack_type": "basic_punch" if i % 4 == 0 else "heavy_kick",
			"movement_type": "walk_forward" if i % 3 == 0 else "walk_backward",
			"position": Vector2(100 + i * 10, 300),
			"timestamp": Time.get_unix_time_from_system() - (10 - i),
			"time_since_last": 0.5,
			"is_hit": i % 3 == 0,
			"damage": 5 if i % 3 == 0 else 0,
			"distance_to_enemy": 100 - i * 5
		})
	
	# Create test enemy actions
	var enemy_actions = []
	for i in range(8):
		enemy_actions.append({
			"type": "attack" if i % 2 == 1 else "movement",
			"attack_type": "basic_kick" if i % 3 == 0 else "heavy_punch",
			"movement_type": "jump" if i % 4 == 0 else "walk_backward",
			"position": Vector2(300 - i * 10, 300),
			"timestamp": Time.get_unix_time_from_system() - (8 - i),
			"is_hit": i % 4 == 0,
			"damage": 3 if i % 4 == 0 else 0,
			"distance_to_player": 100 - i * 5
		})
	
	# Create test health history
	var health_history = []
	for i in range(5):
		health_history.append({
			"timestamp": Time.get_unix_time_from_system() - (5 - i),
			"entity": "player" if i % 2 == 0 else "enemy",
			"health": 100 - i * 5,
			"max_health": 100
		})
	
	# Create test distance history
	var distance_history = []
	for i in range(15):
		distance_history.append({
			"timestamp": Time.get_unix_time_from_system() - (15 - i) * 0.2,
			"distance": 150 + sin(i * 0.5) * 50
		})
	
	return {
		"player_actions": player_actions,
		"enemy_actions": enemy_actions,
		"health_history": health_history,
		"distance_history": distance_history,
		"session_stats": {
			"hits_landed": 4,
			"hits_taken": 2,
			"combos_executed": 1,
			"damage_dealt": 20,
			"damage_taken": 6,
			"session_duration": 60.0,
			"matches_won": 1,
			"matches_lost": 0
		}
	}

#
# DATA COLLECTOR TESTS
#

# Test data collector initialization
func test_data_collector_initialization():
	if data_collector:
		if data_collector.session_id != "" and data_collector.session_start_time > 0:
			test_passed("Data collector initialized with session ID: " + data_collector.session_id)
		else:
			test_failed("Data collector found but not properly initialized")
	else:
		# Create a new data collector for testing
		data_collector = load("res://Scripts/training_data_collector.gd").new()
		add_child(data_collector)
		
		if data_collector.session_id != "" and data_collector.session_start_time > 0:
			test_passed("Created new data collector successfully")
		else:
			test_failed("Failed to initialize new data collector")

# Test data storage functionality
func test_data_storage():
	if not data_collector:
		test_failed("No data collector available")
		return
	
	# Load test data
	var test_data = _create_test_data()
	
	# Copy test data to collector
	data_collector.player_actions = test_data.player_actions.duplicate(true)
	data_collector.enemy_actions = test_data.enemy_actions.duplicate(true)
	data_collector.health_history = test_data.health_history.duplicate(true)
	data_collector.distance_history = test_data.distance_history.duplicate(true)
	data_collector.session_stats = test_data.session_stats.duplicate(true)
	
	# Try to save data
	var save_path = "user://test_data.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	
	if file:
		var save_data = {
			"session_id": data_collector.session_id,
			"timestamp": Time.get_unix_time_from_system(),
			"player_actions": data_collector.player_actions,
			"enemy_actions": data_collector.enemy_actions,
			"health_history": data_collector.health_history,
			"session_stats": data_collector.session_stats
		}
		
		file.store_string(JSON.stringify(save_data))
		file.close()
		
		# Try to read it back
		file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			
			var parse_result = JSON.parse_string(content)
			if parse_result and "player_actions" in parse_result and parse_result.player_actions.size() == test_data.player_actions.size():
				test_passed("Data storage and retrieval working correctly")
			else:
				test_failed("Data retrieval failed or data mismatch")
		else:
			test_failed("Could not read back saved data")
	else:
		test_failed("Could not save test data to file")

# Test action logging
func test_action_logging():
	if not data_collector:
		test_failed("No data collector available")
		return
	
	var initial_action_count = data_collector.player_actions.size()
	
	# Simulate adding a new action
	data_collector._on_player_attack_executed(
		"basic_punch", 
		Vector2(100, 300), 
		true, 
		5
	)
	
	if data_collector.player_actions.size() > initial_action_count:
		test_passed("Action logging working correctly")
	else:
		test_failed("Failed to log new action")

# Test combat metrics tracking
func test_combat_metrics_tracking():
	if not data_collector:
		test_failed("No data collector available")
		return
	
	var initial_hits = data_collector.session_stats["hits_landed"]
	var initial_damage = data_collector.session_stats["damage_dealt"]
	
	# Simulate a successful hit
	data_collector._on_player_attack_executed(
		"heavy_kick", 
		Vector2(100, 300), 
		true,  # is_hit
		10     # damage
	)
	
	if data_collector.session_stats["hits_landed"] > initial_hits and data_collector.session_stats["damage_dealt"] > initial_damage:
		test_passed("Combat metrics tracking working correctly")
	else:
		test_failed("Failed to update combat metrics")

#
# AI CONTROLLER TESTS
#

# Test AI controller initialization
func test_ai_controller_initialization():
	if ai_controller:
		if ai_controller.hidden_state.size() > 0 and ai_controller.cell_state.size() > 0:
			test_passed("AI controller initialized with LSTM state")
		else:
			test_failed("AI controller found but LSTM state not initialized")
	else:
		# Create a new AI controller for testing
		ai_controller = load("res://Scripts/dummy_ryu_ai.gd").new()
		add_child(ai_controller)
		
		await get_tree().process_frame
		
		if ai_controller.hidden_state.size() > 0 and ai_controller.cell_state.size() > 0:
			test_passed("Created new AI controller successfully")
		else:
			test_failed("Failed to initialize new AI controller")

# Test feature extraction
func test_feature_extraction():
	if not ai_controller:
		test_failed("No AI controller available")
		return
	
	# Create mock player and enemy to extract features from
	var mock_player = Node2D.new()
	mock_player.global_position = Vector2(100, 300)
	mock_player.velocity = Vector2(10, 0)
	var player_hp = Control.new()
	player_hp.name = "PlayerHP"
	player_hp.value = 80
	player_hp.max_value = 100
	mock_player.add_child(player_hp)
	add_child(mock_player)
	
	var mock_enemy = Node2D.new()
	mock_enemy.global_position = Vector2(300, 300)
	mock_enemy.velocity = Vector2(0, 0)
	var enemy_hp = Control.new()
	enemy_hp.name = "DummyHP"
	enemy_hp.value = 60
	enemy_hp.max_value = 100
	mock_enemy.add_child(enemy_hp)

# Test LSTM prediction
func test_lstm_prediction():
	if not ai_controller:
		test_failed("No AI controller available")
		return
	
	# Initialize necessary states
	if not ai_controller.is_connected("action_predicted", Callable(self, "_on_test_action_predicted")):
		ai_controller.connect("action_predicted", Callable(self, "_on_test_action_predicted"))
	
	test_data["prediction_received"] = false
	test_data["predicted_action"] = ""
	
	# Force a prediction
	if ai_controller.has_method("predict_next_action"):
		ai_controller.predict_next_action()
		
		# Wait for prediction to complete
		await get_tree().create_timer(1.0).timeout
		
		if test_data["prediction_received"]:
			test_passed("LSTM prediction generated action: " + test_data["predicted_action"])
		else:
			test_failed("No prediction received within timeout")
	else:
		test_failed("AI controller missing predict_next_action method")
	
	# Disconnect to avoid interference with other tests
	if ai_controller.is_connected("action_predicted", Callable(self, "_on_test_action_predicted")):
		ai_controller.disconnect("action_predicted", Callable(self, "_on_test_action_predicted"))

# Test action execution
func test_action_execution():
	if not dummy_character:
		test_failed("No dummy character available")
		return
	
	var original_position = dummy_character.global_position
	var original_velocity = dummy_character.velocity
	
	# Try to execute an action
	if dummy_character.has_method("_on_ai_action_predicted"):
		# Execute a movement action
		dummy_character._on_ai_action_predicted("walk_forward", {})
		
		# Let physics process run
		await get_tree().physics_frame
		await get_tree().physics_frame
		
		var position_changed = dummy_character.global_position != original_position
		var velocity_changed = dummy_character.velocity != original_velocity
		
		if position_changed or velocity_changed:
			test_passed("Action execution affected character state")
		else:
			test_failed("Action execution did not affect character state")
	else:
		test_failed("Dummy character missing required action execution method")

#
# DIFFICULTY ADJUSTER TESTS
#

# Test difficulty adjuster initialization
func test_difficulty_adjuster_initialization():
	if difficulty_adjuster:
		if difficulty_adjuster.current_difficulty > 0 and difficulty_adjuster.player_skill_level >= 0:
			test_passed("Difficulty adjuster initialized with valid state")
		else:
			test_failed("Difficulty adjuster found but not properly initialized")
	else:
		# Create a new difficulty adjuster for testing
		difficulty_adjuster = load("res://Scripts/difficulty_adjuster.gd").new()
		add_child(difficulty_adjuster)
		
		await get_tree().process_frame
		
		if difficulty_adjuster.current_difficulty > 0:
			test_passed("Created new difficulty adjuster successfully")
		else:
			test_failed("Failed to initialize new difficulty adjuster")

# Test difficulty calculation
func test_difficulty_calculation():
	if not difficulty_adjuster:
		test_failed("No difficulty adjuster available")
		return
	
	# Test manual difficulty setting
	var original_difficulty = difficulty_adjuster.current_difficulty
	var test_difficulty = 0.75
	
	difficulty_adjuster.set_difficulty(test_difficulty, "test")
	
	if abs(difficulty_adjuster.target_difficulty - test_difficulty) < 0.01:
		test_passed("Difficulty setting mechanism working correctly")
	else:
		test_failed("Failed to set difficulty level")

# Test skill metrics calculation
func test_skill_metrics():
	if not difficulty_adjuster or not data_collector:
		test_failed("Missing required components")
		return
	
	# Set up difficulty adjuster with data collector
	if not difficulty_adjuster.data_collector:
		difficulty_adjuster.setup(data_collector, ai_controller)
	
	# Load test data into data collector
	var test_data = _create_test_data()
	data_collector.player_actions = test_data.player_actions.duplicate(true)
	data_collector.enemy_actions = test_data.enemy_actions.duplicate(true)
	data_collector.health_history = test_data.health_history.duplicate(true)
	data_collector.session_stats = test_data.session_stats.duplicate(true)
	
	# Calculate skill metrics
	difficulty_adjuster._calculate_hit_ratio()
	difficulty_adjuster._calculate_combo_skill()
	
	# Check if calculations produced valid results
	if difficulty_adjuster.skill_metrics["hit_ratio"] >= 0 and difficulty_adjuster.skill_metrics["hit_ratio"] <= 1.0:
		test_passed("Skill metrics calculation working correctly")
	else:
		test_failed("Skill metrics calculation produced invalid results")

# Test difficulty response to match outcomes
func test_difficulty_response():
	if not difficulty_adjuster:
		test_failed("No difficulty adjuster available")
		return
	
	# Record current difficulty
	var original_difficulty = difficulty_adjuster.target_difficulty
	
	# Simulate a player loss (should make game easier)
	difficulty_adjuster.record_match_result(
		false,  # player_won
		0.2,    # player_health (low)
		0.8,    # enemy_health (high)
		30.0    # match_duration
	)
	
	var easier_difficulty = difficulty_adjuster.target_difficulty
	
	# Reset for next test
	difficulty_adjuster.target_difficulty = original_difficulty
	
	# Simulate a player win (should make game harder)
	difficulty_adjuster.record_match_result(
		true,   # player_won
		0.8,    # player_health (high)
		0.2,    # enemy_health (low)
		30.0    # match_duration
	)
	
	var harder_difficulty = difficulty_adjuster.target_difficulty
	
	# Check if difficulty responded correctly
	if easier_difficulty < original_difficulty and harder_difficulty > original_difficulty:
		test_passed("Difficulty responds appropriately to match outcomes")
	else:
		test_failed("Difficulty adjustment not responding correctly to match outcomes")

#
# INTEGRATION TESTS
#

# Test animation syncing with AI actions
func test_animation_syncing():
	if not dummy_character:
		test_failed("No dummy character available")
		return
	
	var animation_player = null
	if dummy_character.has_node("Dummy_Animation"):
		animation_player = dummy_character.get_node("Dummy_Animation")
	
	if not animation_player:
		test_failed("Animation player not found")
		return
	
	var current_animation = animation_player.current_animation
	
	# Try to trigger an animation change
	if dummy_character.has_method("_on_ai_action_predicted"):
		dummy_character._on_ai_action_predicted("idle", {})
		
		# Let animation system update
		await get_tree().process_frame
		await get_tree().process_frame
		
		if animation_player.current_animation == "idle":
			test_passed("Animation syncing working correctly")
		else:
			test_failed("Animation did not update with AI action")
	else:
		test_failed("Missing required method for animation syncing test")

# Test hitbox activation during attacks
func test_hitbox_activation():
	if not dummy_character or not dummy_character.has_node("Dummy_Hitbox"):
		test_failed("No dummy character or hitbox available")
		return
	
	var hitbox = dummy_character.get_node("Dummy_Hitbox")
	var initial_monitoring = hitbox.monitoring
	
	# Force hitbox disabled initially for testing
	hitbox.monitoring = false
	hitbox.monitorable = false
	
	# Execute an attack action which should enable the hitbox
	if dummy_character.has_method("_perform_attack"):
		dummy_character._perform_attack("basic_punch")
		
		# Give a short time for hitbox to activate
		await get_tree().create_timer(0.1).timeout
		
		if hitbox.monitoring:
			test_passed("Hitbox activation during attacks working correctly")
		else:
			test_failed("Hitbox not activated during attack")
	else:
		test_failed("Attack execution method not available")

# Test signal connections between components
func test_signal_connections():
	var signal_count = 0
	
	# Check data collector signals
	if data_collector:
		var data_signals = data_collector.get_signal_connection_list("data_saved")
		signal_count += data_signals.size()
	
	# Check AI controller signals
	if ai_controller:
		var ai_signals = ai_controller.get_signal_connection_list("action_predicted")
		signal_count += ai_signals.size()
	
	# Check difficulty adjuster signals
	if difficulty_adjuster:
		var difficulty_signals = difficulty_adjuster.get_signal_connection_list("difficulty_changed")
		signal_count += difficulty_signals.size()
	
	# Check if at least some signals are connected
	if signal_count > 0:
		test_passed("Components have " + str(signal_count) + " signal connections")
	else:
		test_failed("No signal connections found between components")

# Test system performance
func test_performance():
	if not ai_controller:
		test_failed("No AI controller available")
		return
	
	# Measure time to generate predictions
	var start_time = Time.get_unix_time_from_system()
	var prediction_count = 0
	
	# Connect to prediction signal
	if not ai_controller.is_connected("action_predicted", Callable(self, "_on_performance_prediction")):
		ai_controller.connect("action_predicted", Callable(self, "_on_performance_prediction"))
	
	test_data["prediction_count"] = 0
	
	# Generate multiple predictions
	for i in range(5):
		if ai_controller.has_method("predict_next_action"):
			ai_controller.predict_next_action()
		await get_tree().create_timer(0.1).timeout
	
	# Wait for predictions to complete
	await get_tree().create_timer(1.0).timeout
	
	var end_time = Time.get_unix_time_from_system()
	var time_elapsed = end_time - start_time
	
	# Disconnect signal
	if ai_controller.is_connected("action_predicted", Callable(self, "_on_performance_prediction")):
		ai_controller.disconnect("action_predicted", Callable(self, "_on_performance_prediction"))
	
	# Evaluate performance
	if test_data["prediction_count"] > 0:
		var avg_time = time_elapsed / test_data["prediction_count"]
		log_output("Average prediction time: " + str(avg_time) + " seconds")
		
		if avg_time < 0.5:  # Less than 500ms per prediction is acceptable
			test_passed("Performance acceptable: " + str(avg_time) + "s per prediction")
		else:
			test_failed("Performance might be too slow: " + str(avg_time) + "s per prediction")
	else:
		test_failed("No predictions were generated")

#
# SIGNAL CALLBACKS
#

# For LSTM prediction test
func _on_test_action_predicted(action_type, params):
	test_data["prediction_received"] = true
	test_data["predicted_action"] = action_type

# For performance test
func _on_performance_prediction(action_type, params):
	test_data["prediction_count"] += 1

# Called when Start button is pressed
func _on_start_button_pressed():
	start_tests()

# Called when Reset button is pressed
func _on_reset_button_pressed():
	output_label.text = "AI Test Suite Ready\nPress Start to begin tests"
	test_status_label.text = "Status: Ready"
	progress_bar.value = 0
