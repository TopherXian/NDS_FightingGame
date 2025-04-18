extends CharacterBody2D

var lower_hits := 0
var upper_hits := 0


@onready var animation = $"Animation"
@onready var player_hit_taken = get_parent().get_node("PlayerDetails")
@onready var timer = $PlayerTimer


var Starthp = 100
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_jumping = false

# Create instances of the Movements and Attacks classes
var movement_system : Movements
var attack_system : Attacks
var damaged_system : Damaged

# Reference to the enemy character
@onready var enemy = get_parent().get_node("Dummy_Ryu")
	
func update_facing_direction():
	if enemy.position.x > position.x:
		$Sprite.flip_h = false  # Face right
		$Hitbox_Container.scale.x = 1
		$Upper_Hurtbox.position.x = abs($Upper_Hurtbox.position.x)
		$Lower_Hurtbox.position.x = abs($Lower_Hurtbox.position.x)
	else:
		$Sprite.flip_h = true   # Face left
		$Hitbox_Container.scale.x = -1
		$Upper_Hurtbox.position.x = -abs($Upper_Hurtbox.position.x)
		$Lower_Hurtbox.position.x = -abs($Lower_Hurtbox.position.x)

func _ready():
	# Initialize the movement system and attack system with necessary components
	movement_system = Movements.new(animation, self)  # Pass 'self' as the player instance
	attack_system = Attacks.new(animation, self)      # Pass 'self' as the player instance
	damaged_system = Damaged.new(animation, self)
	$PlayerHP.value = Starthp
	timer.one_shot = false     # Keep repeating every 4 seconds
	# Connect signal (Godot 4 syntax)
	timer.timeout.connect(_on_timer_timeout)
	
func _physics_process(delta):
	update_facing_direction()
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

func _update_hit_text():
	player_hit_taken.text = "Lower Hits Taken: %d\nUpper Hits Taken: %d" % [lower_hits, upper_hits]
	
func _on_upper_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Dummy_Hitbox":
		damaged_system.take_damage(10)
		upper_hits += 1
		_update_hit_text()

func _on_lower_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Dummy_Hitbox":
		damaged_system.take_damage(10)
		lower_hits += 1
		_update_hit_text()
		
func _on_timer_timeout() -> void:
	upper_hits = 0
	lower_hits = 0
	_update_hit_text()
