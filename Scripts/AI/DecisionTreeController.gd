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

# --- State Machine ---
enum State { IDLE, APPROACHING, ATTACKING, DEFENDING, REPOSITIONING, HURT }
var current_state: State = State.IDLE

# --- Defense Logic ---
var can_defend: bool = true
var defense_cooldown_timer: Timer
const DEFENSE_COOLDOWN_TIME: float = 0.5 # Time in seconds before AI can defend again
const DEFENSE_PROBABILITY: float = 0.8 # 80% chance to defend when conditions met
const DEFENSE_TRIGGER_RANGE: float = 75.0 # How close opponent attack must be

# --- Attack Logic ---
# Keep track if AI is currently in an attack animation (set by state, reset by signal)
var is_attacking: bool = false
# More nuanced attack chance (replace simple proactive chance)
const ATTACK_OPPORTUNITY_RANGE: float = 75.0 # Max range to consider attacking

const PROACTIVE_ATTACK_CHANCE: float = 0.15 # 15% chance per second
const PROACTIVE_APPROACH_CHANCE: float = 0.3 # 30% chance per second
var idle_time: float = 0.0 # Track time spent in IDLE

# --- Repositioning Logic ---
var reposition_timer: Timer
const REPOSITION_DURATION: float = 0.3 # How long to move back

# List of opponent attack animations that trigger defense
const OPPONENT_ATTACKS = [&"basic_punch", &"basic_kick", &"heavy_punch", &"heavy_kick", &"crouch_punch", &"crouch_kick"]
const ATTACK_ANIMATIONS = [&"basic_punch", &"basic_kick", &"crouch_punch", &"crouch_kick"] # Add heavy attacks if AI uses them
const DEFENSE_ANIMATIONS = [&"standing_defense", &"crouching_defense"]
const MOVEMENT_ANIMATIONS = [&"walk_forward", &"walk_backward"] # Add jump if used

func init_controller(fighter_node: CharacterBody2D, anim_player: AnimationPlayer, opp_node: CharacterBody2D):
	fighter = fighter_node
	animation_player = anim_player
	opponent = opp_node

	# Get opponent's animation player [cite: 1, 2]
	if is_instance_valid(opponent) and (opponent.has_node("Animation") or opponent.has_node("Dummy_Animation")):
		opponent_animation_player = opponent.get_node("Animation") if opponent.has_node("Animation") else opponent.get_node("Dummy_Animation")
	else:
		print("DecisionTreeController: Could not find opponent AnimationPlayer!")

	# --- Instantiate AI logic components --- [cite: 2]
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

	# --- Setup Timers ---
	# Defense Cooldown Timer
	defense_cooldown_timer = Timer.new()
	defense_cooldown_timer.wait_time = DEFENSE_COOLDOWN_TIME
	defense_cooldown_timer.one_shot = true
	defense_cooldown_timer.connect("timeout", Callable(self, "_on_defense_cooldown_timeout"))
	add_child(defense_cooldown_timer) # Add timer to the scene tree

	# Reposition Timer
	reposition_timer = Timer.new()
	reposition_timer.wait_time = REPOSITION_DURATION
	reposition_timer.one_shot = true
	reposition_timer.connect("timeout", Callable(self, "_on_reposition_timeout"))
	add_child(reposition_timer)

	# Connect to animation finished signal [cite: 3]
	if animation_player and not animation_player.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

	print("Decision Tree Controller Initialized for: ", fighter.name)


