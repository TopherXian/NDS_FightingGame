extends CharacterBody2D

var Starthp = 100
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 100

# CLASSES
var movementClass: DummyMovement
var attackClass: DummyAttack
var damageClass: DummyDamaged
var ai_controller: DummyRyuAI

# Reference to the enemy character
@onready var enemy = get_parent().get_node("Player")
@onready var enemy_animation = enemy.get_node("Animation")
func _ready():
	$DummyHP.value = Starthp
	damageClass = DummyDamaged.new()
	damageClass.init($Dummy_Animation, $DummyHP, self)
	movementClass = DummyMovement.new($Dummy_Animation, self, enemy)
	attackClass = DummyAttack.new($Dummy_Animation, self, enemy)
	
	# Initialize AI controller
	ai_controller = DummyRyuAI.new()
	add_child(ai_controller)  # Add as child to ensure it's part of the scene tree
	ai_controller.setup(enemy, self, null)  # Pass player and self as enemy
	
	# Connect AI signals
	ai_controller.action_predicted.connect(_on_ai_action_predicted)

func _on_dummy_lower_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		var attacker_pos = enemy.global_position
		damageClass.take_damage(10.0, attacker_pos)
		ai_controller.receive_hit(10, enemy)  # Notify AI of hit
		
func _on_dummy_upper_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		var attacker_pos = enemy.global_position
		damageClass.take_damage(10.0, attacker_pos)
		ai_controller.receive_hit(10, enemy)  # Notify AI of hit

func update_facing_direction():
	var facing_right = enemy.position.x > position.x
	$AnimatedSprite2D.flip_h = not facing_right  # Flip sprite based on direction
	$Dummy_Hitbox_Container.scale.x = 1 if facing_right else -1
	
	# Update hurtbox positions
	var hurtbox_direction = 1 if facing_right else -1
	$Dummy_LowerHurtbox.position.x = abs($Dummy_LowerHurtbox.position.x) * hurtbox_direction
	$Dummy_UpperHurtbox.position.x = abs($Dummy_UpperHurtbox.position.x) * hurtbox_direction

func _on_ai_action_predicted(action_type, params):
	# Don't process new actions if stunned or in the middle of an attack
	if damageClass.is_currently_stunned() or attackClass.is_attacking():
		return
		
	# Get the relative direction based on player position
	var direction = 1 if enemy.position.x > position.x else -1
	var distance = position.distance_to(enemy.position)
	
	match action_type:
		"walk_forward":
			# Don't walk forward if too close
			if distance > 60:
				movementClass.dummy_move(direction)
			else:
				movementClass.dummy_move(0)
		"walk_backward":
			# Add extra backward speed if at critical health
			if $DummyHP.value < 30:
				movementClass.dummy_move(-direction)
			else:
				movementClass.dummy_move(-direction)
		"jump":
			if is_on_floor():
				movementClass.dummy_jump()
				# Add slight forward/backward movement while jumping
				movementClass.dummy_move(direction if distance > 100 else -direction)
		"basic_punch", "heavy_punch", "basic_kick", "heavy_kick":
			# Only attempt attack if in proper range
			if _is_in_attack_range(action_type, distance):
				print("[DEBUG] Attempting attack: " + action_type + " at distance: " + str(distance))
				if attackClass.perform_attack(action_type):
					# Attack succeeded, stop movement
					movementClass.dummy_move(0)
					print("[DEBUG] Acttack succeeded: " + action_type)
					# Notify AI controller of successful attack for learning
					if ai_controller:
						ai_controller.on_action_completed(action_type, true, position)
			else:
				# Move towards attack range if too far
				var optimal_range = get_optimal_range(action_type)
				print("[DEBUG] Not in range for " + action_type + ". Distance: " + str(distance) + ", Optimal range: " + str(optimal_range))
				movementClass.dummy_move(direction if distance > optimal_range else -direction)
		"idle":
			movementClass.dummy_move(0)
			if not $Dummy_Animation.current_animation in ["hurt", "knocked_down"]:
				movementClass.play_attack_animation("idle")

# Helper function to determine optimal attack ranges
func get_optimal_range(attack_type: String) -> float:
	match attack_type:
		"basic_punch", "crouch_punch":
			return attackClass.PUNCH_RANGE - 10  # Slightly inside punch range
		"heavy_punch":
			return attackClass.PUNCH_RANGE - 5  # Closer for heavy punch
		"basic_kick", "crouch_kick":
			return attackClass.KICK_RANGE - 20
		"heavy_kick":
			return attackClass.KICK_RANGE - 10  # Closer for heavy kick
		_:
			return 100.0  # Default medium range

# Helper function to check if in range for an attack
func _is_in_attack_range(attack_type: String, distance: float) -> bool:
	match attack_type:
		"basic_punch", "crouch_punch":
			return distance <= attackClass.PUNCH_RANGE + 5 # Slightly more generous range
		"heavy_punch":
			return distance <= attackClass.PUNCH_RANGE + 10 # Extended range for heavy punch
		"basic_kick", "crouch_kick":
			return distance <= attackClass.KICK_RANGE + 5 # Slightly more generous range
		"heavy_kick":
			return distance <= attackClass.KICK_RANGE + 10 # Extended range for heavy kick
	return false

func _physics_process(delta):
	update_facing_direction()
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Update damage state
	damageClass.update(delta)
	
	# Only process AI and attacks if not stunned
	if not damageClass.is_currently_stunned():
		# Update attack cooldown
		attackClass.update_attack_cooldown(delta)
		
		# Let AI make decisions only if not attacking
		if not attackClass.is_attacking():
			ai_controller._process(delta)

		# Check if we should trigger an attack based on proximity to player
		# This serves as a backup to ensure attacks happen
		var distance_to_player = position.distance_to(enemy.position)
		if not attackClass.is_attacking() and attackClass.attack_cooldown <= 0:
			# Try attacks based on range
			if distance_to_player <= attackClass.PUNCH_RANGE:
				var attack_chance = 0.15  # 15% chance per frame when in range
				if randf() <= attack_chance:
					print("[DEBUG] Proximity-triggered basic punch")
					attackClass.perform_attack("basic_punch")
			elif distance_to_player <= attackClass.KICK_RANGE:
				var attack_chance = 0.1  # 10% chance per frame when in kick range
				if randf() <= attack_chance:
					print("[DEBUG] Proximity-triggered basic kick")
					attackClass.perform_attack("basic_kick")
		
		# Handle crouching attacks only if not in AI attack and close to player
		if enemy_animation.current_animation == "crouch" and not attackClass.is_attacking():
			var distance = position.distance_to(enemy.position)
			if distance <= attackClass.PUNCH_RANGE:
				attackClass.get_crouchAttacks()
	
	move_and_slide()
