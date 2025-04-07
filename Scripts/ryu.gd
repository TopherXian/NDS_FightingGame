extends CharacterBody2D

@onready var animation = $"Animation"
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_jumping = false

# Create instances of the Movements and Attacks classes
var movement_system : Movements
var attack_system : Attacks

func _ready():
	# Initialize the movement system and attack system with necessary components
	movement_system = Movements.new(animation, self)  # Pass 'self' as the player instance
	attack_system = Attacks.new(animation, self)      # Pass 'self' as the player instance

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		if not is_jumping:
			is_jumping = true
	else:
		velocity.y = 0
		if is_jumping:
			is_jumping = false
			animation.play("idle")

	# Use the movement system to handle player movement and jumping
	movement_system.handle_movement()  # Handle movement (left, right, idle)
	movement_system.handle_jump()      # Handle jump
	
	# Use the attack system to handle punch and kick
	attack_system.handle_punch()  # Check for punch input
	attack_system.handle_kick()   # Check for kick input
	
	move_and_slide()
