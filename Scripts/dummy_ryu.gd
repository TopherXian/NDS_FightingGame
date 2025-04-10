extends "res://Scripts/ryu.gd"

# AI-specific variables
var ai_controlled = true
var current_ai_action = "idle"
var action_confidence = 0.0
var ai_controller = null

# Attack signals
signal attack_executed(attack_type, position, is_hit, damage)
signal attack_hit(attack_type, position, target)

func _init():
	# Initialize hitbox areas
	var punch_hitbox = Area2D.new()
	punch_hitbox.name = "PunchHitbox"
	add_child(punch_hitbox)

	var kick_hitbox = Area2D.new()
	kick_hitbox.name = "KickHitbox"
	add_child(kick_hitbox)

	# Set up collision shapes
	for hitbox in [punch_hitbox, kick_hitbox]:
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(60, 40)  # Adjust size as needed
		shape.shape = rect
		hitbox.add_child(shape)
		hitbox.monitoring = false  # Start disabled
		# Connect the area entered signal
		hitbox.connect("area_entered", Callable(self, "_on_hitbox_area_entered"))

func _ready():
	super._ready()
	# Get AI controller if it exists
	ai_controller = $AIController
	
	if ai_controller:
		# Connect to AI action signal
		ai_controller.connect("ai_action", Callable(self, "_on_ai_action_predicted"))

# Handle AI action predictions
func _on_ai_action_predicted(action_type, params):
	current_ai_action = action_type
	action_confidence = params.get("confidence", 0.0)
	
	# Execute the action based on type
	match action_type:
		"basic_punch", "heavy_punch":
			_execute_ai_punch(action_type)
		"basic_kick", "heavy_kick":
			_execute_ai_kick(action_type)
		"walk_forward":
			_execute_ai_movement(1)
		"walk_backward":
			_execute_ai_movement(-1)
		"jump":
			_execute_ai_jump()
		"idle":
			_execute_ai_movement(0)

# AI action execution functions
func _execute_ai_punch(punch_type):
	if not attack_system.is_attacking and is_on_floor():
		attack_system.is_attacking = true
		if punch_type == "heavy_punch":
			animation.play("heavy_punch")
			$PunchHitbox.monitoring = true
			await get_tree().create_timer(0.2).timeout  # Adjust timing as needed
			$PunchHitbox.monitoring = false
		else:
			animation.play("basic_punch")
			$PunchHitbox.monitoring = true
			await get_tree().create_timer(0.1).timeout  # Adjust timing as needed
			$PunchHitbox.monitoring = false
		emit_signal("attack_executed", punch_type, global_position, false, 0)

func _execute_ai_kick(kick_type):
	if not attack_system.is_attacking and is_on_floor():
		attack_system.is_attacking = true
		if kick_type == "heavy_kick":
			animation.play("heavy_kick")
			$KickHitbox.monitoring = true
			await get_tree().create_timer(0.3).timeout  # Adjust timing as needed
			$KickHitbox.monitoring = false
		else:
			animation.play("basic_kick")
			$KickHitbox.monitoring = true
			await get_tree().create_timer(0.2).timeout  # Adjust timing as needed
			$KickHitbox.monitoring = false
		emit_signal("attack_executed", kick_type, global_position, false, 0)

# Add hit detection
func _on_hitbox_area_entered(area):
	if area.get_parent().is_in_group("Player"):
		var hit_position = area.global_position
		var damage = 10  # Base damage
		
		# Adjust damage based on attack type
		if current_ai_action == "heavy_punch" or current_ai_action == "heavy_kick":
			damage = 20
		
		# Emit signals for hit registration
		emit_signal("attack_hit", current_ai_action, hit_position, area.get_parent())
		emit_signal("attack_executed", current_ai_action, global_position, true, damage)
		
		# Apply damage to player
		if area.get_parent().has_node("PlayerHP"):
			area.get_parent().get_node("PlayerHP").value -= damage

func _execute_ai_movement(direction):
	if not attack_system.is_attacking:
		velocity.x = direction * 300  # Use the same speed as player movement
		if direction != 0:
			animation.play("walk")
		else:
			animation.play("idle")

func _execute_ai_jump():
	if is_on_floor() and not attack_system.is_attacking:
		velocity.y = -400  # Use the same jump force as player
		animation.play("jump")
		is_jumping = true

# Override process to prevent normal input handling for AI character
func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		if not is_jumping:
			is_jumping = true
	else:
		if is_jumping:
			is_jumping = false
			if not attack_system.is_attacking:
				animation.play("idle")
	
	move_and_slide()

# Connect animation finished signal
func _on_Animation_animation_finished(anim_name):
	if attack_system.is_attacking:
		attack_system.is_attacking = false
		# Disable hitboxes if they're still active
		$PunchHitbox.monitoring = false
		$KickHitbox.monitoring = false
		# Notify AI system that action is complete
		if ai_controller and ai_controller.ai_controller:
			var was_hit = current_ai_action in ["basic_punch", "heavy_punch", "basic_kick", "heavy_kick"]
			ai_controller.ai_controller.on_action_completed(
				current_ai_action,
				was_hit,  # Success based on if it was an attack
				global_position
			)
