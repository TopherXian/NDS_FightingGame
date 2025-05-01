# BaseFighter.gd
extends CharacterBody2D

# --- Shared Variables ---
var health: int = 200
@export var max_health: int = 200
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_jumping: bool = false # Track jump state if needed by multiple controllers

# --- Hit Tracking (Moved from ryu.txt & DS_ryu.txt) ---
var lower_hits_taken: int = 0
var upper_hits_taken: int = 0
var lower_attacks_landed: int = 0
var upper_attacks_landed: int = 0
var standing_defenses: int = 0
var crouching_defenses: int = 0
var upper_hurtbox: Area2D
var lower_hurtbox: Area2D

var attack_system = null # <-- ADD THIS LINE (or just 'var attack_system')
var movement_system = null # <-- You likely need this too based on HumanController

# --- Constants for Hurtbox Handling (Moved from ryu.txt & DS_ryu.txt) ---
# Adjust OPPONENT_HITBOX_NAME based on what the opponent's hitbox Area2D is named
var OPPONENT_HITBOX_NAME: StringName # Example, might be "Dummy_Hitbox" for Player 1, "Hitbox" for Player 2
const STANDING_DEFENSE_ANIM: StringName = &"standing_defense"
const CROUCHING_DEFENSE_ANIM: StringName = &"crouching_defense"

@export var defense_damage_modifier: float = 0.7 # Takes 70% damage when defending
@export var normal_damage_taken: int = 10    # Default damage taken if hit directly

# --- Node References (Adjust paths as needed!) ---
@onready var animation_player: AnimationPlayer # Or $Dummy_Animation if that's the name
@onready var sprite: Sprite2D
@onready var hp_bar: ProgressBar
@onready var hitbox_container: Node2D # Container for player's own hitbox(es)
@onready var opponent: CharacterBody2D = null # Will be set in _ready or level script

func _get_animation() -> AnimationPlayer:
	if has_node("Animation"):
		return get_node("Animation")
	else:
		return $Dummy_Animation

func _get_sprite() -> Sprite2D:
	if has_node("Sprite"):
		return get_node("Sprite")
	else:
		return get_node("AnimatedSprite2D")
		
func _get_progress_bar() -> ProgressBar:
	if has_node("PlayerHP"):
		return get_node("PlayerHP")
	else:
		return get_node("DummyHP")

func _get_hitbox():
	if has_node("Hitbox_Container"):
		return get_node("Hitbox_Container")
	else:
		return get_node("Dummy_Hitbox")
		
func _get_upper_hurtbox():
	if has_node("Upper_Hurtbox"):
		return get_node("Upper_Hurtbox")
	else:
		return get_node("Dummy_UpperHurtbox")
		
func _get_lower_hurtbox():
	if has_node("Lower_Hurtbox"):
		return get_node("Lower_Hurtbox")
	else:
		return get_node("Dummy_LowerHurtbox")

func _get_opponent_hitbox():
	if character_id == "Player2":
		return &"Hitbox"
	else:
		return &"Dummy_Hitbox"

# UI Labels for Stats (Optional, assign in Inspector or get from parent)
@onready var stats_label: Label = null # e.g., get_parent().get_node("PlayerDetails") - Assign appropriately

# --- Controller ---
var active_controller: Node = null
var control_type: String
# --- Character Identifier (Set in Inspector!) ---
@export var character_id: String = "Player1" # "Player1" for Ryu, "Player2" for Dummy

# --- Component Instances ---
# Note: Damaged system might be simpler if its logic is partially merged here
var damaged_system: Damaged # Instantiated based on controller type? Or always standard? Let's assume standard for now.

