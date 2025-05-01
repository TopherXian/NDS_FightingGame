# DynamicScriptingController.gd
extends Node
class_name DynamicScriptingController

# --- References (Set by BaseFighter) ---
var fighter: CharacterBody2D # Reference to the BaseFighter node
var animation_player: AnimationPlayer
var opponent: CharacterBody2D
var opponent_animation_player: AnimationPlayer
var opponent_HP: ProgressBar

# --- DS Component Instances (From DS_ryu.txt) ---
var rule_engine: ScriptCreation # Instance of DS_script.txt logic
var rules_base: Rules           # Instance of rules.txt logic
var latest_script: Array = []   # The currently executing action sequence

# --- State/Config (From DS_ryu.txt) ---
@export var update_interval : float = 4.0 # How often to re-evaluate rules/script
var _update_timer: Timer
var speed = 150 # Movement speed for AI

# --- Parameters (For training.txt) ---
var previous_parameters = {}

# --- Logging ---
const LOG_FILE_PATH = "res://training.txt"


func init_controller(fighter_node: CharacterBody2D, anim_player: AnimationPlayer, opp_node: CharacterBody2D, playerHP: ProgressBar):
	fighter = fighter_node
	animation_player = anim_player
	opponent = opp_node
	opponent_HP = playerHP
	print(fighter)
	print(opponent)

	if is_instance_valid(opponent) and (opponent.has_node("Animation") or opponent.has_node("Dummy_Animation")): # Adjust path if needed
		opponent_animation_player = opponent.get_node("Animation") if opponent.has_node("Animation") else opponent.get_node("Dummy_Animation")
	if is_instance_valid(opponent) and (opponent.has_node("PlayerHP") or opponent.has_node("DummyHP")):
		opponent_HP = opponent.get_node("PlayerHP") if opponent.has_node("PlayerHP") else opponent.get_node("DummyHP")
	else:
		print("DSController: Could not find opponent AnimationPlayer")
		# Decide how to handle this - maybe disable rule conditions based on opponent anim?

	# --- Instantiate DS components ---
	if FileAccess.file_exists("res://Scripts/rules.gd"):
		var RulesClass = load("res://Scripts/rules.gd")
		if RulesClass:
			rules_base = RulesClass.new()
			# Pass fighter reference if Rules need it (e.g., for fitness calc access)
			# rules_base.set_fighter_reference(fighter)
		else: printerr("DSController: Failed to load Rules.gd")
	else: printerr("DSController: Rules.gd not found.")

	if FileAccess.file_exists("res://Scripts/DS_script.gd"):
		var ScriptCreationClass = load("res://Scripts/DS_script.gd")
		if ScriptCreationClass:
			# ScriptCreation needs opponent and opponent's anim player
			if is_instance_valid(opponent) and is_instance_valid(opponent_animation_player) and is_instance_valid(animation_player):
				rule_engine = ScriptCreationClass.new(opponent, opponent_animation_player, animation_player)
				rule_engine.set_ai_reference(fighter) # Pass self-reference
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

	#print("Dynamic Scripting Controller Initialized for: ", fighter.name)


func _physics_process(_delta):
	if not is_instance_valid(fighter): return
	if not is_instance_valid(rule_engine): return # Cannot execute without engine
	
	# --- Execute current script step ---
	# The original DS_ryu didn't show *how* the script array was executed frame-by-frame.
	# ScriptCreation.evaluate_and_execute seems designed to pick *one* action based on current state.
	# Let's assume evaluate_and_execute is called each frame to determine the best action *now*.
	if is_instance_valid(rules_base):
		# Original ScriptCreation.evaluate_and_execute took the rules array.
		# It should probably take the *generated script* array or just evaluate rules directly.
		# Let's adapt it to evaluate the rules from the Rules class instance.
		if rules_base.has_method("get_rules"):
			var all_rules = rules_base.get_rules() # Assume Rules.gd has this method
			rule_engine.evaluate_and_execute(all_rules) # Pass all rules for evaluation
		else:
			printerr("DSController: Rules class missing get_all_rules() method.")

	# Note: ScriptCreation.evaluate_and_execute now directly modifies fighter.velocity
	# and calls animation_player.play() based on the chosen rule action.
	# BaseFighter handles gravity and move_and_slide.


# --- Timer Timeout (From DS_ryu.txt) ---
func _on_timer_timeout():
	if not is_instance_valid(fighter) or not is_instance_valid(rules_base): return

	print("\n=== DS Update Cycle ===")
	print("Current HP: %d/%d" % [fighter.health, fighter.max_health])
	
	# Calculate and log fitness
	var fitness = calculate_fitness()
	print("Adapting with fitness: %.2f" % fitness)
	
	# Weight adjustment
	rules_base.adjust_script_weights(fitness)
	rules_base.update_rulebase()
	
	# Generate new script with logging
	get_total_weights()
	get_latest_script()
	log_game_info()
	
	# Reset counters
	reset_counters()

