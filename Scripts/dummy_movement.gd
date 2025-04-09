extends Node


class_name DummyMovement

var enemy = CharacterBody2D
var animation_player = AnimationPlayer

func _init(anim: AnimationPlayer, enemy_instance: CharacterBody2D):
	animation_player = anim
	enemy = enemy_instance

func dummy_move(direction: int):
	enemy.velocity.x = direction
	animation_player.play("walk_forward")
