extends Node
class_name DummyAttack

var player : CharacterBody2D
var enemy : CharacterBody2D
var animation_player : AnimationPlayer


func _init(anim: AnimationPlayer, enemy_instance: CharacterBody2D, player_char: CharacterBody2D):
	animation_player = anim
	enemy = enemy_instance
	player = player_char

func get_basicAttacks():
	var distance = enemy.global_position.distance_to(player.global_position)
	if distance <= 83:
		animation_player.play("basic_punch")
	elif distance <= 100:
		animation_player.play("basic_kick")

func get_crouchAttacks():
	var distance = enemy.global_position.distance_to(player.global_position)
	if distance <= 83:
		animation_player.play("crouch_punch")

	elif distance <= 100:
		animation_player.play("crouch_kick")
