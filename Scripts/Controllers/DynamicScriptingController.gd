# DynamicScriptingController.gd
extends Node
class_name DynamicScriptingController

# References
var fighter: CharacterBody2D # Reference to the BaseFighter node
var animation_player: AnimationPlayer
var opponent: CharacterBody2D
var opponent_animation_player: AnimationPlayer
var opponent_HP: ProgressBar

# DS Component Instances
var rule_engine: ScriptCreation # Instance of DS_script.txt logic
var rules_base: Rules           # Instance of rules.txt logic
var latest_script: Array = []   # The currently executing action sequence

var current_rule_id: int = -1

# AIConfig
var ai_config: AIConfig

# State/Config
@export var update_interval : float = 4.0 # How often to re-evaluate rules/script
var _update_timer: Timer
var speed = 150 # Movement speed for AI
var is_hurt: bool = false
var last_hurt_time: float = 0.0
const HURT_RECOVERY_TIME: float = 0.4

# ⚡ New action queue variables
var action_queue: Array = []
var is_performing_action: bool = false

# Parameters
var previous_parameters = {}

# Logging
const LOG_FILE_PATH = "res://training.txt"
const Fitness_Log_Path = "res://fitness_record.txt"

const LOG_SCHEMA_VERSION = 1  # Increment when log structure changes

# Fitness Record
#var fitness_record: Array = []

func init_controller(fighter_node: CharacterBody2D, anim_player: AnimationPlayer, opp_node: CharacterBody2D, playerHP: ProgressBar, _config: AIConfig):
	fighter = fighter_node
	animation_player = anim_player
	opponent = opp_node
	opponent_HP = playerHP
	
	ai_config = _config

	if is_instance_valid(opponent) and (opponent.has_node("Animation") or opponent.has_node("Dummy_Animation")): # Adjust path if needed
		opponent_animation_player = opponent.get_node("Animation") if opponent.has_node("Animation") else opponent.get_node("Dummy_Animation")
	if is_instance_valid(opponent) and (opponent.has_node("PlayerHP") or opponent.has_node("DummyHP")):
		opponent_HP = opponent.get_node("PlayerHP") if opponent.has_node("PlayerHP") else opponent.get_node("DummyHP")
	else:
		print("DSController: Could not find opponent AnimationPlayer")
		# Decide how to handle this - maybe disable rule conditions based on opponent anim?
		
	if fighter.hitbox_container.has_signal("area_entered"):
		fighter.hitbox_container.connect("area_entered", Callable(self, "_on_hitbox_contact"))

	# --- Instantiate DS components ---
	if FileAccess.file_exists("res://Scripts/rules.gd"):
		var RulesClass = load("res://Scripts/rules.gd")
		if RulesClass:
			rules_base = RulesClass.new()
			rules_base.initialize_rules()
			# Pass fighter reference if Rules need it (e.g., for fitness calc access)
			# rules_base.set_fighter_reference(fighter)
		else: print("DSController: Failed to load Rules.gd")
	else: print("DSController: Rules.gd not found.")

	if FileAccess.file_exists("res://Scripts/DS_script.gd"):
		var ScriptCreationClass = load("res://Scripts/DS_script.gd")
		if ScriptCreationClass:
			# ScriptCreation needs opponent and opponent's anim player
			if is_instance_valid(opponent) and is_instance_valid(opponent_animation_player) and is_instance_valid(animation_player):
				rule_engine = ScriptCreationClass.new(opponent, opponent_animation_player, animation_player)
				rule_engine.set_ai_reference(fighter) # Pass self-reference
				fighter.active_controller = self 
			else:
				print("DSController: Missing references for ScriptCreation init.")
				return # Cannot proceed
		else: print("DSController: Failed to load ScriptCreation.gd")
	else: print("DSController: ScriptCreation.gd not found.")


	# --- Setup Update Timer (From DS_ryu.txt _ready) ---
	_update_timer = Timer.new()
	_update_timer.wait_time = update_interval
	_update_timer.one_shot = false # Make it repeat
	_update_timer.timeout.connect(_on_timer_timeout)
	add_child(_update_timer) # Add timer to the scene tree
	_update_timer.start()

	# --- Initial Script Generation ---
	if is_instance_valid(rules_base):
		get_latest_script()
		append_script_to_log("Initial Script", )
		log_game_info()

	if animation_player and not animation_player.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))
	reset_ai_state()
	#print("Dynamic Scripting Controller Initialized for: ", fighter.name)