func _physics_process(_delta):
	
	if current_state == State.HURT:
		return
		
	if not is_instance_valid(fighter) or not is_instance_valid(opponent) or fighter.health <= 0:
		if is_instance_valid(fighter): fighter.velocity = Vector2.ZERO
		return

	# --- Get Current World State ---
	var opponent_anim_name: StringName = &""
	if is_instance_valid(opponent_animation_player):
		opponent_anim_name = opponent_animation_player.current_animation
	var distance = fighter.global_position.distance_to(opponent.global_position)
	var current_fighter_anim = animation_player.current_animation if animation_player.is_playing() else &""

	# --- State Machine Logic ---
	match current_state:
		
		State.HURT:
			# Wait for the hurt animation to finish (handled in _on_animation_finished)
			fighter.velocity.x = 0 # Stop movement while hurt
			
		State.IDLE:
			
			idle_time += _delta # Track idle duration

			# --- Proactive Transitions ---
			if idle_time > 1.5: # Only act after 1.5s of inactivity
			# Randomly attack even without opponent action
				if randf() < PROACTIVE_ATTACK_CHANCE * _delta:
					_change_state(State.ATTACKING)
					idle_time = 0.0
			# Randomly approach to close distance
			elif randf() < PROACTIVE_APPROACH_CHANCE * _delta:
				_change_state(State.APPROACHING)
				idle_time = 0.0
				
			# Play idle animation if not already doing something important
			if current_fighter_anim not in ATTACK_ANIMATIONS and \
			   current_fighter_anim not in DEFENSE_ANIMATIONS and \
			   current_fighter_anim not in MOVEMENT_ANIMATIONS and \
			   current_fighter_anim != &"hurt": # Assuming hurt recovery is handled
				if current_fighter_anim != &"idle":
					_play_animation("idle")
			fighter.velocity.x = 0 # Ensure stopped

			# --- Transitions from IDLE ---
			# 1. Defend?
			if _should_defend(opponent_anim_name, distance):
				_change_state(State.DEFENDING)
			# 2. Attack? (Opponent is close and maybe idle/walking?)
			elif _should_attack(opponent_anim_name, distance):
				_change_state(State.ATTACKING)
			# 3. Approach? (Opponent is far)
			elif _should_approach(distance):
				_change_state(State.APPROACHING)
			# 4. Reposition? (Maybe random chance or if opponent is too close and idle)
			elif _should_reposition(distance):
				_change_state(State.REPOSITIONING)


		State.APPROACHING:
			# Use movement logic to move towards opponent [cite: 5]
			if is_instance_valid(movement_logic):
				movement_logic.decide_movement() # Assumes this sets velocity & animation
			else: # Fallback basic movement
				_move_towards_opponent()
				_play_animation("walk_forward", true) # Force if logic missing

			# --- Transitions from APPROACHING ---
			# 1. Close enough? -> Idle/Attack decision
			if distance <= ATTACK_OPPORTUNITY_RANGE:
				if _should_attack(opponent_anim_name, distance): # Check attack first
					_change_state(State.ATTACKING)
				else:
					_change_state(State.IDLE) # Go idle if close but no attack opportunity
					pass
			# 2. Need to defend while approaching?
			elif _should_defend(opponent_anim_name, distance):
				_change_state(State.DEFENDING)


		State.ATTACKING:
			# Logic: Execute the chosen attack (done on state entry)
			# State exit is handled by _on_animation_finished
			fighter.velocity.x = 0 # Ensure stopped during attack
			is_attacking = true

			# --- Transitions from ATTACKING ---
			# Primarily handled by _on_animation_finished


		State.DEFENDING:
			# Logic: Play defense animation (done on state entry)
			fighter.velocity.x = 0 # Ensure stopped

			# --- Transitions from DEFENDING ---
			# 1. Opponent stopped attacking or moved away? -> Idle/Reposition
			if not (opponent_anim_name in OPPONENT_ATTACKS and distance < DEFENSE_TRIGGER_RANGE):
				# Maybe reposition briefly after defending
				if randf() < 0.5: # 50% chance to reposition
					_change_state(State.REPOSITIONING)
				else:
					_change_state(State.IDLE)


		State.REPOSITIONING:
			# Logic: Move backward (done on state entry)
			# State exit is handled by _on_reposition_timeout

			# --- Transitions from REPOSITIONING ---
			# 1. Timer handles transition back to IDLE
			# 2. Can still be interrupted by defense need
			if _should_defend(opponent_anim_name, distance):
				reposition_timer.stop() # Stop repositioning early
				_change_state(State.DEFENDING)


# --- State Change Helper ---
func _change_state(new_state: State):
	if current_state == State.IDLE:
		idle_time = 0.0 # Reset counter when leaving IDLE
	if current_state == new_state: return # No change

	# print("Changing state from %s to %s" % [State.keys()[current_state], State.keys()[new_state]]) # Debug

	# --- Logic on EXITING previous state (optional) ---
	# match current_state:
		# State.APPROACHING:
			# fighter.velocity.x = 0 # Stop movement if wasn't stopped by next state

	current_state = new_state

	# --- Logic on ENTERING new state ---
	match current_state:
		State.IDLE:
			fighter.velocity.x = 0
			# Play idle only if not already playing something important (checked in IDLE logic)
		State.APPROACHING:
			# Movement handled in state logic
			pass
		State.ATTACKING:
			fighter.velocity.x = 0 # Stop movement
			if is_instance_valid(attack_logic):
				var attack_anim = attack_logic.get_basic_attack_action() # Or more complex choice
				if attack_anim != &"":
					_play_animation(attack_anim)
					is_attacking = true
				else:
					# Failed to find valid attack, revert to IDLE
					_change_state(State.IDLE)
			else:
				# Attack logic missing, revert to IDLE
				_change_state(State.IDLE)
		State.DEFENDING:
			fighter.velocity.x = 0
			# Choose crouch/stand defense based on opponent anim? (Simplified here)
			_play_animation("standing_defense")
			can_defend = false
			defense_cooldown_timer.start()
		State.REPOSITIONING:
			# Move backward
			_move_away_from_opponent()
			_play_animation("walk_backward", true) # Force walk backward animation
			reposition_timer.start()