func _ready():
	
	upper_hurtbox = _get_upper_hurtbox() # Adjust node name if different
	lower_hurtbox = _get_lower_hurtbox() # Adjust node name if different
	animation_player = _get_animation()
	sprite = _get_sprite()
	hp_bar = _get_progress_bar()
	hitbox_container = _get_hitbox()
	OPPONENT_HITBOX_NAME = _get_opponent_hitbox()
	# Find Opponent (Assuming parent node has both player and dummy)
	# This is a common pattern, adjust if your level structure is different
	for child in get_parent().get_children():
		if child is CharacterBody2D and child != self:
			opponent = child
			break
	if opponent == null:
		print("ERROR: ", character_id, " could not find opponent node.")
		return # Cannot proceed without opponent reference

	# Initialize HP Bar
	hp_bar.max_value = max_health
	hp_bar.value = health
	if FileAccess.file_exists("res://Scripts/Damaged.gd"): 
		var DamagedClass = load("res://Scripts/Damaged.gd")
		if DamagedClass:
			damaged_system = DamagedClass.new(animation_player, self, hp_bar) # Pass needed refs
		else:
			print("ERROR: Could not load Damaged.gd")
	else:
		print("WARNING: Damaged.gd not found at res://Scripts/Damaged.gd")

	# Determine Control Type and Setup Controller
	if character_id == "Player1":
		control_type = GameSettings.player1_control_type
	elif character_id == "Player2":
		control_type = GameSettings.player2_control_type
	else:
		print("ERROR: Unknown character_id: ", character_id)
		control_type = "Human" # Fallback

	#print(character_id, " activating controller: ", control_type)
	setup_controller(control_type)

	# Connect Hurtbox Signals (Connect these in the Godot Editor Inspector too!)

	if upper_hurtbox and upper_hurtbox.has_signal("area_entered"):
		if not upper_hurtbox.is_connected("area_entered", Callable(self, "_on_upper_hurtbox_area_entered")):
			upper_hurtbox.connect("area_entered", Callable(self, "_on_upper_hurtbox_area_entered"))
	else:
		print("Upper Hurtbox node or signal not found!")

	if lower_hurtbox and lower_hurtbox.has_signal("area_entered"):
		if not lower_hurtbox.is_connected("area_entered", Callable(self, "_on_lower_hurtbox_area_entered")):
			lower_hurtbox.connect("area_entered", Callable(self, "_on_lower_hurtbox_area_entered"))
	else:
		print("Lower Hurtbox node or signal not found!")

	# Connect own Hitbox Signals (To track when *this* character hits the opponent)
	# Find the actual hitbox Area2D node, might be inside hitbox_container
	var own_hitbox
	if hitbox_container.has_node("Hitbox"):
		own_hitbox = hitbox_container.get_node("Hitbox")
	else:
		own_hitbox = hitbox_container
	if own_hitbox and own_hitbox.has_signal("area_entered"):
		if not own_hitbox.is_connected("area_entered", Callable(self, "_on_own_hitbox_area_entered")):
			own_hitbox.connect("area_entered", Callable(self, "_on_own_hitbox_area_entered")) # Connect to a NEW function
	else:
		print("Own Hitbox node or signal not found!")


func setup_controller(type: String):
	if active_controller:
		active_controller.queue_free()
		active_controller = null

	match type:
		"Human":
			if FileAccess.file_exists("res://Scripts/Controllers/HumanController.gd"):
				var HumanControllerClass = load("res://Scripts/Controllers/HumanController.gd")
				if HumanControllerClass:
					active_controller = HumanControllerClass.new()
					add_child(active_controller) # Add as child
					active_controller.init_controller(self, animation_player, opponent) # Pass references
				else: print("Failed to load HumanController.gd")
			else: print("HumanController.gd not found.")

		"Dynamic Scripting":
			if FileAccess.file_exists("res://Scripts/Controllers/DynamicScriptingController.gd"):
				var DSControllerClass = load("res://Scripts/Controllers/DynamicScriptingController.gd")
				if DSControllerClass:
					active_controller = DSControllerClass.new()
					add_child(active_controller) # Add as child
					active_controller.init_controller(self, animation_player, opponent, hp_bar) # Pass references
				else: print("Failed to load DynamicScriptingController.gd")
			else: print("DynamicScriptingController.gd not found.")

		"Decision Tree": # <-- Add this case
			var dt_script_path = "res://Scripts/AI/DecisionTreeController.gd"
			if FileAccess.file_exists(dt_script_path):
				var DTControllerClass = load(dt_script_path)
				if DTControllerClass:
					active_controller = DTControllerClass.new()
					add_child(active_controller) # Add as child node
					# Call the init function, passing necessary references
					active_controller.init_controller(self, animation_player, opponent)
				else: print("Failed to load DecisionTreeController.gd")
			else: print("DecisionTreeController.gd not found at ", dt_script_path)

		"Neuro-Dynamic":
			if FileAccess.file_exists("res://Scripts/AI/NeuroDynamicController.gd"): # Assuming path
				var NDControllerClass = load("res://Scripts/AI/NeuroDynamicController.gd")
				if NDControllerClass:
					active_controller = NDControllerClass.new(self, animation_player, opponent) # Use constructor if it accepts args
					add_child(active_controller)
				else: print("Failed to load NeuroDynamicController.gd")
			else: print("NeuroDynamicController.gd not found.")

		_:
			print("Error: Unknown control type: ", type)
			# Fallback to Human?
			# setup_controller("Human")