func reset_ai_state():
	is_hurt = false
	fighter.velocity = Vector2.ZERO

func _physics_process(_delta):
	if not is_instance_valid(fighter) or not is_instance_valid(rule_engine):
		return
	
	if is_hurt:
		if Time.get_ticks_msec() - last_hurt_time > HURT_RECOVERY_TIME * 1000:
			reset_ai_state()
		return 
	
	# Only process next action if not performing one and queue exists
	if not is_performing_action:
		if action_queue.size() > 0:
			var action_data = action_queue.pop_front()
			is_performing_action = true
			rule_engine._execute_single_action(action_data["action"])
			
			# Handle delay without blocking physics process
			if action_data["delay"] > 0:
				var timer = get_tree().create_timer(action_data["delay"])
				timer.timeout.connect(_on_action_delay_completed.bind(action_data["delay"]))
		else:
			# Fallback to regular evaluation if no queued actions
			rule_engine.evaluate_and_execute(latest_script)

func _on_action_delay_completed(delay: float):
	is_performing_action = false
	
# Add unified hitbox handler
func _on_hitbox_contact(area: Area2D):
	if area.get_parent() == opponent and current_rule_id != -1:
		record_rule_success()

func queue_actions(actions: Array):
	action_queue.clear()
	is_performing_action = false
	current_rule_id = -1  # <-- Reset current_rule_id when queueing new actions

	# Convert all actions to dictionary format
	for action in actions:
		if action is String:
			action_queue.append({"action": action, "delay": 0.1})
		elif action is Dictionary:
			action_queue.append(action)


func _on_animation_finished(anim_name: String):
	if anim_name == "hurt":
		animation_player.play("idle")
		reset_ai_state()
	else:
		# ⚡ Allow next action in queue
		is_performing_action = false

func _on_timer_timeout():
	if not is_instance_valid(rules_base):
		print("Rules system not initialized!")
		return

	# Add rule validation
	if rules_base.get_rules().is_empty():
		print("No rules available in rulebase!")
		return
		
	var ai_hp = fighter.get_health()
	var player_hp = opponent.get_health()

		
	if not is_instance_valid(fighter) or not is_instance_valid(rules_base): 
		return

	print("\n=== DS Update Cycle ===")
	print("Current HP: %d/%d" % [fighter.health, fighter.max_health])
	
	# 1. Calculate fitness FIRST
	var fitness = calculate_fitness()
	print("Adapting with fitness: %.2f" % fitness)

	# 2. Apply weight adjustments based on fitness
	rules_base.adjust_script_weights(fitness, ai_hp, player_hp)
	
	# 3. Update rule priorities before generating new script
	rules_base.update_rule_priorities()
	
	# 4. Generate new script AFTER adjustments
	rules_base.generate_script()
	var active_script = rules_base.get_DScript()
	
	# 5. Update internal state
	get_total_weights()
	get_latest_script()
	
	# 6. Logging and cleanup
	log_game_info()
	append_script_to_log()
	reset_counters()

	# (Optional) Debug output
	print("New script contains %d rules" % active_script.size())

func get_total_weights():
	var rules = rules_base.get_rules()
	var total_weight = 0
	for rule in rules:
		total_weight += rule["weight"]
	print("Total Weights: ", total_weight)

# In DynamicScriptingController.gd
func log_game_info():
	# Get fresh data from the rule system
	var current_script = rules_base.get_DScript()
	var executed_rules = rule_engine.get_executed_rules()
	
	# Log current active script
	_log_script_info(current_script, "CURRENT ACTIVE")
	
	# Log executed rules
	_log_script_info(executed_rules, "EXECUTED")
	
	# Additional weight history
	print("\n=== WEIGHT CHANGE HISTORY (LAST 5) ===")
	var history = rules_base.weight_history.slice(-5)
	for entry in history:
		print("[%s] R%d: %.2f → %.2f (%s)" % [
			entry.timestamp.substr(11), # Show only time
			entry.ruleID,
			entry.old_weight,
			entry.new_weight,
			entry.reason
		])
	print("")

