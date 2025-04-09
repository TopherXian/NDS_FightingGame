extends Node

class_name Damaged

var animation_player: AnimationPlayer
var player: CharacterBody2D
var hp_bar
var is_knocked_down = false

func _init(anim: AnimationPlayer, player_instance: CharacterBody2D):
	animation_player = anim
	player = player_instance
	hp_bar = player_instance.get_node("PlayerHP")

func take_damage(amount: int):

	hp_bar.value -= amount
	if hp_bar.value > 0:
		player.velocity.x = -10
		player.velocity.y = 0
		animation_player.play("hurt")
		
	else:
		is_knocked_down = true
		animation_player.play("knockdown")