func get_total_weights():
	var rules = rules_base.get_rules()
	var total_weight = 0
	for rule in rules:
		total_weight += rule["weight"]
	print("Total Weights: ", total_weight)

func log_game_info():
	print("\n=========== New Cycle ===========")
	var script_rules = rules_base.get_DScript()
	var executed_rules = rule_engine.get_executed_rules()
	
	#Format and log generated script
	log_info(script_rules, "Newly Generated")
	#Format and log executed rules
	log_info(executed_rules, "Executed")
	
	if script_rules.is_empty():
		print("No active rules in script!")
		return
	
	# Sort by weight descending
	script_rules.sort_custom(func(a, b): return a["weight"] > b["weight"])
	
	# Print top 5 rules
	print("Top 5 Highest Weights:")
	for i in range(min(5, script_rules.size())):
		var rule = script_rules[i]
		print("%d. [Rule %d] %s (Weight: %.2f)" % [
			i+1,
			rule["ruleID"],
			rule["enemy_action"], 
			rule["weight"]
		])
	
	# Action diversity	
	#var actions = {}
	#for rule in script_rules:
		#var action = rule["enemy_action"]
		#actions[action] = actions.get(action, 0) + 1
	
	#print("\nAction Distribution:")
	#for action in actions:
		#print("- %s: %d%%" % [
			#action, 
			#round(float(actions[action]) / script_rules.size() * 100)
		#])
#LOG EXECUTED RULES 
func log_info(script, header) -> void:
	print("\n====== %s Rules ======" % header)
	print("ID | Action            | Weight | In Script")
	print("---|-------------------|--------|----------")
	
	for rule in script:
		var rule_id = str(rule.get("ruleID", "??")).rpad(3)
		var action = str(rule.get("enemy_action", "unknown")).rpad(17)
		var weight = "%.2f" % rule.get("weight", 0.0)
		var in_script = "✓" if rule.get("inScript", false) else "✗"
		
		print("%s | %s | %s   | %s" % [rule_id, action, weight, in_script])
	
	print("Total rules: %d\n" % script.size())

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
	var baseline = rules_base.baseline # Get baseline from Rules instance
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
	return fitness


# --- Script Generation (From DS_ryu.txt) ---
func get_latest_script() -> void:
	if not is_instance_valid(rules_base): return
	# Assuming these methods exist in Rules.gd based on original DS_ryu.txt
	if rules_base.has_method("generate_and_update_script") and rules_base.has_method("get_DScript"):
		rules_base.generate_and_update_script()
		latest_script = rules_base.get_DScript()
		# Pass the latest script to the rule engine if it needs it?
		# if is_instance_valid(rule_engine) and rule_engine.has_method("set_active_script"):
		#     rule_engine.set_active_script(latest_script)
	else:
		print("DSController: Rules class missing script generation methods.")

# --- Logging (From DS_ryu.txt, modified slightly) ---
func append_script_to_log(context: String = "Update") -> void:
	if not is_instance_valid(rules_base) or not is_instance_valid(rule_engine): return
	
	var stringified_parameters = JSON.stringify(previous_parameters)
	var file = FileAccess.open(LOG_FILE_PATH, FileAccess.READ_WRITE)
	if file:
		file.seek_end() # Move to the end to append
		var timestamp = Time.get_datetime_string_from_system(false, true)
		
		file.store_line("--- Parameters: %s ---" % stringified_parameters) # 👈 Write parameters here
		file.store_line("--- Script Generated (%s) | Timestamp: %s ---" % [context, timestamp])

		# Log the generated script itself
		if not latest_script.is_empty():
			# Attempt to stringify, handle potential errors if complex objects
			var stringified_script = JSON.stringify(latest_script, "\t")
			if stringified_script:
				file.store_line("Generated Script:")
				file.store_line(stringified_script)
			else:
				file.store_line("Generated Script: [Could not stringify]")

		# Log the rules executed by the rule engine (if tracked)
		if rule_engine.has_method("get_executed_rules"):
			var executed_rules = rule_engine.get_executed_rules()
			var stringified_executed = JSON.stringify(executed_rules, "\t")
			if stringified_executed:
				file.store_line("Rules Executed in Last Cycle:")
				file.store_line(stringified_executed)
				# Optionally clear executed rules history in rule_engine
				if rule_engine.has_method("clear_executed_rules"):
					rule_engine.clear_executed_rules()
			else:
				file.store_line("Rules Executed: [Could not stringify or none executed]")

		file.store_line("--- End Log Entry ---")
		file.close()
	else:
		print("Failed to open log file: ", LOG_FILE_PATH)

# --- Allow BaseFighter to notify this controller ---
func notify_damage_taken(_amount: int, _is_upper: bool, _defended: bool):
	# AI can use this information immediately if needed
	# print("DSController notified: Took ", amount, " damage. Upper: ", is_upper, " Defended: ", defended)
	pass
