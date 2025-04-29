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
		if MovementsClass:
			movementClass = MovementsClass.new(AI_animation, fighter, opponent)
			# Pass opponent reference if Movements needs it (original didn't seem to)
			# if movement_system.has_method("set_opponent"): movement_system.set_opponent(opponent)
		else: printerr("DecisionTreeController: Failed to load dummy_movement.gd")
	else: printerr("DecisionTreeController: dummy_movement.gd not found.")
	
	if FileAccess.file_exists("res://Scripts/dummy_attack.gd"):
		var AttackClass = load("res://Scripts/dummy_attack.gd")
		if AttackClass:
			attackClass = AttackClass.new(AI_animation, fighter, opponent)
			# Pass opponent reference if Movements needs it (original didn't seem to)
			# if movement_system.has_method("set_opponent"): movement_system.set_opponent(opponent)
		else: printerr("DecisionTreeController: Failed to load dummy_attack.gd")
	else: printerr("DecisionTreeController: dummy_attack.gd not found.")



func _physics_process(delta):
	if fighter == null or opponent == null:
		return

	if not fighter.is_on_floor():
		fighter.velocity.y += gravity * delta
		if opponent.current_animation == "crouch":
			attackClass.get_crouchAttacks()
			fighter.velocity = Vector2.ZERO
		else:
			attackClass.get_basicAttacks()
	fighter.move_and_slide()
	
func take_damage(amount: int):
	# Handle damage specific to this controller if needed
	pass

# Add other necessary functions (e.g., attack handlers if separate)
