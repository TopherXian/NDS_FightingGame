extends Node

class_name Movements

var animation : AnimationPlayer
var player : CharacterBody2D
var speed = 300

func _init(anim : AnimationPlayer, p : CharacterBody2D):
	animation = anim
	player = p



func handle_movement():
	var right = Input.is_action_pressed("ui_right")
	var left = Input.is_action_pressed("ui_left")
	var crouch = Input.is_action_pressed("ui_down")

	# Check if attack_system is valid before using it
	var is_currently_attacking = false
	if "attack_system" in player and player.attack_system != null:
		if "is_attacking" in player.attack_system:
			is_currently_attacking = player.attack_system.is_attacking


	# If player is grounded and not attacking or jumping
	if player.is_on_floor() and not player.is_jumping and not is_currently_attacking:
		# Move to the right
		if right:
			player.velocity.x = speed
			animation.play("walk_forward")
		# Move to the left
		elif left:
			player.velocity.x = -speed
			animation.play("walk_backward")
		# Handle idle state when no movement
		else:
			player.velocity.x = 0
			animation.play("idle")

		# Handle crouch
		if crouch:
			animation.play("crouch")
			player.velocity.x = 0


	# If player is in the air (not on the floor), allow free horizontal movement
	# Check attack state here too
	elif not player.is_on_floor() and not is_currently_attacking:
		# Apply horizontal movement while in the air based on input
		if right:
			player.velocity.x = speed
		elif left:
			player.velocity.x = -speed
		else:
			player.velocity.x = 0

		# Only play jump animation if needed
		if not animation.is_playing() or animation.current_animation != "jump":
			 # Check if the jump animation exists before playing
			if animation.has_animation("jump"):
				animation.play("jump")


func handle_jump():
	var can_jump = true
	if "attack_system" in player and player.attack_system != null:
		if "is_attacking" in player.attack_system:
			if player.attack_system.is_attacking:
				can_jump = false # Prevent jumping while attacking

	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor() and can_jump:
		player.velocity.y = -450
		player.is_jumping = true
		if animation.has_animation("jump"):
			animation.play("jump")
