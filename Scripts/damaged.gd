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

func take_damage(amount: int, sprite):
	hp_bar.value -= amount
	if hp_bar.value > 0:
		# Handle ALL visual/physical reactions here
		player.velocity.y = 0
		animation_player.play("hurt")
		var knockback_dir = 1 if sprite.flip_h else -1
		player.velocity.x = knockback_dir * 30
	else:
		animation_player.play("knocked_down")
	_connect_animation_physics()

func _connect_animation_physics():
	if not animation_player.is_connected("animation_finished", Callable(self, "on_hurt_finished")):
		animation_player.connect("animation_finished", Callable(self, "on_hurt_finished"), CONNECT_ONE_SHOT)

func on_hurt_finished(anim_name: String):
	if anim_name == "hurt":
		animation_player.play("idle")
		
		if player.has_method("reset_ai_state"):
			player.reset_ai_state()
