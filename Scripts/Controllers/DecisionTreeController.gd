# DecisionTreeController.gd
extends Node
class_name DecisionTreeController

# References
var fighter: CharacterBody2D # Reference to the BaseFighter node
var animation_player: AnimationPlayer
var opponent: CharacterBody2D
var opponent_animation_player: AnimationPlayer # Reference to opponent's anim player

# Gameplay Mechanics
var movement_logic: DummyMovement
var attack_logic: DummyAttack

# State Machine
enum State { IDLE, APPROACHING, ATTACKING, DEFENDING, REPOSITIONING, HURT }
var current_state: State = State.IDLE
var last_executed_decision: String = "Initializing" 

# Defense Logic
var can_defend: bool = true
var defense_cooldown_timer: Timer
const DEFENSE_COOLDOWN_TIME: float = 0.5 # Time in seconds before AI can defend again
const DEFENSE_PROBABILITY: float = 0.8 # 80% chance to defend when conditions met
const DEFENSE_TRIGGER_RANGE: float = 75.0 # How close opponent attack must be

# Attack Logic
var is_attacking: bool = false
const ATTACK_OPPORTUNITY_RANGE: float = 75.0
const CROUCH_ATTACK_RANGE: float = 55.0

const PROACTIVE_ATTACK_CHANCE: float = 0.15 # 15% chance per second
const REPOSITION_CHANCE: float = 0.15
const PROACTIVE_APPROACH_CHANCE: float = 0.3 # 30% chance per second
var idle_time: float = 0.0 # Track time spent idle

# Attack Animation Names
const ATTACK_ANIMATIONS: Array[StringName] = [
	&"basic_punch", &"basic_kick",
	&"crouch_punch", &"crouch_kick",
	&"heavy_punch", &"heavy_kick"
]
const DEFENSE_ANIMATIONS: Array[StringName] = [&"standing_defense", &"crouching_defense"]


# Initialization
func init_controller(fighter_node: CharacterBody2D, anim_player: AnimationPlayer, opp_node: CharacterBody2D):
	fighter = fighter_node
	animation_player = anim_player
	opponent = opp_node
	print("Decision Tree Controller Initialized for: ", fighter.name)

	if opponent and opponent.has_node("Animation"):
		opponent_animation_player = opponent.get_node("Animation")
	else:
		opponent_animation_player = opponent.get_node("Dummy_Animation")

	movement_logic = DummyMovement.new(animation_player, fighter, opponent)
	attack_logic = DummyAttack.new(fighter, opponent) 

	# Setup Timers
	defense_cooldown_timer = Timer.new()
	defense_cooldown_timer.wait_time = DEFENSE_COOLDOWN_TIME
	defense_cooldown_timer.one_shot = true
	defense_cooldown_timer.connect("timeout", Callable(self, "_on_defense_cooldown_timeout"))
	add_child(defense_cooldown_timer)

	if animation_player and not animation_player.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

	_change_state(State.IDLE) # Start in idle state


# Getter for the current decision
func get_current_decision() -> String:
	return last_executed_decision

# Core Logic
func _physics_process(delta):
	if not is_instance_valid(fighter) or not fighter.is_inside_tree():
		return
		
	if not is_instance_valid(opponent):
		_change_state(State.IDLE)
		return

	if not fighter.is_on_floor():
		fighter.velocity.y += fighter.gravity * delta
	else:
		fighter.is_jumping = false

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
				_decide_attack()
			elif distance < 50:
				_change_state(State.IDLE)
		State.ATTACKING:
			if animation_player.current_animation in ATTACK_ANIMATIONS:
				fighter.velocity.x = 0
				# fighter.velocity.y = 0 # Might interfere with gravity if mid-air attack
		State.DEFENDING:
			fighter.velocity.x = 0
			if _should_defend(): 
				_execute_defense()
			else:
				_change_state(State.IDLE)
		State.REPOSITIONING:
			# Movement handled by _execute_reposition
			# Timer will transition back to IDLE
			pass
		State.HURT:
			is_attacking = false 
			pass

	if current_state != State.ATTACKING and current_state != State.DEFENDING and current_state != State.HURT:
		fighter.move_and_slide()


# Decision Making
func _decide_action(delta):
	fighter.velocity.x = 0

	# 1. Check for defense opportunity (highest priority)
	if _should_defend() and can_defend and randf() < DEFENSE_PROBABILITY:
		_change_state(State.DEFENDING)
		return

	# 2. Check for attack opportunity
	var distance = fighter.global_position.distance_to(opponent.global_position)
	if distance <= ATTACK_OPPORTUNITY_RANGE:
		_decide_attack()
		if current_state == State.ATTACKING:
			return

	# 3. Proactive actions
	if idle_time > 0.2:
		var random_action = randf()
		if random_action < PROACTIVE_ATTACK_CHANCE * delta * 60:
			_decide_attack()
			if current_state == State.ATTACKING: return
		elif random_action < (PROACTIVE_ATTACK_CHANCE + PROACTIVE_APPROACH_CHANCE) * delta * 60:
			_change_state(State.APPROACHING)
			return
		elif random_action < (PROACTIVE_ATTACK_CHANCE + PROACTIVE_APPROACH_CHANCE + REPOSITION_CHANCE) * delta * 60:
			_change_state(State.REPOSITIONING)
			return

	# 4. If no other action, remain idle (or ensure idle anim plays)
	if current_state == State.IDLE and animation_player.current_animation != "idle":
		_play_animation("idle")


