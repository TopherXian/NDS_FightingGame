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
var last_executed_decision: String = "Initializing" # <--- ADD THIS VARIABLE

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
var idle_time: float = 0.0 # Track time spent idle

# --- Attack Animation Names (for signal handling) ---
# Adjust these if your animation names are different
const ATTACK_ANIMATIONS: Array[StringName] = [
	&"basic_punch", &"basic_kick",
	&"crouch_punch", &"crouch_kick",
	&"heavy_punch", &"heavy_kick" # Add any other attack animations
]
const DEFENSE_ANIMATIONS: Array[StringName] = [&"standing_defense", &"crouching_defense"]


# --- Initialization ---
func init_controller(fighter_node: CharacterBody2D, anim_player: AnimationPlayer, opp_node: CharacterBody2D):
	fighter = fighter_node
	animation_player = anim_player
	opponent = opp_node
	print("Decision Tree Controller Initialized for: ", fighter.name)

	# Get opponent's animation player if available
	if opponent and opponent.has_node("AnimationPlayer"):
		opponent_animation_player = opponent.get_node("AnimationPlayer")

	# Instantiate logic components
	movement_logic = DummyMovement.new(animation_player, fighter, opponent)
	attack_logic = DummyAttack.new(fighter, opponent) # Pass opponent

	# Setup Timers
	defense_cooldown_timer = Timer.new()
	defense_cooldown_timer.wait_time = DEFENSE_COOLDOWN_TIME
	defense_cooldown_timer.one_shot = true
	defense_cooldown_timer.connect("timeout", Callable(self, "_on_defense_cooldown_timeout"))
	add_child(defense_cooldown_timer)

	# Connect animation finished signal if not already connected
	if animation_player and not animation_player.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

	_change_state(State.IDLE) # Start in idle state


# --- Getter for the current decision ---
func get_current_decision() -> String: # <--- ADD THIS FUNCTION
	return last_executed_decision

# --- Core Logic ---
func _physics_process(delta):
	if not is_instance_valid(fighter) or not fighter.is_inside_tree():
		return # Don't process if fighter is gone
	if not is_instance_valid(opponent):
		# Opponent might be removed (e.g., end of round), go idle
		_change_state(State.IDLE)
		return

	# Apply gravity (moved from BaseFighter for AI control)
	if not fighter.is_on_floor():
		fighter.velocity.y += fighter.gravity * delta
	else:
		fighter.is_jumping = false # Reset jump flag when grounded

	# State machine logic
	match current_state:
		State.IDLE:
			idle_time += delta
			_decide_action(delta)
		State.APPROACHING:
			_execute_approach()
			# Check if close enough to attack or if should stop approaching
			var distance = fighter.global_position.distance_to(opponent.global_position)
			if distance <= ATTACK_OPPORTUNITY_RANGE:
				_decide_attack() # Try attacking if close
			elif distance < 50: # Stop if very close but not attacking
				_change_state(State.IDLE)
		State.ATTACKING:
			# State managed by animation finished signal
			# Ensure velocity is zeroed during attack unless specific attack moves
			if animation_player.current_animation in ATTACK_ANIMATIONS: # Check specific attacks if needed
				fighter.velocity.x = 0
				# fighter.velocity.y = 0 # Might interfere with gravity if mid-air attack
		State.DEFENDING:
			fighter.velocity.x = 0 # Stop movement while defending
			# Add logic to check if defense should end (e.g., opponent stops attacking)
			# For now, relies on animation finishing or being interrupted by hurt/new decision
			if _should_defend(): # Continuously check if defense is needed
				_execute_defense() # Re-play animation if stopped
			else:
				_change_state(State.IDLE) # Stop defending if threat passed
		State.REPOSITIONING:
			# Movement handled by _execute_reposition
			# Timer will transition back to IDLE
			pass
		State.HURT:
			# State managed by animation finished signal from Damaged system
			is_attacking = false # Cancel any attack intent
			pass

	# Apply movement only if not attacking or in a state that prevents it
	if current_state != State.ATTACKING and current_state != State.DEFENDING and current_state != State.HURT:
		fighter.move_and_slide()


