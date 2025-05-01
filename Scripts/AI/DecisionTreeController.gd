# DecisionTreeController.gd
extends Node
class_name DecisionTreeController

# --- References (Set by BaseFighter) ---
var fighter: CharacterBody2D # Reference to the BaseFighter node
var animation_player: AnimationPlayer
var opponent: CharacterBody2D
var opponent_animation_player: AnimationPlayer # Reference to opponent's anim player

# --- Component Instances ---
var movement_logic: DummyMovement
var attack_logic: DummyAttack

# --- State ---
var is_defending: bool = false
var is_attacking: bool = false # Track if AI is currently in an attack animation

@export var proactive_attack_chance: float = 0.2

# List of opponent attack animations that trigger defense
const OPPONENT_ATTACKS = [&"basic_punch", &"basic_kick", &"heavy_punch", &"heavy_kick", &"crouch_punch", &"crouch_kick"]

func init_controller(fighter_node: CharacterBody2D, anim_player: AnimationPlayer, opp_node: CharacterBody2D):
	fighter = fighter_node
	animation_player = anim_player
	opponent = opp_node

	# Get opponent's animation player
	if is_instance_valid(opponent) and (opponent.has_node("Animation") or opponent.has_node("Dummy_Animation")): # Adjust path if needed
		opponent_animation_player = opponent.get_node("Animation") if opponent.has_node("Animation") else opponent.get_node("Dummy_Animation")
	else:
		print("DecisionTreeController: Could not find opponent AnimationPlayer!")
		# Might need fallback logic if opponent animation can't be checked

	# --- Instantiate AI logic components ---
	# Ensure the class scripts exist and paths are correct
	var movement_script_path = "res://Scripts/DummyMovement.gd"
	if FileAccess.file_exists(movement_script_path):
		var MovementClass = load(movement_script_path)
		if MovementClass:
			movement_logic = MovementClass.new(animation_player, fighter, opponent)
		else: print("DecisionTreeController: Failed to load DummyMovement.gd")
	else: print("DecisionTreeController: DummyMovement.gd not found at ", movement_script_path)

	var attack_script_path = "res://Scripts/DummyAttack.gd"
	if FileAccess.file_exists(attack_script_path):
		var AttackClass = load(attack_script_path)
		if AttackClass:
			attack_logic = AttackClass.new(fighter, opponent)
		else: print("DecisionTreeController: Failed to load DummyAttack.gd")
	else: print("DecisionTreeController: DummyAttack.gd not found at ", attack_script_path)

	# Connect to the animation player's finished signal to reset attack flag
	if animation_player and not animation_player.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

	print("Decision Tree Controller Initialized for: ", fighter.name)


func _physics_process(_delta):
	if not is_instance_valid(fighter) or not is_instance_valid(opponent) or fighter.health <= 0:
		# Stop processing if fighter/opponent invalid or fighter is defeated
		fighter.velocity = Vector2.ZERO # Ensure velocity is zeroed
		return

# --- Get Current State ---
	var opponent_anim_name: StringName = &""
	if is_instance_valid(opponent_animation_player):
		opponent_anim_name = opponent_animation_player.current_animation

	# Reset flags
	is_defending = false
	var desired_attack: StringName = &""

	# --- Decision Logic ---

	# 1. Check for Defense Condition (Reactive)
	if opponent_anim_name in OPPONENT_ATTACKS:
		is_defending = true
		fighter.velocity.x = 0
		if animation_player.current_animation != "standing_defense":
			animation_player.play("standing_defense")

	# 2. If NOT Defending and NOT Attacking, consider Proactive Attack, Movement, and Reactive Attack
	elif not is_attacking:
		# a. Proactive Attack Check (NEW)
		# Only check if not defending and on the floor
		if fighter.is_on_floor() and randf() < proactive_attack_chance:
			# Check distance using the attack logic helper
			if is_instance_valid(attack_logic):
				desired_attack = attack_logic.get_basic_attack_action()
				#if desired_attack != &"": # If an attack is valid at this range
					#print("DecisionTree: Proactive attack!") # For debugging
					# Proceed to execute below

		# b. Decide Movement (only if no attack was chosen proactively)
		if desired_attack == &"" and is_instance_valid(movement_logic):
			movement_logic.decide_movement()

		# c. Decide Reactive Attack (only if no proactive attack chosen)
		#    (This part might be redundant if proactive uses the same distance check)
		if desired_attack == &"" and is_instance_valid(attack_logic):
			# Check if basic attack is viable based on distance (reactive to position)
			desired_attack = attack_logic.get_basic_attack_action()

		# d. Execute Chosen Attack (if any)
		if desired_attack != &"":
			fighter.velocity.x = 0 # Stop moving
			animation_player.play(desired_attack)
			is_attacking = true

		# e. Idle (if not moving, not attacking, on floor)
		elif fighter.velocity.x == 0 and fighter.is_on_floor():
			if animation_player.current_animation not in [&"idle", &"hurt", &"standing_defense", &"crouching_defense"]:
				if not is_attacking:
					animation_player.play("idle")

# Called when any animation finishes on this character's AnimationPlayer
func _on_animation_finished(anim_name: StringName):
	# Reset the attacking flag if an attack animation just finished
	# You might want a more specific list of attack animations here
	const ATTACK_ANIMATIONS = [&"basic_punch", &"basic_kick", &"crouch_punch", &"crouch_kick"]
	if anim_name in ATTACK_ANIMATIONS:
		is_attacking = false
		# Optionally, play idle immediately after attack if needed
		# if fighter.is_on_floor():
		#     animation_player.play("idle")

	# Reset defending flag? Maybe not needed if checked each frame
	# if anim_name == &"standing_defense":
	#     is_defending = false


# Optional: Allow BaseFighter to notify this controller if needed
func notify_damage_taken(_amount: int, _is_upper: bool, _defended: bool):
	# AI could potentially react to getting hit, e.g., cancel current action
	# print("DecisionTreeController notified: Took ", amount, " damage.")
	# For this simple AI, maybe just print or ignore
	pass
