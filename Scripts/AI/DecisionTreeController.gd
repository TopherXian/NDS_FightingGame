# DecisionTreeController.gd
extends Node
class_name DecisionTreeController

# --- Dependencies (Example - Adjust as needed) ---
var AI_animation: AnimationPlayer
var fighter: CharacterBody2D
var opponent: CharacterBody2D
var opponent_animation : AnimationPlayer
# --- Decision Trees Component Instances (From DS_ryu.txt) ---
var movementClass: DummyMovement
var attackClass: DummyAttack

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 100

func _init(char_body = null, anim_player = null, opp = null):
	# Store references if provided
	# character_body = char_body
	# animation_player = anim_player
	# opponent = opp
	print("Decision Tree Controller Initialized")
	pass

func init_controller(fighter_node: CharacterBody2D, anim_player: AnimationPlayer, opp_node: CharacterBody2D, playerHP: ProgressBar):
	fighter = fighter_node
	AI_animation = anim_player
	opponent = opp_node
	opponent_animation = opponent.get_node("Animation")
	print(fighter)
	print(opponent)
	
	if FileAccess.file_exists("res://Scripts/dummy_movement.gd"):
		var MovementsClass = load("res://Scripts/dummy_movement.gd")
		print("Movement Class Found")
		if MovementsClass:
			print("Movement Class Loaded")
			movementClass = MovementsClass.new(AI_animation, fighter, opponent)
			# Pass opponent reference if Movements needs it (original didn't seem to)
			# if movement_system.has_method("set_opponent"): movement_system.set_opponent(opponent)
		else: printerr("DecisionTreeController: Failed to load dummy_movement.gd")
	else: printerr("DecisionTreeController: dummy_movement.gd not found.")
	
	if FileAccess.file_exists("res://Scripts/dummy_attack.gd"):
		var AttackClass = load("res://Scripts/dummy_attack.gd")
		print("Attack Class Found")
		if AttackClass:
			print("Attack Class Loaded")
			attackClass = AttackClass.new(AI_animation, fighter, opponent)
			# Pass opponent reference if Movements needs it (original didn't seem to)
			# if movement_system.has_method("set_opponent"): movement_system.set_opponent(opponent)
		else: printerr("DecisionTreeController: Failed to load dummy_attack.gd")
	else: printerr("DecisionTreeController: dummy_attack.gd not found.")



func _physics_process(delta):
	if fighter == null or opponent == null:
		return
	# Update facing direction based on opponent position
	update_facing_direction()
	# Gravity and attacking logic
	if not fighter.is_on_floor():
		fighter.velocity.y += gravity * delta
		if opponent_animation.current_animation == "crouch":
			if attackClass:
				attackClass.get_crouchAttacks()
			fighter.velocity = Vector2.ZERO
		else:
			if attackClass:
				attackClass.get_basicAttacks()

	# Movement logic
	fighter.move_and_slide()



func update_facing_direction():
	if not fighter or not opponent or not movementClass:
		return
	# Calculate the distance between the fighter and opponent
	var distance_to_opponent = fighter.position.distance_to(opponent.position)

	# Only execute facing direction and movement logic if the distance is greater than 100
	if distance_to_opponent > 100:
		if opponent.position.x > fighter.position.x:
			fighter.get_node("AnimatedSprite2D").flip_h = false  # Face right
			fighter.get_node("Dummy_Hitbox").position.x = abs(fighter.get_node("Dummy_Hitbox").position.x)
			fighter.get_node("Dummy_LowerHurtbox").position.x = abs(fighter.get_node("Dummy_LowerHurtbox").position.x)
			fighter.get_node("Dummy_UpperHurtbox").position.x = abs(fighter.get_node("Dummy_UpperHurtbox").position.x)
			print("character facing right")
			movementClass.dummy_move(speed)
		else:
			fighter.get_node("AnimatedSprite2D").flip_h = true  # Face left
			fighter.get_node("Dummy_Hitbox").scale.x = -1
			fighter.get_node("Dummy_Hitbox").position.x = -abs(fighter.get_node("Dummy_Hitbox").position.x)
			fighter.get_node("Dummy_LowerHurtbox").position.x = -abs(fighter.get_node("Dummy_LowerHurtbox").position.x)
			fighter.get_node("Dummy_UpperHurtbox").position.x = -abs(fighter.get_node("Dummy_UpperHurtbox").position.x)
			print("character facing left")
			movementClass.dummy_move(-speed)
	else:
		# If distance is less than or equal to 100, stop any movement or facing updates
		print("Player is too close to AI, no movement or facing update")
		pass

	
	
func take_damage(amount: int):
	# Handle damage specific to this controller if needed
	pass

# Add other necessary functions (e.g., attack handlers if separate)
