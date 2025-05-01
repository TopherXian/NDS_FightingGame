class_name DummyDamaged
extends Node

var anim_player: AnimationPlayer
var hp_bar: ProgressBar
var enemy: CharacterBody2D

func init(anim: AnimationPlayer, enemy_instance: CharacterBody2D, hp: ProgressBar):
	hp_bar = hp
	anim_player = anim
	enemy = enemy_instance

func take_damage(damage_value: int) -> void:
	#hp_bar.value -= damage_value
	#enemy.velocity.x = -100
	#enemy.velocity.y = 0
	#anim_player.play("hurt")
	_connect_animation_physics()
	

func _connect_animation_physics():
	if not anim_player.is_connected("animation_finished", Callable(self, "on_hurt_finished")):
		anim_player.connect("animation_finished", Callable(self, "on_hurt_finished"))
		
func on_hurt_finished(animation):
	enemy.velocity.x = 0
	if hp_bar.value > 0:
		anim_player.play("idle")
	else:
		anim_player.play("knocked_down")
	