func _decide_attack():
	if is_attacking or current_state == State.HURT: return

	var attack_anim = &"" 
	# Add more complex logic: consider opponent state, health, distance, etc.
	# Example: Prioritize crouch attacks if opponent is crouching?
	# Example: Use heavy attacks occasionally or when opponent is vulnerable?

	var distance = fighter.global_position.distance_to(opponent.global_position)
	if distance < 55: 
		attack_anim = attack_logic.get_basic_attack_action()
	elif distance < ATTACK_OPPORTUNITY_RANGE: # Kick range
		attack_anim = &"basic_kick"

	if fighter.is_crouching and distance < CROUCH_ATTACK_RANGE:
		attack_anim = attack_logic.get_crouch_attack_action()

	if attack_anim != &"":
		_change_state(State.ATTACKING)
		_play_animation(attack_anim)


func _should_defend() -> bool:
	if not is_instance_valid(opponent_animation_player): return false

	var opp_anim_name = opponent_animation_player.current_animation
	if opp_anim_name in ATTACK_ANIMATIONS:
		# Check if the attack is close enough to warrant defense
		var distance = fighter.global_position.distance_to(opponent.global_position)
		if distance < DEFENSE_TRIGGER_RANGE:
			return true
	return false

# State Execution
func _change_state(new_state: State):
	if current_state == new_state: return # No change
	
	
	match current_state:
		State.IDLE:
			idle_time = 0.0
		State.APPROACHING:
			if new_state != State.ATTACKING:
				fighter.velocity.x = 0
				if new_state == State.IDLE: _play_animation("idle")
		State.ATTACKING:
			is_attacking = false
		State.DEFENDING:
			pass
		State.REPOSITIONING:
			if get_node_or_null("RepositionTimer"):
				get_node("RepositionTimer").stop()
			fighter.velocity.x = 0
			if new_state == State.IDLE: _play_animation("idle")


	current_state = new_state

	# Entry logic for new state
	match current_state:
		State.IDLE:
			last_executed_decision = "Idle"
			_play_animation("idle")
			fighter.velocity.x = 0
		State.APPROACHING:
			last_executed_decision = "Approaching"
			_play_animation("walk_forward") 
		State.ATTACKING:
			is_attacking = true
			# Animation and decision string set by _decide_attack -> _play_animation
		State.DEFENDING:
			last_executed_decision = "Defending" #
			_execute_defense()
			can_defend = false # Start cooldown
			defense_cooldown_timer.start()
		State.REPOSITIONING:
			last_executed_decision = "Repositioning"
			_execute_reposition()
		State.HURT:
			last_executed_decision = "Hurt"
			pass


func _execute_approach():
	var fighter_sprite
	fighter_sprite = fighter.get_node("Sprite") if fighter.has_node("Sprite") else fighter.get_node("AnimatedSprite2D")
	var direction_to_opponent = opponent.global_position.x - fighter.global_position.x
	if direction_to_opponent > 0:
		fighter.velocity.x = movement_logic.speed 
		fighter_sprite.flip_h = false # Ensure facing right
	elif direction_to_opponent < 0:
		fighter.velocity.x = -movement_logic.speed
		fighter_sprite.flip_h = true # Ensure facing left
	else:
		fighter.velocity.x = 0

	_play_animation("walk_forward", false) # Don't force restart if already playing

func _execute_defense():
	var anim_to_play = &"standing_defense"
	_play_animation(anim_to_play)
	last_executed_decision = str(anim_to_play).capitalize()

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
			if current_state != State.IDLE:
				last_executed_decision = str(anim_name).capitalize().replace("_", " ")
	else:
		print("Warning: Animation '%s' not found for %s." % [anim_name, fighter.name])


# Signal Callbacks
func _on_animation_finished(anim_name: StringName):

	if anim_name in ATTACK_ANIMATIONS:
		is_attacking = false
		if current_state == State.ATTACKING: # Ensure we were actually attacking
			if randf() < 0.3: # Chance to reposition after attack
				_change_state(State.REPOSITIONING)
			else:
				_change_state(State.IDLE) # Default to idle after attacking

	if anim_name == &"hurt":
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

func _on_reposition_timeout():
	# Stop moving and go back to idle after repositioning
	if current_state == State.REPOSITIONING:
		fighter.velocity.x = 0
		_change_state(State.IDLE)

func reset_ai_state():
	if current_state != State.HURT:
		_change_state(State.IDLE)
	is_attacking = false
	if defense_cooldown_timer.is_stopped(): can_defend = true
	if get_node_or_null("RepositionTimer"):
		get_node("RepositionTimer").stop()


# Allow BaseFighter to notify this controller
func notify_damage_taken(_amount: int, _is_upper: bool, _defended: bool):
	# When the fighter takes damage, transition to HURT state
	if current_state != State.HURT:
		_change_state(State.HURT)
