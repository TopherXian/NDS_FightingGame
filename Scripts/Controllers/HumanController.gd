# HumanController.gd
extends Node
class_name HumanController

# References (Set by BaseFighter)
var fighter: CharacterBody2D # Reference to the BaseFighter node
var animation_player: AnimationPlayer
var opponent: CharacterBody2D

# Component Instances
var movement_system : Movements
var attack_system : Attacks

var gravity: float

func init_controller(fighter_node: CharacterBody2D, anim_player: AnimationPlayer, opp_node: CharacterBody2D):
	fighter = fighter_node
	animation_player = anim_player
	opponent = opp_node
	gravity = fighter.gravity

	# Instantiate control component
	if FileAccess.file_exists("res://Scripts/Movement.gd"):
		var MovementsClass = load("res://Scripts/Movement.gd")
		if MovementsClass:
			movement_system = MovementsClass.new(animation_player, fighter)
		else: print("HumanController: Failed to load Movements.gd")
	else: print("HumanController: Movements.gd not found.")

	if FileAccess.file_exists("res://Scripts/Attacks.gd"):
		var AttacksClass = load("res://Scripts/Attacks.gd")
		if AttacksClass:
			attack_system = AttacksClass.new(animation_player, fighter)
		else: print("HumanController: Failed to load Attacks.gd")
	else: print("HumanController: Attacks.gd not found.")

	# Re-assign fighter's attack_system reference if BaseFighter needs it
	if is_instance_valid(fighter) and "attack_system" in fighter:
		fighter.attack_system = attack_system
		
	# Re-assign fighter's movement_system reference if BaseFighter needs it
	if is_instance_valid(fighter) and "movement_system" in fighter:
		fighter.movement_system = movement_system


func _physics_process(_delta):
	if not is_instance_valid(fighter): return

	if is_instance_valid(movement_system):
		movement_system.handle_movement()
		movement_system.handle_jump()

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
