extends Node

class_name DummyMovement

var player : CharacterBody2D
var enemy : CharacterBody2D
var animation_player : AnimationPlayer
var movement_speed = 150  # Base movement speed

func _init(anim: AnimationPlayer, enemy_instance: CharacterBody2D, player_char: CharacterBody2D):
	animation_player = anim
	enemy = enemy_instance
	player = player_char

func dummy_move(direction: int):
	var distance = enemy.global_position.distance_to(player.global_position)
	
	# Update velocity based on direction and speed
	enemy.velocity.x = direction * movement_speed
	
	# Play appropriate animation based on movement direction
	if direction != 0:
		if (direction > 0 and enemy.global_position.x < player.global_position.x) or \
		   (direction < 0 and enemy.global_position.x > player.global_position.x):
			animation_player.play("walk_forward")
		else:
			animation_player.play("walk_backward")
	else:
		animation_player.play("idle")
	
	# Distance management
	if distance < 50:  # Too close
		# Slow down when very close to prevent overlap
		enemy.velocity.x *= 0.5
	elif distance > 300:  # Too far
		# Speed up when far to catch up
		enemy.velocity.x *= 1.5

# Add new function for jumping
func dummy_jump(force: float = -400.0):
	if enemy.is_on_floor():
		enemy.velocity.y = force
		animation_player.play("jump")

# Add function for attack animations
func play_attack_animation(attack_type: String):
	match attack_type:
		"basic_punch":
			animation_player.play("basic_punch")
		"heavy_punch":
			animation_player.play("heavy_punch")
		"basic_kick":
			animation_player.play("basic_kick")
		"heavy_kick":
			animation_player.play("heavy_kick")
		_:
			animation_player.play("idle")
