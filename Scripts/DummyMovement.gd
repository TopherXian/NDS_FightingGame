# DummyMovement.gd
extends Node
class_name DummyMovement

var fighter: CharacterBody2D  # The AI character itself (BaseFighter instance)
var opponent: CharacterBody2D # The player character (BaseFighter instance)
var animation_player: AnimationPlayer

# Speed should likely come from the fighter itself for consistency
var speed: float = 80.0

func _init(anim_player: AnimationPlayer, ai_fighter: CharacterBody2D, opponent_char: CharacterBody2D):
	animation_player = anim_player
	fighter = ai_fighter
	opponent = opponent_char
	# Get speed from the fighter if possible
	if fighter and fighter.has("speed"): # Check if fighter has a speed property
		speed = fighter.speed


# Decide movement direction based on opponent position and distance
func decide_movement():
	if not is_instance_valid(fighter) or not is_instance_valid(opponent):
		return

	var distance = fighter.global_position.distance_to(opponent.global_position)
	var direction_to_opponent = opponent.global_position.x - fighter.global_position.x

	# Only move if sufficiently far away
	if distance >= 70:
		if direction_to_opponent > 0:
			# Opponent is to the right, move right
			fighter.velocity.x = speed
			if fighter.is_on_floor() and (not animation_player.is_playing() or animation_player.current_animation != "walk_forward"):
				animation_player.play("walk_forward")
		elif direction_to_opponent < 0:
			# Opponent is to the left, move left
			fighter.velocity.x = -speed
			if fighter.is_on_floor() and (not animation_player.is_playing() or animation_player.current_animation != "walk_forward"):
				animation_player.play("walk_forward")
		else:
			fighter.velocity.x = 0
	else:
		# Too close, stop moving horizontally (unless attacking/defending)
		fighter.velocity.x = 0
