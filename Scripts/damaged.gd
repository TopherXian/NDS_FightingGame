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

func take_damage(amount: int, opponent_sprite):

	hp_bar.value -= amount
	if hp_bar.value > 0:
		player.velocity.y = 0
		animation_player.play("hurt")
		# Basic knockback
		var knockback_dir = 1 if opponent_sprite.flip_h else -1 # Knock away from facing dir
		player.velocity.x = knockback_dir * 30 # Small knockback
		
	else:
		is_knocked_down = true
		animation_player.play("knocked_down")
	_connect_animation_physics()

func _connect_animation_physics():
	if not animation_player.is_connected("animation_finished", Callable(self, "on_hurt_finished")):
		animation_player.connect("animation_finished", Callable(self, "on_hurt_finished"))
		
func on_hurt_finished(_animation):
	player.velocity.x = 0
	if hp_bar.value > 0:
		animation_player.play("idle")
	else:
		animation_player.play("knocked_down")