func _log_script_info(script: Array, header: String):
	# Transform script data for formatting
	var formatted_script = []
	for rule in script:
		formatted_script.append({
			"ruleID": rule.ruleID,
			"weight": rule.weight,
			"inScript": rule.in_script,
			"enemy_action": rule.enemy_action
		})
	
	log_info(formatted_script, header)

# Modified logging
func log_info(script, header) -> void:
	print("\n====== %s Rules ======" % header)
	print("ID | Action            | Weight | Uses  | Success%")
	print("---|-------------------|--------|-------|---------")
	for rule in script:
		var stats = rules_base.rule_success_counts[rule.ruleID]
		var success_pct = stats.hits / float(max(stats.uses, 1)) * 100
		print("%2d | %-17s | %5.2f | %5d | %6.1f%%" % [
			rule.ruleID,
			rule.enemy_action,
			rule.weight,
			stats.uses,
			success_pct
		])
		
func record_rule_success():
	if current_rule_id != -1:
		rules_base.record_rule_success(current_rule_id)
		print("Recorded success for rule ", current_rule_id)

func _process_action(rule: Dictionary) -> String:
	var action = rule.get("enemy_action", "unknown")
	if action is Array:
		return " → ".join(action)
	return action.lpad(16).substr(0, 16)
	
func process_action(rule: Dictionary) -> String:
	var processedActions = ''
	var actions = rule["enemy_action"]
	for action in actions:
		processedActions =  str(processedActions) + str(action)
	return processedActions

func reset_counters():
	# Reset numerical counters
	fighter.lower_hits_taken = 0
	fighter.upper_hits_taken = 0
	fighter.lower_attacks_landed = 0
	fighter.upper_attacks_landed = 0
	fighter.standing_defenses = 0
	fighter.crouching_defenses = 0
	
	# Force label update with fresh values
	fighter._update_stats_text()

func get_parameters():
	previous_parameters = {
		"lower_hits": fighter.lower_hits_taken,
		"upper_hits": fighter.upper_hits_taken,
		"upper_attacks": fighter.upper_attacks_landed,
		"lower_attacks": fighter.lower_attacks_landed,
		"standing_defense": fighter.standing_defenses,
		"crouching_defense": fighter.crouching_defenses,
		"current_hp": opponent_HP.value # 👈 Add this line
	}
	#print("Stored parameters: %s" % previous_parameters)	

func calculate_fitness() -> float:
	if not is_instance_valid(fighter) or not is_instance_valid(rules_base): return 0.0

	# Use the formula from rules.txt, accessing counters from BaseFighter
	var baseline = ai_config.baseline_fitness # Get baseline from Rules instance
	# Damage Score - Requires tracking damage dealt/taken in the interval. Not directly available.
	# Let's simplify fitness for now based only on hits/defense counts from BaseFighter.
	# You might need to enhance BaseFighter or this controller to track damage delta per interval.
	var dmg_score = 0.0 # Placeholder

	var offensiveness = (0.002 * fighter.upper_attacks_landed + 0.002 * fighter.lower_attacks_landed)
	var defensiveness = (0.003 * fighter.standing_defenses + 0.003 * fighter.crouching_defenses)
	var penalties = (-0.005 * fighter.lower_hits_taken + -0.005 * fighter.upper_hits_taken)

	var raw_fitness = baseline + dmg_score + offensiveness + defensiveness + penalties
	var fitness = clampf(raw_fitness, 0.0, 1.0) # Clamp between 0 and 1
	print("DS Fitness calculated: ", fitness)
	append_fitness_to_log(fitness)
	return fitness


