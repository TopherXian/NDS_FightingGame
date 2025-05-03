# rules.gd
extends Node
class_name Rules

@export var script_count : int = 35

var baseline = 0.5
var WMAX = 1.0
var WMIN = 0.1
var scaling_factor = 0.1    

var rules = [
	{
		"ruleID": 1,
		"conditions": { "player_anim": "walk_forward", "distance": { "op": ">=", "value": 80 }, "upper_hits": { "op": ">=", "value": 1 }, "lower_hits": { "op": "<", "value": 1 } },
		"enemy_action": "walk_forward", "weight": 0.9, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 2,
		"conditions": { "player_anim": "walk_forward", "distance": { "op": "<=", "value": 70 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 0 } },
		"enemy_action": "basic_kick", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 3,
		"conditions": { "player_anim": "basic_punch", "distance": { "op": "<=", "value": 40 }, "upper_hits": { "op": ">=", "value": 3 }, "lower_hits": { "op": ">=", "value": 0 } },
		"enemy_action": "walk_backward", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 4,
		"conditions": { "player_anim": "basic_kick", "distance": { "op": "<=", "value": 80 }, "upper_hits": { "op": ">=", "value": 2 }, "lower_hits": { "op": ">=", "value": 0 } },
		"enemy_action": "standing_defense", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 5,
		"conditions": { "player_anim": "basic_punch", "distance": { "op": "<=", "value": 65 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 0 } },
		"enemy_action": "basic_kick", "weight": 0.85, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 6,
		"conditions": { "player_anim": "crouch_kick", "distance": { "op": "<=", "value": 90 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 1 } },
		"enemy_action": "crouch_defense", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 7,
		"conditions": { "player_anim": "crouch_punch", "distance": { "op": "<=", "value": 70 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 1 } },
		"enemy_action": "crouch_defense", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 8,
		"conditions": { "player_anim": "crouch_kick", "distance": { "op": ">=", "value": 90 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 1 } },
		"enemy_action": "crouch_defense", "weight": 0.7, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 9,
		"conditions": { "player_anim": "crouch_kick", "distance": { "op": "<=", "value": 90 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 1 } },
		"enemy_action": "jump", "weight": 0.85, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 10,
		"conditions": { "player_anim": "jump", "distance": { "op": "<=", "value": 90 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 0 } },
		"enemy_action": "basic_kick", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 11,
		"conditions": { "player_anim": "jump", "distance": { "op": "<=", "value": 60 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 0 } },
		"enemy_action": "basic_punch", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 12,
		"conditions": { "player_anim": "walk_backward", "distance": { "op": ">=", "value": 60 }, "upper_hits": { "op": "<=", "value": 1 }, "lower_hits": { "op": "<=", "value": 1 } },
		"enemy_action": "walk_forward", "weight": 0.85, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 13,
		"conditions": { "player_anim": "standing_defense", "distance": { "op": "<=", "value": 60 }, "upper_hits": { "op": ">=", "value": 1 }, "lower_hits": { "op": "<=", "value": 1 } },
		"enemy_action": "basic_punch", "weight": 0.85, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 14,
		"conditions": { "player_anim": "crouch_defense", "distance": { "op": "<=", "value": 80 }, "upper_hits": { "op": "<=", "value": 1 }, "lower_hits": { "op": ">=", "value": 1 } },
		"enemy_action": "basic_kick", "weight": 0.9, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 15,
		"conditions": { "player_anim": "walk_forward", "distance": { "op": ">=", "value": 130 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "jump", "weight": 0.6, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 16,
		"conditions": { "player_anim": "basic_punch", "distance": { "op": "<=", "value": 50 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "basic_punch", "weight": 0.85, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 17,
		"conditions": { "player_anim": "basic_kick", "distance": { "op": "<=", "value": 100 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "walk_backward", "weight": 0.85, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 18,
		"conditions": { "player_anim": "jump", "distance": { "op": ">=", "value": 110 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "walk_forward", "weight": 0.7, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 19,
		"conditions": { "player_anim": "crouch_punch", "distance": { "op": "<=", "value": 60 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": ">=", "value": 3 } },
		"enemy_action": "jump", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 20,
		"conditions": { "player_anim": "walk_forward", "distance": { "op": "<=", "value": 110 }, "upper_hits": { "op": ">=", "value": 2 }, "lower_hits": { "op": "<=", "value": 1 } },
		"enemy_action": "standing_defense", "weight": 0.9, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 21,
		"conditions": { "player_anim": "standing_defense", "distance": { "op": "<=", "value": 40 }, "upper_hits": { "op": ">=", "value": 3 }, "lower_hits": { "op": ">=", "value": 2 } },
		"enemy_action": "walk_backward", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 22,
		"conditions": { "player_anim": "basic_kick", "distance": { "op": ">=", "value": 120 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "walk_forward", "weight": 0.85, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 23,
		"conditions": { "player_anim": "walk_forward", "distance": { "op": "<=", "value": 50 }, "upper_hits": { "op": ">=", "value": 1 }, "lower_hits": { "op": ">=", "value": 2 } },
		"enemy_action": "crouch_defense", "weight": 0.9, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 24,
		"conditions": { "player_anim": "walk_backward", "distance": { "op": ">=", "value": 140 }, "upper_hits": { "op": "<=", "value": 1 }, "lower_hits": { "op": "<=", "value": 1 } },
		"enemy_action": "jump", "weight": 0.7, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 25,
		"conditions": { "player_anim": "jump", "distance": { "op": "<=", "value": 60 }, "upper_hits": { "op": ">=", "value": 2 }, "lower_hits": { "op": ">=", "value": 1 } },
		"enemy_action": "standing_defense", "weight": 0.85, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 26,
		"conditions": { "player_anim": "walk_forward", "distance": { "op": "<=", "value": 90 }, "upper_hits": { "op": "<=", "value": 1 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "basic_punch", "weight": 0.85, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 27,
		"conditions": { "player_anim": "basic_kick", "distance": { "op": "<=", "value": 110 }, "upper_hits": { "op": ">=", "value": 1 }, "lower_hits": { "op": ">=", "value": 2 } },
		"enemy_action": "crouch_defense", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 28,
		"conditions": { "player_anim": "crouch_punch", "distance": { "op": "<=", "value": 80 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": ">=", "value": 2 } },
		"enemy_action": "basic_kick", "weight": 0.9, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 29,
		"conditions": { "player_anim": "jump", "distance": { "op": "<=", "value": 50 }, "upper_hits": { "op": ">=", "value": 1 }, "lower_hits": { "op": ">=", "value": 1 } },
		"enemy_action": "walk_backward", "weight": 0.85, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 30,
		"conditions": { "player_anim": "walk_forward", "distance": { "op": "<=", "value": 40 }, "upper_hits": { "op": "<=", "value": 2 }, "lower_hits": { "op": "<=", "value": 1 } },
		"enemy_action": "basic_kick", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 31,
		"conditions": { "player_anim": "crouch_defense", "distance": { "op": "<=", "value": 50 }, "upper_hits": { "op": ">=", "value": 2 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "basic_punch", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 32,
		"conditions": { "player_anim": "walk_backward", "distance": { "op": "<=", "value": 50 }, "upper_hits": { "op": ">=", "value": 1 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "basic_kick", "weight": 0.85, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 33,
		"conditions": { "player_anim": "jump", "distance": { "op": ">=", "value": 120 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "walk_forward", "weight": 0.6, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 34,
		"conditions": { "player_anim": "basic_kick", "distance": { "op": "<=", "value": 60 }, "upper_hits": { "op": ">=", "value": 2 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "standing_defense", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 35,
		"conditions": { "player_anim": "walk_forward", "distance": { "op": ">=", "value": 150 }, "upper_hits": { "op": "<=", "value": 1 }, "lower_hits": { "op": "<=", "value": 1 } },
		"enemy_action": "jump", "weight": 0.7, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 36,
		"conditions": { "player_anim": "basic_punch", "distance": { "op": "<=", "value": 45 }, "upper_hits": { "op": ">=", "value": 1 }, "lower_hits": { "op": ">=", "value": 0 } },
		"enemy_action": "walk_backward", "weight": 0.92, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 37,
		"conditions": { "player_anim": "walk_backward", "distance": { "op": "<=", "value": 70 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "basic_punch", "weight": 0.88, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 38,
		"conditions": { "player_anim": "walk_forward", "distance": { "op": "<=", "value": 75 }, "upper_hits": { "op": ">=", "value": 3 }, "lower_hits": { "op": "<=", "value": 1 } },
		"enemy_action": "walk_backward", "weight": 0.87, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 39,
		"conditions": { "player_anim": "basic_punch", "distance": { "op": "<=", "value": 65 }, "upper_hits": { "op": ">=", "value": 2 }, "lower_hits": { "op": "<=", "value": 1 } },
		"enemy_action": "standing_defense", "weight": 0.93, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 40,
		"conditions": { "player_anim": "basic_kick", "distance": { "op": "<=", "value": 75 }, "upper_hits": { "op": "<=", "value": 1 }, "lower_hits": { "op": ">=", "value": 2 } },
		"enemy_action": "crouch_defense", "weight": 0.95, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 41,
		"conditions": { "player_anim": "walk_forward", "distance": { "op": ">=", "value": 160 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "jump", "weight": 0.65, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 42,
		"conditions": { "player_anim": "crouch_punch", "distance": { "op": "<=", "value": 75 }, "upper_hits": { "op": ">=", "value": 1 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "basic_punch", "weight": 0.89, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 43,
		"conditions": { "player_anim": "jump", "distance": { "op": "<=", "value": 65 }, "upper_hits": { "op": "<=", "value": 2 }, "lower_hits": { "op": "<=", "value": 1 } },
		"enemy_action": "basic_kick", "weight": 0.91, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 44,
		"conditions": { "player_anim": "basic_kick", "distance": { "op": "<=", "value": 85 }, "upper_hits": { "op": ">=", "value": 1 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "walk_backward", "weight": 0.88, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 45,
		"conditions": { "player_anim": "standing_defense", "distance": { "op": "<=", "value": 50 }, "upper_hits": { "op": ">=", "value": 2 }, "lower_hits": { "op": ">=", "value": 1 } },
		"enemy_action": "jump", "weight": 0.85, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 46,
		"conditions": { "player_anim": "crouch_defense", "distance": { "op": "<=", "value": 65 }, "upper_hits": { "op": ">=", "value": 2 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "basic_kick", "weight": 0.94, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 47,
		"conditions": { "player_anim": "basic_punch", "distance": { "op": ">=", "value": 90 }, "upper_hits": { "op": "<=", "value": 1 }, "lower_hits": { "op": "<=", "value": 1 } },
		"enemy_action": "walk_forward", "weight": 0.78, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 48,
		"conditions": { "player_anim": "walk_forward", "distance": { "op": "<=", "value": 50 }, "upper_hits": { "op": ">=", "value": 3 }, "lower_hits": { "op": ">=", "value": 3 } },
		"enemy_action": "jump", "weight": 0.97, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 49,
		"conditions": { "player_anim": "walk_backward", "distance": { "op": "<=", "value": 85 }, "upper_hits": { "op": "<=", "value": 2 }, "lower_hits": { "op": "<=", "value": 2 } },
		"enemy_action": "basic_punch", "weight": 0.82, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 50,
		"conditions": { "player_anim": "basic_kick", "distance": { "op": "<=", "value": 55 }, "upper_hits": { "op": "<=", "value": 1 }, "lower_hits": { "op": ">=", "value": 3 } },
		"enemy_action": "crouch_defense", "weight": 0.96, "wasUsed": false, "inScript": false
	}
]


var current_script: Array

func generate_and_update_script():
	for rule in rules:
		if rule.has("inScript"):
			rule["inScript"] = false
		else:
			print("Warning: Rule %s is missing 'inScript' key." % rule.get("ruleID", "UNKNOWN"))
			rule["inScript"] = false # Add it if missing

	if script_count <= 0:
		current_script = []
		return # Exit early

	# Step 2: Sort a *copy* of rules by weight (descending)
	var sorted_rules = rules.duplicate() # Shallow copy is sufficient
	sorted_rules.sort_custom(func(a, b): 
		# Sort descending. Handle missing 'weight' key gracefully.
		return a.get("weight", 0.0) > b.get("weight", 0.0)
	)

	# Step 3: Slice to get the top N rules
	var actual_count = min(script_count, sorted_rules.size())
	# Get the slice containing the dictionaries of the top rules
	var top_rules_slice = sorted_rules.slice(0, actual_count) 

	# Step 4: Modify the 'inScript' flag to true *within the sliced array*
	for rule_in_slice in top_rules_slice:
		if rule_in_slice.has("inScript"):
			rule_in_slice["inScript"] = true
		else:
			print("Warning: Rule %s in slice is missing 'inScript' key." % rule_in_slice.get("ruleID", "UNKNOWN"))
			rule_in_slice["inScript"] = true # Add and set to true

	# Step 5: Assign the modified slice to current_script
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
