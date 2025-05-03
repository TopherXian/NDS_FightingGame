extends Node

class_name Attacks

var animation : AnimationPlayer
var player : CharacterBody2D
var is_attacking = false

func _init(anim : AnimationPlayer, p : CharacterBody2D):
	animation = anim
	player = p

func handle_punch():
	var is_walking_forward = player.velocity.x > 0 
	var crouch = Input.is_action_pressed("ui_down") 


	if Input.is_action_just_pressed("Punch") and player.is_on_floor() and not is_attacking:
		is_attacking = true
		player.velocity.x = 0
		player.velocity.y = 0
		
		if crouch:
			animation.play("crouch_punch")
		elif is_walking_forward:
			animation.play("heavy_punch")
		else:
			animation.play("basic_punch")
		
		_connect_animation_finished()

func handle_kick():
	var is_walking_forward = player.velocity.x > 0
	var crouch = Input.is_action_pressed("ui_down")


	if Input.is_action_just_pressed("Kick") and player.is_on_floor() and not is_attacking:
		is_attacking = true
		player.velocity.x = 0
		player.velocity.y = 0

		if crouch:
			animation.play("crouch_kick")
		elif is_walking_forward:
			animation.play("heavy_kick")
		else:
			animation.play("basic_kick")
		
		_connect_animation_finished()

func _connect_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
		animation.connect("animation_finished", Callable(self, "_on_attack_finished"))

func _on_attack_finished(_anim):
	is_attacking = false
	animation.stop()
