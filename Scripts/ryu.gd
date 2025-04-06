extends CharacterBody2D

const speed = 300
const jump_velocity = -400.0

@onready var animation = $"Animation"
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_jumping = false  # To track whether the player is currently jumping

func _physics_process(delta):
	if not is_on_floor():
		# Apply gravity if the player is not on the floor
		velocity.y += gravity * delta
		if not is_jumping:  # Start the jump animation when we first jump
			is_jumping = true
			#animation.play("jump")
	else:
		# Stop gravity effect when on the floor
		velocity.y = 0
		if is_jumping:  # Stop jump animation and play idle animation when landing
			is_jumping = false
			animation.play("idle")
	
	# Handle movement input
	var right = Input.is_action_pressed("ui_right")
	var left = Input.is_action_pressed("ui_left")

	if right:
		velocity.x = speed
		if not is_jumping:  # Only play walk animation if not jumping
			animation.play("walk_forward")
	elif left:
		velocity.x = -speed
		if not is_jumping:  # Only play walk animation if not jumping
			animation.play("walk_backward")
	else:
		velocity.x = 0
		if not is_jumping:  # Only play idle if not jumping
			animation.play("idle")

	# Handle jump input
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity  # Apply jump velocity
		is_jumping = true  # Set jumping state to true
		animation.play("jump")  # Start the jump animation
	
	# Move the character
	move_and_slide()
