# rules.gd
extends Node
class_name Rules

@export var script_count : int = 20

var baseline = 0.5
var WMAX = 1.0
var WMIN = 0.1
var scaling_factor = 0.1    

var rules: Array = [
	# --- Original Rules (1-11) ---
	{
		"ruleID": 1, "prioritization": 1,
		"conditions": { "distance": { "op": ">=", "value": 100 } },
		"enemy_action_1": "walk_forward", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 2, "prioritization": 10,
		"conditions": { "distance": { "op": "<=", "value": 100 }},
		"enemy_action_1": "basic_kick", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 3, "prioritization": 11,
		"conditions": { "distance": { "op": "<=", "value": 83 } },
		"enemy_action_1": "basic_punch", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 4, "prioritization": 21,
		"conditions": { "player_anim": "basic_kick", "distance": { "op": ">=", "value": 100 }, "upper_hits_taken": { "op": ">=", "value": 1 } },
		"enemy_action_1": "standing_defense", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 5, "prioritization": 22,
		"conditions": { "player_anim": "basic_punch", "distance": { "op": ">=", "value": 83 }, "upper_hits_taken": { "op": ">=", "value": 1 } },
		"enemy_action_1": "standing_defense", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 6, "prioritization": 24,
		"conditions": { "player_anim": "crouch_punch", "distance": { "op": ">=", "value": 83 }, "lower_hits_taken": { "op": ">=", "value": 1 } },
		"enemy_action_1": "standing_defense", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 7, "prioritization": 23,
		"conditions": { "player_anim": "crouch_kick", "distance": { "op": ">=", "value": 83 }, "lower_hits_taken": { "op": ">=", "value": 1 } },
		"enemy_action_1": "standing_defense", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 8, "prioritization": 26,
		"conditions": { "player_anim": "crouch_punch", "distance": { "op": ">=", "value": 83 }, "lower_hits_taken": { "op": ">=", "value": 3 } },
		"enemy_action_1": "standing_defense", "enemy_action_2": "crouch_punch", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 9, "prioritization": 25,
		"conditions": { "player_anim": "crouch_kick", "distance": { "op": ">=", "value": 83 }, "lower_hits_taken": { "op": ">=", "value": 3 } },
		"enemy_action_1": "standing_defense", "enemy_action_2": "crouch_kick", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	#{
		#"ruleID": 10, "prioritization": 91,
		#"conditions": { "distance": { "op": ">=", "value": 83 }, "position": "map_border" },
		#"enemy_action_1": "jump", "enemy_action_2": "move_forward", "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	{
		"ruleID": 11, "prioritization": 28,
		"conditions": { "player_anim": "basic_punch", "distance": { "op": ">=", "value": 83 }, "upper_hits_taken": { "op": ">=", "value": 3 } },
		"enemy_action_1": "standing_defense", "enemy_action_2": "basic_punch", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 12, "prioritization": 27,
		"conditions": { "player_anim": "basic_kick", "distance": { "op": ">=", "value": 100 }, "upper_hits_taken": { "op": ">=", "value": 3 } },
		"enemy_action_1": "standing_defense", "enemy_action_2": "basic_kick", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 13, "prioritization": 2,
		"conditions": { "distance": { "op": "<=", "value": 80 }, "lower_hits_taken": { "op": ">=", "value": 3 } },
		"enemy_action_1": "walk_backward", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 14, "prioritization": 100,
		"conditions": { "player_anim": "idle" },
		"enemy_action_1": "standing_defense", "enemy_action_2": "idle", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	
	


]

var current_script: Array

func generate_and_update_script():
	for rule in rules:
		if rule.has("inScript"):
			rule["inScript"] = false
		else:
			printerr("Warning: Rule %s is missing 'inScript' key." % rule.get("ruleID", "UNKNOWN"))
			rule["inScript"] = false # Add it if missing

	if script_count <= 0:
		current_script = []
		print("Script count is zero or negative. No script generated.")
		return # Exit early

	# --- Step 2: Sort a *copy* of rules by weight (descending) ---
	var sorted_rules = rules.duplicate() # Shallow copy is sufficient
	sorted_rules.sort_custom(func(a, b): 
		# Sort descending. Handle missing 'weight' key gracefully.
		return a.get("weight", 0.0) > b.get("weight", 0.0)
	)

	# --- Step 3: Slice to get the top N rules ---
	var actual_count = min(script_count, sorted_rules.size())
	# Get the slice containing the dictionaries of the top rules
	var top_rules_slice = sorted_rules.slice(0, actual_count) 

	# --- Step 4: Modify the 'inScript' flag to true *within the sliced array* ---
	for rule_in_slice in top_rules_slice:
		if rule_in_slice.has("inScript"):
			rule_in_slice["inScript"] = true
		else:
			# This shouldn't happen if the original rules have the key, but handle defensively
			print("Warning: Rule %s in slice is missing 'inScript' key." % rule_in_slice.get("ruleID", "UNKNOWN"))
			rule_in_slice["inScript"] = true # Add and set to true

	# --- Step 5: Assign the modified slice to current_script ---
	current_script = top_rules_slice

	#print("Generated new script with %d rules. 'inScript' set to true within this script." % current_script.size())
	# Optional: Print the actual script for debugging (notice 'inScript' should be true)
	#print("New Script:", current_script)

func get_rules() -> Array:
	return rules

func get_DScript() -> Array:
		return current_script
	
func adjust_script_weights(fitness: float) -> void:
	var adjustment = (fitness - baseline) * scaling_factor
	var used_rules = []
	var unused_rules = []
	
	# Track changes for logging
	var weight_changes = {}
	
	# Classify rules
	for rule in current_script:
		if rule["wasUsed"]:
			used_rules.append(rule)
		else:
			unused_rules.append(rule)
	
	# Calculate compensation more safely
	var compensation = 0.0
	if unused_rules.size() > 0:
		compensation = (used_rules.size() * adjustment) / unused_rules.size()
	
	# Apply adjustments with clamping
	for rule in current_script:
		var original_weight = rule["weight"]
		
		if rule["wasUsed"]:
			rule["weight"] += adjustment
		else:
			rule["weight"] += compensation
		
		# Apply nonlinear clamping
		rule["weight"] = clamp(
			rule["weight"] * (1.0 + 0.1 * randf()),  # Add slight randomness
			WMIN, 
			WMAX
		)
		
		# Track meaningful changes
		if abs(original_weight - rule["weight"]) > 0.01:
			weight_changes[rule["ruleID"]] = {
				"old": original_weight,
				"new": rule["weight"]
			}
	
	# Log weight changes
	if weight_changes.size() > 0:
		print("=== Weight Adjustments ===")
		for rule_id in weight_changes:
			var change = weight_changes[rule_id]
			print("Rule %d: %.2f => %.2f" % [
				rule_id, 
				change["old"], 
				change["new"]
			])
	else:
		print("No significant weight changes this cycle")

func calculate_fitness(DS_lower_hits_taken: int, DS_upper_hits_taken: int, 
					  DS_upper_successful_attacks: int, DS_lower_successful_attacks: int,
					  DS_standing_defended: int, DS_crouching_defended: int, 
					  maxHP: int) -> float:
	# Enhanced fitness calculation with kick spam penalty
	var kick_ratio = float(DS_lower_successful_attacks) / max(DS_lower_successful_attacks + DS_upper_successful_attacks, 1)
	var kick_spam_penalty = -0.1 * kick_ratio
	
	var bot_dmg_taken = 10 * (DS_lower_hits_taken + DS_upper_hits_taken)
	var bot_dmg_output = 10 * (DS_upper_successful_attacks + DS_lower_successful_attacks)
	
	var dmg_score = (bot_dmg_output - bot_dmg_taken) / float(maxHP)
	var offensiveness = 0.002 * (DS_upper_successful_attacks + DS_lower_successful_attacks)
	var defensiveness = 0.003 * (DS_standing_defended + DS_crouching_defended)
	var penalties = -0.005 * (DS_lower_hits_taken + DS_upper_hits_taken)
	
	var raw = baseline + dmg_score + offensiveness + defensiveness + penalties + kick_spam_penalty
	var fitness = clamp(raw, 0.0, 1.0)
	
	print("\n=== Fitness Calculation ===")
	print("Damage Score: %.2f" % dmg_score)
	print("Offensiveness: %.2f" % offensiveness)
	print("Defensiveness: %.2f" % defensiveness)
	print("Penalties: %.2f" % penalties)
	print("Kick Spam Penalty: %.2f" % kick_spam_penalty)
	print("Final Fitness: %.2f\n" % fitness)
	
	return fitness
	
func update_rulebase() -> void:
	
	var script_dict := {}
	# Build dictionary from script using ruleID as key
	for r in current_script:
		script_dict[r["ruleID"]] = r
	# Update rulebase weights from script_dict
	for r in rules:
		if script_dict.has(r["ruleID"]):
			r["weight"] = script_dict[r["ruleID"]]["weight"]
