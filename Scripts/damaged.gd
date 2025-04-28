extends Node

class_name Damaged

var animation_player: AnimationPlayer
var player: CharacterBody2D
var hp_bar
var is_knocked_down = false

func _init(anim: AnimationPlayer, player_instance: CharacterBody2D, hp):
	animation_player = anim
	player = player_instance
	hp_bar = hp

func take_damage(amount: int):

	hp_bar.value -= amount
	if hp_bar.value > 0:
		player.velocity.x = -10
		player.velocity.y = 0
		animation_player.play("hurt")
		
	else:
		is_knocked_down = true
		animation_player.play("knocked_down")
