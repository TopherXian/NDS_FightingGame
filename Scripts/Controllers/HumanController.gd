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
	if FileAccess.file_exists("res://Scripts/Movement.gd"):
		var MovementsClass = load("res://Scripts/Movement.gd")
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
			# (Your notes on signals remain relevant)

		else: printerr("HumanController: Failed to load Attacks.gd")
	else: printerr("HumanController: Attacks.gd not found.")

	# Re-assign fighter's attack_system reference if BaseFighter needs it
	# Use 'in' to check for property existence
	if is_instance_valid(fighter) and "attack_system" in fighter:
		fighter.attack_system = attack_system
		#print("Assigned attack_system to fighter.") # Optional: Add debug prints
	# else: # Optional: Add debug prints
		# if is_instance_valid(fighter): print("Fighter does not have 'attack_system' property.")
		# else: print("Fighter instance is invalid before attack_system check.")

	if is_instance_valid(fighter) and "movement_system" in fighter:
		fighter.movement_system = movement_system
		#print("Assigned movement_system to fighter.") # Optional: Add debug prints
	# else: # Optional: Add debug prints
		# if is_instance_valid(fighter): print("Fighter does not have 'movement_system' property.")
		# else: print("Fighter instance is invalid before movement_system check.")

	#print("Human Controller Initialized for: ", fighter.name)


func _physics_process(_delta):
	if not is_instance_valid(fighter): return # Fighter might be destroyed

	# --- Handle Input ---
	# Add checks here too, in case initialization failed
	if is_instance_valid(movement_system):
		movement_system.handle_movement() # Assumes handle_movement updates fighter.velocity
		movement_system.handle_jump()     # Assumes handle_jump updates fighter.velocity
	# else: print("Movement system invalid in _physics_process") # Optional debug

	if is_instance_valid(attack_system):
		attack_system.handle_punch()
		attack_system.handle_kick()

	if Engine.get_frames_drawn() % 240 == 0: # Every 4 seconds at 60 FPS
		reset_counters()

func reset_counters():
	if is_instance_valid(fighter):
		fighter.lower_hits_taken = 0
		fighter.upper_hits_taken = 0
		fighter.lower_attacks_landed = 0
		fighter.upper_attacks_landed = 0
		fighter.standing_defenses = 0
		fighter.crouching_defenses = 0
		fighter._update_stats_text()
