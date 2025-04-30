# DummyAttack.gd
extends Node
class_name DummyAttack

var fighter: CharacterBody2D  # The AI character itself
var opponent: CharacterBody2D # The player character
# We don't need animation_player directly here anymore

func _init(ai_fighter: CharacterBody2D, opponent_char: CharacterBody2D):
	fighter = ai_fighter
	opponent = opponent_char
	print("DummyAttack Initialized")

# Returns the name of the basic attack animation to play based on distance, or null
func get_basic_attack_action() -> StringName:
	if not is_instance_valid(fighter) or not is_instance_valid(opponent):
		return &"" # Return empty StringName if refs invalid

	var distance = fighter.global_position.distance_to(opponent.global_position)

	if distance <= 75:
		return &"basic_punch" # Use StringName for efficiency
	elif distance <= 90: # Check original logic: was 83 for punch, 100 for kick
		return &"basic_kick"
	else:
		return &"" # No basic attack in range

# Returns the name of the crouch attack animation to play based on distance, or null
func get_crouch_attack_action() -> StringName:
	if not is_instance_valid(fighter) or not is_instance_valid(opponent):
		return &""

	var distance = fighter.global_position.distance_to(opponent.global_position)

	# Example logic (adjust ranges as needed)
	if distance <= 83:
		return &"crouch_punch"
	elif distance <= 100:
		return &"crouch_kick"
	else:
		return &""