# --- Decision Making ---
func _decide_action(delta):
	fighter.velocity.x = 0 # Default to stop moving when idle/deciding

	# 1. Check for defense opportunity (highest priority)
	if _should_defend() and can_defend and randf() < DEFENSE_PROBABILITY:
		_change_state(State.DEFENDING)
		return

	# 2. Check for attack opportunity
	var distance = fighter.global_position.distance_to(opponent.global_position)
	if distance <= ATTACK_OPPORTUNITY_RANGE:
		_decide_attack() # Checks internally if already attacking
		if current_state == State.ATTACKING:
			return # Attack decision made

	# 3. Proactive actions (if idle for a bit)
	if idle_time > 0.2: # Only act proactively after a short pause
		var random_action = randf()
		if random_action < PROACTIVE_ATTACK_CHANCE * delta * 60: # Scale chance by frame time
			_decide_attack()
			if current_state == State.ATTACKING: return
		elif random_action < (PROACTIVE_ATTACK_CHANCE + PROACTIVE_APPROACH_CHANCE) * delta * 60:
			_change_state(State.APPROACHING)
			return
		# Add chance for REPOSITIONING?
		# elif random_action < (PROACTIVE_ATTACK_CHANCE + PROACTIVE_APPROACH_CHANCE + REPOSITION_CHANCE) * delta * 60:
		#     _change_state(State.REPOSITIONING)
		#     return

	# 4. If no other action, remain idle (or ensure idle anim plays)
	if current_state == State.IDLE and animation_player.current_animation != "idle":
		_play_animation("idle")


func _decide_attack():
	if is_attacking or current_state == State.HURT: return # Don't attack if already attacking or hurt

	var attack_anim = &"" # Empty StringName
	# Add more complex logic: consider opponent state, health, distance, etc.
	# Example: Prioritize crouch attacks if opponent is crouching?
	# Example: Use heavy attacks occasionally or when opponent is vulnerable?

	# Simple distance-based basic attack for now
	var distance = fighter.global_position.distance_to(opponent.global_position)
	if distance < 55: # Punch range
		attack_anim = attack_logic.get_basic_attack_action() # Will return "basic_punch" or ""
	elif distance < ATTACK_OPPORTUNITY_RANGE: # Kick range
		attack_anim = &"basic_kick" # Directly use kick if punch too far

	# Maybe add crouch attacks?
	# if fighter.is_crouching and distance < CROUCH_ATTACK_RANGE:
	#     attack_anim = attack_logic.get_crouch_attack_action()

	if attack_anim != &"":
		_change_state(State.ATTACKING)
		_play_animation(attack_anim)


func _should_defend() -> bool:
	if not is_instance_valid(opponent_animation_player): return false

	var opp_anim_name = opponent_animation_player.current_animation
	if opp_anim_name in ATTACK_ANIMATIONS: # Check if opponent is doing any attack animation
		# Check if the attack is close enough to warrant defense
		var distance = fighter.global_position.distance_to(opponent.global_position)
		if distance < DEFENSE_TRIGGER_RANGE:
			# Optional: Check if the attack would actually hit (e.g., high vs low)
			# print("Opponent attacking (%s) within defense range." % opp_anim_name) # Debug
			return true
	return false

# --- State Execution ---
func _change_state(new_state: State):
	if current_state == new_state: return # No change

	# print("Changing state from %s to %s" % [State.keys()[current_state], State.keys()[new_state]]) # Debug

	# Exit logic for previous state (optional)
	match current_state:
		State.IDLE:
			idle_time = 0.0 # Reset idle timer when leaving idle state
		State.APPROACHING:
			if new_state != State.ATTACKING: # Stop moving if not transitioning to attack
				fighter.velocity.x = 0
				# Play idle only if not going to another active state like defend/hurt
				if new_state == State.IDLE: _play_animation("idle")
		State.ATTACKING:
			is_attacking = false # Ensure flag is reset when leaving attack state (belt-and-braces)
		State.DEFENDING:
			# Stop defense animation if transitioning out explicitly
			# This might be handled by _play_animation below anyway
			pass
		State.REPOSITIONING:
			# Stop reposition timer if interrupted
			if get_node_or_null("RepositionTimer"):
				get_node("RepositionTimer").stop()
			fighter.velocity.x = 0
			if new_state == State.IDLE: _play_animation("idle")


	current_state = new_state

	# Entry logic for new state
	match current_state:
		State.IDLE:
			last_executed_decision = "Idle" # <--- UPDATE DECISION
			_play_animation("idle")
			fighter.velocity.x = 0
		State.APPROACHING:
			last_executed_decision = "Approaching" # <--- UPDATE DECISION
			# Movement direction set in _execute_approach
			_play_animation("walk_forward") # Assumes walk forward anim exists
		State.ATTACKING:
			is_attacking = true
			# Animation and decision string set by _decide_attack -> _play_animation
		State.DEFENDING:
			last_executed_decision = "Defending" # <--- UPDATE DECISION (initial)
			_execute_defense() # Play correct defense anim
			can_defend = false # Start cooldown
			defense_cooldown_timer.start()
		State.REPOSITIONING:
			last_executed_decision = "Repositioning" # <--- UPDATE DECISION
			_execute_reposition()
		State.HURT:
			last_executed_decision = "Hurt" # <--- UPDATE DECISION
			# Animation is played by the Damaged system signal
			pass