# --- Script Generation (From DS_ryu.txt) ---
func get_latest_script() -> void:
	if not is_instance_valid(rules_base): return
	# Assuming these methods exist in Rules.gd based on original DS_ryu.txt
	if rules_base.has_method("generate_script") and rules_base.has_method("get_DScript"):
		rules_base.generate_script()
		latest_script = rules_base.get_DScript()
		# Pass the latest script to the rule engine if it needs it?
		# if is_instance_valid(rule_engine) and rule_engine.has_method("set_active_script"):
		#     rule_engine.set_active_script(latest_script)
	else:
		print("DSController: Rules class missing script generation methods.")

# Logging
func append_script_to_log(context: String = "Update") -> void:
	if not is_instance_valid(rules_base) or not is_instance_valid(rule_engine): 
		return
	
	# 1. Read existing log data
	var log_data = {
		"version": LOG_SCHEMA_VERSION,
		"scripts": []
	}
	
	var file = FileAccess.open(LOG_FILE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var err = json.parse(file.get_as_text())
		if err == OK:
			log_data = json.data
		file.close()

	# 2. Prepare new entry
	var new_entry = {
		"timestamp": Time.get_unix_time_from_system(),
		"parameters": get_current_parameters(),
		"scripts_generated": get_script_data(),
		"rules_used": get_executed_rules_data()
	}

	# 3. Schema version check
	if _detect_schema_change(log_data, new_entry):
		log_data["version"] += 1

	# 4. Append new entry
	log_data["scripts"].append(new_entry)

	# 5. Write updated data
	file = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(log_data, "\t"))
		file.close()

# Helper functions
func get_current_parameters() -> Dictionary:
	return {
		"lower_hits": fighter.lower_hits_taken,
		"upper_hits": fighter.upper_hits_taken,
		"attacks_landed": {
			"upper": fighter.upper_attacks_landed,
			"lower": fighter.lower_attacks_landed
		},
		"defenses": {
			"standing": fighter.standing_defenses,
			"crouching": fighter.crouching_defenses
		},
		"current_hp": fighter.health
	}

func get_script_data() -> Dictionary:
	var script_data = []
	for rule in latest_script:
		script_data.append({
			"rule_id": rule.get("ruleID", -1),
			"action": rule.get("enemy_action", "unknown"),
			"weight": rule.get("weight", 0.0)
		})
	return {"rules": script_data}
	
func get_executed_rules_data() -> Dictionary:
	var executed = []
	var rules = rule_engine.get_executed_rules()
	for rule in rules:
		executed.append({
			"rule_id": rule.get("ruleID", -1),
			"action": rule.get("enemy_action", "unknown"),
			"timestamp": Time.get_unix_time_from_system()
		})
	return {"count": executed.size(), "rules": executed}

func _detect_schema_change(old_data: Dictionary, new_entry: Dictionary) -> bool:
	# Compare keys with previous entry
	if old_data["scripts"].is_empty():
		return false
		
	var last_entry = old_data["scripts"][-1]
	return (
		last_entry["parameters"].keys() != new_entry["parameters"].keys() ||
		last_entry["scripts_generated"].keys() != new_entry["scripts_generated"].keys() ||
		last_entry["rules_used"].keys() != new_entry["rules_used"].keys()
	)
		
func get_executed_rule() -> String:
	if is_instance_valid(rule_engine) and rule_engine.has_method("get_current_rule"):
		return rule_engine.get_current_rule()
	else: 
		return "Failed to get rule"
		
# --- Allow BaseFighter to notify this controller ---
func notify_damage_taken(_amount: int, _is_upper: bool, _defended: bool):
	# Simply track hurt state without duplicating knockback logic
	is_hurt = true
	last_hurt_time = Time.get_ticks_msec()
	fighter.velocity = Vector2.ZERO

func append_fitness_to_log(fitness: float):
	var file = FileAccess.open(Fitness_Log_Path, FileAccess.READ_WRITE)
	
	if file: # Always good to check
		file.seek_end() # Move to the end so we append, not overwrite
		
		var timestamp = Time.get_datetime_string_from_system(false, true)
		file.store_line("Timestamp: %s" % [timestamp])
		file.store_line("Fitness: %.4f" % fitness)
		file.store_line("") # Optional: adds an empty line for clarity
	else:
		push_error("Failed to open fitness log file!")
