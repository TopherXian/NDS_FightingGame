extends Node

# Define the Movements class to be referenced elsewhere
class_name Movements

var animation : AnimationPlayer
var player : CharacterBody2D
var speed = 300

# Initialize with animation and player reference
func _init(anim : AnimationPlayer, p : CharacterBody2D):
	animation = anim
	player = p

# Optional setter for the opponent (if added after init)

func handle_movement():
	var right = Input.is_action_pressed("ui_right")
	var left = Input.is_action_pressed("ui_left")
	var crouch = Input.is_action_pressed("ui_down")

	# --- Check if attack_system is valid before using it ---
	# Default to 'false' if the system isn't ready yet
	var is_currently_attacking = false
	if "attack_system" in player and player.attack_system != null:
		 # You might need to check if 'is_attacking' exists too, depending on Attacks.gd
		if "is_attacking" in player.attack_system:
			is_currently_attacking = player.attack_system.is_attacking
		 # else: print("Warning: attack_system exists but has no 'is_attacking' property.")
	# else: print("Warning: player.attack_system is not valid in handle_movement.")


	# If player is grounded and not attacking or jumping
	if player.is_on_floor() and not player.is_jumping and not is_currently_attacking: # Use the checked variable
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

		# Handle crouch (Needs to be inside the grounded block, potentially adjusted logic)
		if crouch:
			animation.play("crouch")
			player.velocity.x = 0
			# player.velocity.y = 0 # Probably not needed if applying gravity elsewhere
		# This 'else' for stopping crouch might conflict with idle above.
		# Consider simplifying crouch/idle logic. Example:
		# elif not right and not left: # If not moving and not crouching (crouch handled above)
		#     animation.play("idle")


	# If player is in the air (not on the floor), allow free horizontal movement
	# Check attack state here too
	elif not player.is_on_floor() and not is_currently_attacking: # Use the checked variable
		# Apply horizontal movement while in the air based on input
		if right:
			player.velocity.x = speed
		elif left:
			player.velocity.x = -speed
		else:
			player.velocity.x = 0

		# Only play jump animation if needed (maybe handled better in jump/landing logic)
		if not animation.is_playing() or animation.current_animation != "jump":
			 # Check if the jump animation exists before playing
			if animation.has_animation("jump"):
				animation.play("jump")


func handle_jump():
	# Add check for attack system here too? Often can't jump while attacking.
	var can_jump = true
	if "attack_system" in player and player.attack_system != null:
		if "is_attacking" in player.attack_system:
			if player.attack_system.is_attacking:
				can_jump = false # Prevent jumping while attacking

	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor() and can_jump:
		player.velocity.y = -450
		player.is_jumping = true # Make sure BaseFighter resets this on landing
		if animation.has_animation("jump"): # Check if animation exists
			animation.play("jump")
