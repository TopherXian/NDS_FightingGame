extends Node

# Define the Movements class to be referenced elsewhere
class_name Movements

var animation : AnimationPlayer
var player : CharacterBody2D
var opponent : CharacterBody2D  # 👈 Add this
var speed = 300

# Initialize with animation and player reference
func _init(anim : AnimationPlayer, p : CharacterBody2D, opp : CharacterBody2D = null):
	animation = anim
	player = p
	opponent = opp

# Optional setter for the opponent (if added after init)
func set_opponent(opp : CharacterBody2D):
	opponent = opp

func handle_movement():
	var right = Input.is_action_pressed("ui_right")
	var left = Input.is_action_pressed("ui_left")
	var crouch = Input.is_action_pressed("ui_down")

	# Face the opponent automatically
	if opponent:
		var diff = opponent.global_position.x - player.global_position.x
		player.scale.x = -1 if diff < 0 else 1  # Flip to face the opponent

	# If player is grounded and not attacking or jumping
	if player.is_on_floor() and not player.is_jumping and not player.attack_system.is_attacking:
		# Move to the right
		if right:
			player.velocity.x = speed
			animation.play("walk_forward")  # Play walk forward animation
		# Move to the left
		elif left:
			player.velocity.x = -speed
			animation.play("walk_backward")  # Play walk backward animation
		# Handle idle state when no movement
		else:
			player.velocity.x = 0
			animation.play("idle")  # Play idle animation when not moving
		
		# Handle crouch
		if crouch:  # If the crouch button is being pressed
			animation.play("crouch")  # Play the crouch animation
			player.velocity.x = 0
			player.velocity.y = 0  # Stop any movement while crouching
		else:
			# Stop crouch animation when not crouching
			if not right and not left: 
				animation.play("idle")  # Stop crouch animation and go back to idle


	# If player is in the air (not on the floor), allow free horizontal movement
	elif not player.is_on_floor() and not player.attack_system.is_attacking:
		# Apply horizontal movement while in the air based on input
		if right:
			player.velocity.x = speed
			if not animation.is_playing():
				animation.play("jump")  # Ensure jump animation plays
		elif left:
			player.velocity.x = -speed
			if not animation.is_playing():
				animation.play("jump")  # Ensure jump animation plays
		else:
			player.velocity.x = 0
			if not animation.is_playing():
				animation.play("jump")  # Ensure jump animation plays

# Handle jumping
func handle_jump():
	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		player.velocity.y = -450  # Apply jump velocity
		player.is_jumping = true
		animation.play("jump")  # Play jump animation
