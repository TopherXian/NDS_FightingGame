# HumanController.gd
extends Node
class_name HumanController

# --- References (Set by BaseFighter) ---
var fighter: CharacterBody2D # Reference to the BaseFighter node
var animation_player: AnimationPlayer
var opponent: CharacterBody2D

# --- Component Instances (From ryu.txt) ---
var movement_system : Movements
var attack_system : Attacks
# Note: Damage taking is handled by BaseFighter's signals now
# var damaged_system : Damaged # Not needed directly for control logic

var gravity: float # Get from fighter or ProjectSettings

func init_controller(fighter_node: CharacterBody2D, anim_player: AnimationPlayer, opp_node: CharacterBody2D):
	fighter = fighter_node
	animation_player = anim_player
	opponent = opp_node
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity") # Or fighter.gravity

	# --- Instantiate control components ---
	# Ensure the class scripts exist and paths are correct
	if FileAccess.file_exists("res://Scripts/Movements.gd"):
		var MovementsClass = load("res://Scripts/Movements.gd")
		if MovementsClass:
			movement_system = MovementsClass.new(animation_player, fighter)
			# Pass opponent reference if Movements needs it (original didn't seem to)
			# if movement_system.has_method("set_opponent"): movement_system.set_opponent(opponent)
		else: printerr("HumanController: Failed to load Movements.gd")
	else: printerr("HumanController: Movements.gd not found.")

	if FileAccess.file_exists("res://Scripts/Attacks.gd"):
		var AttacksClass = load("res://Scripts/Attacks.gd")
		if AttacksClass:
			attack_system = AttacksClass.new(animation_player, fighter)
			# Pass opponent reference if Attacks needs it (original didn't seem to)
			# if attack_system.has_method("set_opponent"): attack_system.set_opponent(opponent)

			# --- IMPORTANT: Connect attack system's finished signal ---
			# BaseFighter needs to know when an attack animation finishes
			# Option 1: Add a signal to Attacks.gd and emit it in _on_attack_finished
			# Option 2: Connect directly to AnimationPlayer's signal IF Attacks connects reliably
			# Let's assume Attacks.gd handles the connection and reset internally for now.
			# If BaseFighter needs notification, Attacks.gd needs to emit a signal.

		else: printerr("HumanController: Failed to load Attacks.gd")
	else: printerr("HumanController: Attacks.gd not found.")

	# Re-assign fighter's attack_system reference if BaseFighter needs it
	# This feels a bit messy, indicates maybe Attacks/Movements should be children nodes?
	if is_instance_valid(fighter) and fighter.has("attack_system"):
		fighter.attack_system = attack_system
	if is_instance_valid(fighter) and fighter.has("movement_system"):
		fighter.movement_system = movement_system

	print("Human Controller Initialized for: ", fighter.name)


func _physics_process(delta):
	if not is_instance_valid(fighter): return # Fighter might be destroyed

	# --- Handle Input ---
	if is_instance_valid(movement_system):
		movement_system.handle_movement() # Assumes handle_movement updates fighter.velocity
		movement_system.handle_jump()     # Assumes handle_jump updates fighter.velocity

	if is_instance_valid(attack_system):
		attack_system.handle_punch()
		attack_system.handle_kick()

	# Note: The original ryu.txt had gravity application and move_and_slide
	# directly in its _physics_process. BaseFighter now handles these.
	# This controller just needs to modify fighter.velocity based on input.
	# Ensure Movements/Attacks classes correctly modify fighter.velocity.