# --- Decision Helper Functions ---
func _should_defend(opponent_anim, dist) -> bool:
	if not can_defend: return false
	if opponent_anim in OPPONENT_ATTACKS and dist < DEFENSE_TRIGGER_RANGE:
		# Check if already defending
		if animation_player.current_animation == "standing_defense" or \
		   animation_player.current_animation == "crouching_defense":
			return false # Already defending, stay in state but don't re-trigger cooldown

		# Check probability
		if randf() < DEFENSE_PROBABILITY:
			return true
	return false

func _should_attack(opponent_anim, dist) -> bool:
	# Allow attacks even if slightly out of range
	var effective_range = ATTACK_OPPORTUNITY_RANGE # +20% buffer
	
	if dist <= effective_range and not is_attacking:
		# Original checks + allow attacks during mutual idle
		if opponent_anim == &"idle" or opponent_anim == &"":
			return randf() < 0.6 # 60% chance to attack idle opponent
			
	if is_attacking: return false # Already attacking
	if dist <= ATTACK_OPPORTUNITY_RANGE:
		# Basic condition: Attack if opponent is close and not attacking/defending
		if not (opponent_anim in OPPONENT_ATTACKS or \
				opponent_anim in DEFENSE_ANIMATIONS):
			# Check if AI has a valid attack for this range
			if is_instance_valid(attack_logic) and attack_logic.get_basic_attack_action() != &"":
				# Add more complex checks? e.g., chance based on health, opponent recovery frames etc.
				return true # Potential attack opportunity
	return false

func _should_approach(dist) -> bool:
	# Approach if opponent is further than attack range + a buffer
	return dist > ATTACK_OPPORTUNITY_RANGE + 20

func _should_reposition(dist) -> bool:
	# Example: Reposition if opponent is very close but not attacking (crowding)
	if dist < 40 and not (opponent_animation_player.current_animation in OPPONENT_ATTACKS):
		if randf() < 0.1: # Low chance to reposition if crowded
			return true
	# Example: Random chance after defending or attacking
	# (Handled in state transitions)
	return false


# --- Movement Helpers (Fallback if DummyMovement fails/missing) ---
func _move_towards_opponent():
	if not is_instance_valid(fighter) or not is_instance_valid(opponent): return
	var direction = sign(opponent.global_position.x - fighter.global_position.x)
	fighter.velocity.x = direction * 300  # Use fixed speed if movement_logic is missing
	# Force animation if needed
	_play_animation("walk_forward", true)

func _move_away_from_opponent():
	if not is_instance_valid(fighter) or not is_instance_valid(opponent): return
	var direction = -1 if opponent.global_position.x > fighter.global_position.x else 1
	fighter.velocity.x = direction * movement_logic.speed if is_instance_valid(movement_logic) else direction * 150


# --- Animation Helper ---
func _play_animation(anim_name: StringName, force_restart: bool = false):
	if is_instance_valid(animation_player):
		if animation_player.current_animation != anim_name or force_restart:
			animation_player.play(anim_name)


# --- Signal Callbacks ---
func _on_animation_finished(anim_name: StringName):

	# Reset attacking flag if an attack animation finished [cite: 9]
	if anim_name in ATTACK_ANIMATIONS:
		is_attacking = false
		# Decide next state after attacking
		if randf() < 0.3: # Chance to reposition after attack
			_change_state(State.REPOSITIONING)
		else:
			_change_state(State.IDLE) # Default to idle after attacking
			
	if anim_name == "hurt":
		# Return to IDLE after recovering from damage
		_change_state(State.IDLE)

	# If a non-looping defense animation finishes, transition
	# if anim_name in DEFENSE_ANIMATIONS and not animation_player.get_animation(anim_name).loop:
	#     _change_state(State.IDLE)

func _on_defense_cooldown_timeout():
	can_defend = true
	# print("Defense cooldown finished.") # Debug

func _on_reposition_timeout():
	# Stop moving and go back to idle after repositioning
	if current_state == State.REPOSITIONING: # Ensure we are still repositioning
		fighter.velocity.x = 0
		_change_state(State.IDLE)
	# print("Reposition finished.") # Debug


func notify_damage_taken(_amount: int, _is_upper: bool, _defended: bool):
	# Immediately cancel attacks and transition to HURT state
	if is_attacking:
		is_attacking = false
	_change_state(State.HURT)
