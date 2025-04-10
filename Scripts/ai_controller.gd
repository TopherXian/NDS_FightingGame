extends Node

# This script manages the AI components for a character
# Serves as the connection point between different AI systems

# AI Components
var data_collector = null
var ai_controller = null
var difficulty_adjuster = null

# Character references
var player_node = null
var enemy_node = null  # This is the node this controller is attached to

# Signals from AI components
signal ai_action(action_type, params)
signal difficulty_changed(value, reason)
signal data_saved()

func _ready():
	# Initialize AI components
	_initialize_components()
	
	# Find player reference
	_find_player()
	
	# Store reference to the character this AI controls
	enemy_node = get_parent()
	
	# Connect internal signals
	_connect_signals()
	
	print("AI Controller initialized")

# Initialize all AI components
func _initialize_components():
	# Create data collector
	data_collector = load("res://Scripts/training_data_collector.gd").new()
	add_child(data_collector)
	
	# Create AI controller
	ai_controller = load("res://Scripts/dummy_ryu_ai.gd").new()
	add_child(ai_controller)
	
	# Create difficulty adjuster
	difficulty_adjuster = load("res://Scripts/difficulty_adjuster.gd").new()
	add_child(difficulty_adjuster)
	
	# Set up references between components
	if ai_controller:
		ai_controller.data_collector = data_collector
	
	if difficulty_adjuster:
		difficulty_adjuster.setup(data_collector, ai_controller)

# Find the player character
func _find_player():
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player_node = players[0]
		
		# Start data collection
		if data_collector and player_node:
			data_collector.start_collection(player_node, enemy_node)
			
		# Set up player reference in AI controller
		if ai_controller:
			ai_controller.player_node = player_node
			ai_controller.enemy_node = enemy_node

# Connect signals between components
func _connect_signals():
	# Connect AI controller signals
	if ai_controller:
		if not ai_controller.is_connected("action_predicted", Callable(self, "_on_ai_action_predicted")):
			ai_controller.connect("action_predicted", Callable(self, "_on_ai_action_predicted"))
			
		if not ai_controller.is_connected("action_executed", Callable(self, "_on_ai_action_executed")):
			ai_controller.connect("action_executed", Callable(self, "_on_ai_action_executed"))
	
	# Connect difficulty adjuster signals
	if difficulty_adjuster:
		if not difficulty_adjuster.is_connected("difficulty_changed", Callable(self, "_on_difficulty_changed")):
			difficulty_adjuster.connect("difficulty_changed", Callable(self, "_on_difficulty_changed"))
	
	# Connect data collector signals
	if data_collector:
		if not data_collector.is_connected("data_saved", Callable(self, "_on_data_saved")):
			data_collector.connect("data_saved", Callable(self, "_on_data_saved"))
	
	# Connect character signals to tracking functions
	if enemy_node:
		if enemy_node.has_signal("attack_executed") and not enemy_node.is_connected("attack_executed", Callable(self, "_on_character_attack_executed")):
			enemy_node.connect("attack_executed", Callable(self, "_on_character_attack_executed"))
			
	# Connect animation finished signal from character
	if enemy_node and enemy_node.has_node("Animation"):
		var anim = enemy_node.get_node("Animation")
		if not anim.is_connected("animation_finished", Callable(enemy_node, "_on_Animation_animation_finished")):
			anim.connect("animation_finished", Callable(enemy_node, "_on_Animation_animation_finished"))

# Process AI on each frame
func _process(delta):
	# Update AI controller if available
	if ai_controller:
		# ai_controller.update(delta) - Remove this line as dummy_ryu_ai doesn't have this method
		pass
		
	# Update difficulty adjustment if enough time has passed
	if difficulty_adjuster:
		difficulty_adjuster.update(delta)

# Handle AI prediction
func _on_ai_action_predicted(action_type, params):
	# Forward the AI action to the parent character
	emit_signal("ai_action", action_type, params)
	
	# Forward to parent character if it has an appropriate method
	if enemy_node and enemy_node.has_method("_on_ai_action_predicted"):
		enemy_node._on_ai_action_predicted(action_type, params)

# Track action execution results
func _on_ai_action_executed(action_type, result, position, timestamp):
	# Record this in the data collector
	if data_collector and data_collector.is_collecting:
		# The data collector already has a handler for this
		pass

# Track when difficulty changes
func _on_difficulty_changed(new_difficulty, reason):
	emit_signal("difficulty_changed", new_difficulty, reason)

# Track when data is saved
func _on_data_saved():
	emit_signal("data_saved")

# Track character attacks for AI learning
func _on_character_attack_executed(attack_type, position, is_hit, damage):
	if ai_controller:
		# Store attack execution data in AI controller
		# This can be used for reinforcement learning
		pass
