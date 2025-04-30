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
	else:
		# Handle case where opponent anim player isn't found
		pass

	# Reset flags at the start of the frame
	is_defending = false
	var desired_attack: StringName = &""

	# --- Decision Logic (Based on test.txt) ---

	# 1. Check for Defense Condition
	if opponent_anim_name in OPPONENT_ATTACKS:
		# Opponent is attacking, attempt to defend
		is_defending = true
		fighter.velocity.x = 0 # Stop horizontal movement when defending
		if animation_player.current_animation != "standing_defense": # Check if already defending
			animation_player.play("standing_defense")
			# Don't reset is_attacking flag here, defense is not an attack

	# 2. If NOT Defending, consider Movement and Attack
	if not is_defending and not is_attacking: # Only move/attack if not defending and not already attacking
		# a. Decide Movement (uses DummyMovement logic)
		if is_instance_valid(movement_logic):
			movement_logic.decide_movement() # Sets fighter.velocity.x and plays walk anim if needed

		# b. Decide Attack (uses DummyAttack logic)
		if is_instance_valid(attack_logic):
			desired_attack = attack_logic.get_basic_attack_action()

		# c. Execute Attack if one is desired and AI is in range/state to do so
		if desired_attack != &"":
			fighter.velocity.x = 0 # Stop moving when starting an attack
			animation_player.play(desired_attack)
			is_attacking = true # Set flag to prevent other actions during attack

		# d. If no attack chosen and not moving, play idle
		elif fighter.velocity.x == 0 and fighter.is_on_floor():
			if animation_player.current_animation != "idle": # Check if already idle
				animation_player.play("idle")

	# Note: Gravity and move_and_slide() are handled by BaseFighter.gd

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