func _execute_approach():
	var fighter_sprite
	fighter_sprite = fighter.get_node("Sprite") if fighter.has_node("Sprite") else fighter.get_node("AnimatedSprite2D")
	var direction_to_opponent = opponent.global_position.x - fighter.global_position.x
	if direction_to_opponent > 0:
		fighter.velocity.x = movement_logic.speed # Access speed from movement logic
		fighter_sprite.flip_h = false # Ensure facing right
	elif direction_to_opponent < 0:
		fighter.velocity.x = -movement_logic.speed
		fighter_sprite.flip_h = true # Ensure facing left
	else:
		fighter.velocity.x = 0 # Stop if directly above/below

	# Ensure walk animation continues playing
	_play_animation("walk_forward", false) # Don't force restart if already playing

func _execute_defense():
	# Choose defense based on opponent's potential attack height (simple example)
	# Needs more sophisticated prediction based on opponent animation
	var anim_to_play = &"standing_defense"
	# Placeholder: if opponent is low? use "crouching_defense"
	# if opponent is doing a low attack animation... anim_to_play = &"crouching_defense"
	_play_animation(anim_to_play)
	last_executed_decision = str(anim_to_play).capitalize() # Update with specific defense

func _execute_reposition():
	# Example: Move randomly left or right for a short time
	var move_dir = 1 if randf() > 0.5 else -1
	fighter.velocity.x = move_dir * movement_logic.speed * 0.7 # Move slightly slower
	_play_animation("walk_forward") # Play walk anim (sprite flips handled in BaseFighter)

	# Use a timer to stop repositioning
	var repo_timer = Timer.new()
	repo_timer.name = "RepositionTimer" # Give it a name to find later
	repo_timer.wait_time = randf_range(0.3, 0.8) # Reposition for 0.3-0.8 seconds
	repo_timer.one_shot = true
	repo_timer.connect("timeout", Callable(self, "_on_reposition_timeout"))
	add_child(repo_timer)
	repo_timer.start()
	# Make sure timer is removed when done
	repo_timer.connect("timeout", Callable(repo_timer,"queue_free"))


func _play_animation(anim_name: StringName, force_restart: bool = false):
	if not is_instance_valid(animation_player): return

	if animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name or force_restart:
			animation_player.play(anim_name)
			# Update the decision string when an animation is played
			if current_state != State.IDLE: # Don't override "Idle" if just playing idle anim
				# Capitalize and replace underscores for better display
				last_executed_decision = str(anim_name).capitalize().replace("_", " ") # <--- UPDATE DECISION HERE
	else:
		print("Warning: Animation '%s' not found for %s." % [anim_name, fighter.name])


# --- Signal Callbacks ---
func _on_animation_finished(anim_name: StringName):

	# Reset attacking flag if an attack animation finished
	if anim_name in ATTACK_ANIMATIONS:
		is_attacking = false
		# Decide next state after attacking
		if current_state == State.ATTACKING: # Ensure we were actually attacking
			if randf() < 0.3: # Chance to reposition after attack
				_change_state(State.REPOSITIONING)
			else:
				_change_state(State.IDLE) # Default to idle after attacking

	if anim_name == &"hurt":
		# Return to IDLE after recovering from damage (state change handles anim)
		if current_state == State.HURT:
			_change_state(State.IDLE)

	# If a non-looping defense animation finishes, transition back to idle
	# Check if animation exists and has loop property before accessing
	if anim_name in DEFENSE_ANIMATIONS and animation_player.has_animation(anim_name):
		var anim_resource = animation_player.get_animation(anim_name)
		if anim_resource and anim_resource.loop_mode == Animation.LOOP_NONE:
			if current_state == State.DEFENDING: # Only transition if still defending
				_change_state(State.IDLE)


func _on_defense_cooldown_timeout():
	can_defend = true
	# print("Defense cooldown finished.") # Debug

func _on_reposition_timeout():
	# Stop moving and go back to idle after repositioning
	if current_state == State.REPOSITIONING: # Ensure we are still repositioning
		fighter.velocity.x = 0
		_change_state(State.IDLE)
	# print("Reposition finished.") # Debug

func reset_ai_state():
	# Called externally (e.g., by Damaged system) if AI needs reset after being hit
	if current_state != State.HURT: # Don't interrupt the hurt state itself
		_change_state(State.IDLE)
	is_attacking = false
	# Reset timers maybe?
	if defense_cooldown_timer.is_stopped(): can_defend = true
	if get_node_or_null("RepositionTimer"):
		get_node("RepositionTimer").stop()


# --- Allow BaseFighter to notify this controller ---
func notify_damage_taken(_amount: int, _is_upper: bool, _defended: bool):
	# When the fighter takes damage, transition to HURT state
	if current_state != State.HURT: # Avoid re-triggering if already hurt
		_change_state(State.HURT)