func _physics_process(delta):
	# Apply gravity if not on floor
	if not is_on_floor():
		velocity.y += gravity * delta

	# --- Delegate Control Logic ---
	if is_instance_valid(active_controller) and active_controller.has_method("_physics_process"):
		active_controller._physics_process(delta) # Let the controller handle movement/actions

	# --- Shared Logic ---
	update_facing_direction()
	move_and_slide()

	# Optional: Reset jump flag if grounded (depends on controller needs)
	if is_on_floor():
		is_jumping = false
	
	_update_executed_rule()



func update_facing_direction():
	if not is_instance_valid(opponent): return # Opponent might be defeated/removed
	var direction_to_opponent = opponent.global_position.x - global_position.x
	if abs(direction_to_opponent) > 1.0: # Add a small tolerance
		if direction_to_opponent > 0:
			sprite.flip_h = false  # Face right
			if character_id == "Player1":
				hitbox_container.scale.x = 1
				hitbox_container.position.x = abs(hitbox_container.position.x)
			else:
				hitbox_container.position.x = abs(hitbox_container.position.x)
			# Adjust hurtbox positions if they are offset (use absolute values)
			#upper_hurtbox.position.x = abs(upper_hurtbox.position.x)
			#lower_hurtbox.position.x = abs(lower_hurtbox.position.x)
		else:
			sprite.flip_h = true   # Face left
			if character_id == "Player1":
				hitbox_container.scale.x = -1
				hitbox_container.position.x = -abs(hitbox_container.position.x)
			else:
				hitbox_container.position.x = -abs(hitbox_container.position.x)
			# Adjust hurtbox positions if they are offset (use negative absolute values)
			#upper_hurtbox.position.x = -abs(upper_hurtbox.position.x)
			#lower_hurtbox.position.x = -abs(lower_hurtbox.position.x)


# --- Damage Handling ---
func apply_damage(damage_amount: int, is_upper_hit: bool):
	if animation_player.current_animation == "hurt":
		return
	if health <= 0: return # Already defeated
	
	var final_damage = damage_amount
	var defended = false	

	# Check defense state
	var current_anim = animation_player.current_animation
	if current_anim == STANDING_DEFENSE_ANIM:
		final_damage = int(damage_amount * defense_damage_modifier)
		standing_defenses += 1
		defended = true
	elif current_anim == CROUCHING_DEFENSE_ANIM:
		final_damage = int(damage_amount * defense_damage_modifier)
		crouching_defenses += 1
		defended = true

	# Apply damage
	health -= final_damage
	hp_bar.value = health # Update HP bar directly here

	# Single source for damage reactions
	if is_instance_valid(damaged_system):
		damaged_system.take_damage(final_damage, sprite)
	
	# Notify controller AFTER damage is applied
	if active_controller and active_controller.has_method("notify_damage_taken"):
		active_controller.notify_damage_taken(damage_amount, is_upper_hit, defended)
		
	# Update hit counters
	if is_upper_hit:
		upper_hits_taken += 1
	else:
		lower_hits_taken += 1

	# Trigger damaged effects (animation, knockback) - Use Damaged system if it exists
	if is_instance_valid(damaged_system) and damaged_system.has_method("take_damage"):
		damaged_system.take_damage(final_damage, sprite)
	else: # Basic fallback if no damaged system
		animation_player.play("hurt")
		# Basic knockback
		var knockback_dir = 1 if sprite.flip_h else -1 # Knock away from facing dir
		velocity.x = knockback_dir * 30 # Small knockback

	# Check for defeat
	if health <= 0:
		die()
		GameSettings.round_active = false
		get_tree().call_group("game_controller", "on_round_end")
	
	_update_stats_text()

