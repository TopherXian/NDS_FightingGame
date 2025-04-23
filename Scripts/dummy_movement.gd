extends Node

class_name DummyMovement

var player : CharacterBody2D
var enemy = CharacterBody2D
var animation_player = AnimationPlayer

func _init(anim: AnimationPlayer, enemy_instance: CharacterBody2D, player_char: CharacterBody2D):
	animation_player = anim
	enemy = enemy_instance
	player = player_char

func dummy_move(direction: int):
	var distance = enemy.global_position.distance_to(player.global_position)
	if distance >= 100:
		enemy.velocity.x = direction
		animation_player.play("walk_forward")
