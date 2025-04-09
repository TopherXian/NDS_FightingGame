extends Node


class_name DummyAttack

var enemy = CharacterBody2D
var animation_player = AnimationPlayer
var player = CharacterBody2D


func _init(anim: AnimationPlayer, enemy_instance: CharacterBody2D, player_char: CharacterBody2D):
	animation_player = anim
	enemy = enemy_instance
	player = player_char

func get_attacks():
	if player.position.x <= 300:
		animation_player.play("basic_punch")