func die():
	if animation_player.current_animation != "knocked_down":
		animation_player.play("knocked_down")


# --- Signal Callbacks ---
func _on_upper_hurtbox_area_entered(area: Area2D) -> void:
	# Check if the area is the opponent's hitbox and if it's currently active/damaging
	# This requires the hitbox Area2D to have a script or property indicating it's active
	# For now, assume any area with the correct name deals damage
	if area.name == OPPONENT_HITBOX_NAME: # Make sure opponent hitbox has this name!
		# Determine damage based on opponent's attack (needs more info from 'area' or opponent state)
		var damage = normal_damage_taken # Placeholder
		apply_damage(damage, true) # True because it's the upper hurtbox


func _on_lower_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == OPPONENT_HITBOX_NAME:
		var damage = normal_damage_taken # Placeholder
		apply_damage(damage, false) # False because it's the lower hurtbox

func _on_own_hitbox_area_entered(area: Area2D) -> void:
	# This is called when THIS character's hitbox overlaps with something.
	# Check if it's the opponent's hurtbox.
	if area.get_parent() == opponent: # Check if the area belongs to the opponent
		if "Hurtbox" in area.name: # Check if it's one of the opponent's hurtboxes
			# Increment landed attack counters based on which hurtbox was hit
			if "Upper" in area.name:
				upper_attacks_landed += 1
			elif "Lower" in area.name:
				lower_attacks_landed += 1
			_update_stats_text()
			# Note: The opponent's hurtbox signal handler (`_on_upper/lower_hurtbox_area_entered` on *their* script)
			# is responsible for making the opponent take damage. This function just records the hit.


func _update_stats_text():
	# Determine correct label name based on character
	var parameters_label = "PlayerDetails" if character_id == "Player1" else "OpponentDetails"
	
	if stats_label == null:
		# Try to find the correct label node
		var label_node = get_parent().get_node(parameters_label)
		if label_node is Label:
			stats_label = label_node
		else:
			print("Stats label '%s' not found for "%parameters_label, character_id)
			return
	
	# Update text with current values
	stats_label.text = "%s\nLower Hits Taken: %d\nUpper Hits Taken: %d\nLower Attacks Hit: %d\nUpper Attacks Hit: %d\nStand Def: %d\nCrouch Def: %d" % [
		character_id, lower_hits_taken, upper_hits_taken, 
		lower_attacks_landed, upper_attacks_landed,
		standing_defenses, crouching_defenses
	]

func _update_executed_rule():
	var label_name = "P1ExecutedR" if character_id == "Player1" else "P2ExecutedR"
	var label_node = get_parent().get_node(label_name)
	
	if not label_node:
		print("Executed Rule label '%s' not found" % label_name)
		return
	
	var rule_text = "No rule"
	if is_instance_valid(active_controller):
		# Try general controller access first
		if active_controller.has_method("get_executed_rule"):
			rule_text = active_controller.get_executed_rule()
		elif "current_rule" in active_controller:
			rule_text = active_controller.current_rule
		else:
			# Controller-specific handling
			match control_type:
				"Dynamic Scripting":
					if active_controller.has_method("get_executed_rule"):
						rule_text = active_controller.get_executed_rule()
						print(rule_text)
				"Decision Tree":
					if "last_executed_decision" in active_controller:
						rule_text = active_controller.last_executed_decision
				"Neuro-Dynamic":
					if "current_action" in active_controller:
						rule_text = active_controller.current_action
				"Human":
					rule_text = "Manual input"
	
	# Limit text length for display
	if rule_text.length() > 20:
		rule_text = rule_text.substr(0, 17) + "..."
	
	label_node.text = "Rule used: %s" % rule_text
	#print("RULE TEXT:%s" % rule_text )
	
func get_opponent() -> CharacterBody2D:
	return opponent

func get_health() -> int:
	return health

# Add any other shared functions controllers might call
