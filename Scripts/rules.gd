# rules.gd
extends Node
class_name Rules

@export var script_count : int = 12  

var baseline = 0.5
var WMAX = 1.0
var WMIN = 0.1
var scaling_factor = 0.1    

var rules: Array = [
	# --- Original Rules (1-11) ---
	{
		"ruleID": 1,
		"conditions": { "player_anim": "walk_forward", "distance": { "op": ">=", "value": 100 }, "upper_hits": { "op": ">=", "value": 1 }, "lower_hits": { "op": "<", "value": 1 } },
		"enemy_action": "walk_forward", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 2,
		"conditions": { "player_anim": "walk_forward", "distance": { "op": "<=", "value": 80 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 0 } },
		"enemy_action": "basic_kick", "weight": 0.5, "wasUsed": false, "inScript": false # Increased weight
	},
	{
		"ruleID": 3,
		"conditions": { "player_anim": "basic_punch", "distance": { "op": "<=", "value": 50 }, "upper_hits": { "op": ">=", "value": 4 }, "lower_hits": { "op": ">=", "value": 0 } },
		"enemy_action": "walk_backward", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 4,
		"conditions": { "player_anim": "basic_kick", "distance": { "op": "<=", "value": 100 }, "upper_hits": { "op": ">=", "value": 2 }, "lower_hits": { "op": ">=", "value": 0 } },
		"enemy_action": "standing_defense", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 5,
		"conditions": { "player_anim": "basic_punch", "distance": { "op": "<=", "value": 83 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 0 } },
		"enemy_action": "basic_kick", "weight": 0.5, "wasUsed": false, "inScript": false # Increased weight
	},
	{
		"ruleID": 6,
		"conditions": { "player_anim": "crouch_kick", "distance": { "op": "<=", "value": 100 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 1 } },
		"enemy_action": "crouching_defense", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 7,
		"conditions": { "player_anim": "crouch_punch", "distance": { "op": "<=", "value": 83 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 1 } },
		"enemy_action": "crouching_defense", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 8,
		"conditions": { "player_anim": "crouch_kick", "distance": { "op": ">=", "value": 100 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 1 } },
		"enemy_action": "crouching_defense", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 9,
		"conditions": { "player_anim": "crouch_kick", "distance": { "op": "<=", "value": 100 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 1 } },
		"enemy_action": "jump", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 10,
		"conditions": { "player_anim": "jump", "distance": { "op": "<=", "value": 100 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 0 } },
		"enemy_action": "basic_kick", "weight": 0.5, "wasUsed": false, "inScript": false # Increased weight
	},
	{
		"ruleID": 11,
		"conditions": { "player_anim": "jump", "distance": { "op": "<=", "value": 83 }, "upper_hits": { "op": ">=", "value": 0 }, "lower_hits": { "op": ">=", "value": 0 } },
		"enemy_action": "basic_punch", "weight": 0.5, "wasUsed": false, "inScript": false # Increased weight
	},
	# --- New Rules (12-22) ---
	{
		"ruleID": 12, # Player walking back, enemy closes distance
		"conditions": { "player_anim": "walk_backward", "distance": { "op": ">=", "value": 50 }, "upper_hits": { "op": "<=", "value": 1 }, "lower_hits": { "op": "<=", "value": 1 } },
		"enemy_action": "walk_forward", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 13, # Player defending high, enemy tries a punch
		"conditions": { "player_anim": "standing_defense", "distance": { "op": "<=", "value": 70 }, "upper_hits": { "op": ">=", "value": 1 }, "lower_hits": { "op": "<=", "value": 1 } },
		"enemy_action": "basic_punch", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 14, # Player defending low, enemy tries a kick (potential counter)
		"conditions": { "player_anim": "crouching_defense", "distance": { "op": "<=", "value": 90 }, "upper_hits": { "op": "<=", "value": 1 }, "lower_hits": { "op": ">=", "value": 1 } },
		"enemy_action": "basic_kick", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 15, # Player walking forward far away, enemy jumps in
		"conditions": { "player_anim": "walk_forward", "distance": { "op": ">=", "value": 150 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "jump", "weight": 0., "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 16, # Player punch blocked/missed close range, enemy counter punches
		"conditions": { "player_anim": "basic_punch", "distance": { "op": "<=", "value": 60 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "basic_punch", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 17, # Player kick blocked/missed medium range, enemy backs away
		"conditions": { "player_anim": "basic_kick", "distance": { "op": "<=", "value": 110 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "walk_backward", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 18, # Player jumps from far away, enemy walks forward
		"conditions": { "player_anim": "jump", "distance": { "op": ">=", "value": 120 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "walk_forward", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 19, # Player low punch connects often, enemy jumps away
		"conditions": { "player_anim": "crouch_punch", "distance": { "op": "<=", "value": 70 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": ">=", "value": 3 } },
		"enemy_action": "jump", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 20, # Player walking forward taking upper hits, enemy defends high
		"conditions": { "player_anim": "walk_forward", "distance": { "op": "<=", "value": 120 }, "upper_hits": { "op": ">=", "value": 2 }, "lower_hits": { "op": "<=", "value": 1 } },
		"enemy_action": "standing_defense", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 21, # Player defending under pressure, enemy backs off
		"conditions": { "player_anim": "standing_defense", "distance": { "op": "<=", "value": 50 }, "upper_hits": { "op": ">=", "value": 3 }, "lower_hits": { "op": ">=", "value": 2 } },
		"enemy_action": "walk_backward", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 22, # Player kicks from far, enemy closes distance
		"conditions": { "player_anim": "basic_kick", "distance": { "op": ">=", "value": 130 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "walk_forward", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 23, # Player kicks from far, enemy closes distance
		"conditions": { "player_anim": "basic_kick", "distance": { "op": ">=", "value": 130 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "crouch_punch", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 24, # Player kicks from far, enemy closes distance
		"conditions": { "player_anim": "basic_kick", "distance": { "op": ">=", "value": 130 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "crouch_punch", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 25, # Player kicks from far, enemy closes distance
		"conditions": { "player_anim": "basic_punch", "distance": { "op": ">=", "value": 130 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "crouch_punch", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 26, # Player kicks from far, enemy closes distance
		"conditions": { "player_anim": "basic_punch", "distance": { "op": ">=", "value": 130 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "crouch_kick", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 27, # Player kicks from far, enemy closes distance
		"conditions": { "player_anim": "basic_punch", "distance": { "op": ">=", "value": 130 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "standing_defense", "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 28, # Player kicks from far, enemy closes distance
		"conditions": { "player_anim": "basic_kick", "distance": { "op": ">=", "value": 130 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		"enemy_action": "standing_defense", "weight": 0.5, "wasUsed": false, "inScript": false
	}
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
			printerr("Warning: Rule %s in slice is missing 'inScript' key." % rule_in_slice.get("ruleID", "UNKNOWN"))
			rule_in_slice["inScript"] = true # Add and set to true

	# --- Step 5: Assign the modified slice to current_script ---
	current_script = top_rules_slice

	print("Generated new script with %d rules. 'inScript' set to true within this script." % current_script.size())
	# Optional: Print the actual script for debugging (notice 'inScript' should be true)
	#print("New Script:", current_script)

func get_rules() -> Array:
	return rules

func get_DScript() -> Array:
		#print(current_script) 
		return current_script
# --- Optional: Add functions to modify rules or weights if needed ---
# func update_rule_weight(rule_id: int, new_weight: float):
#	 for rule in rules:
#		 if rule.get("ruleID") == rule_id:
#			 rule["weight"] = new_weight
#			 print("Updated weight for rule %d to %f" % [rule_id, new_weight])
#			 # Note: This change will only reflect in the *next* script generation cycle.
#			 break
func calculate_fitness(DS_lower_hits_taken : int, DS_upper_hits_taken : int, DS_upper_successful_attacks : int, DS_lower_successful_attacks : int, DS_standing_defended : int, DS_crouching_defended : int, maxHP):
	var bot_dmg_taken :=(10 * (DS_lower_hits_taken + DS_upper_hits_taken)) 
	var bot_dmg_output := (10 * (DS_upper_successful_attacks + DS_lower_successful_attacks))
	
	var dmg_score = (bot_dmg_taken - bot_dmg_output)/maxHP
	
	var offensiveness = (0.002 * DS_upper_successful_attacks + 0.002 * DS_lower_successful_attacks)
#	ADD FIRST THE FUNCTIONALITIES FOR THE CROUCHING AND STANDING DEFENSE
	var defensiveness = (0.003 * DS_standing_defended + 0.003 * DS_crouching_defended)
	var penalties = (-0.005 * DS_lower_hits_taken + -0.005 * DS_upper_hits_taken)
	var raw = baseline + dmg_score + offensiveness + defensiveness + penalties
	return max(0.0, min(1.0, raw))
	
func adjust_script_weights(fitness: float) -> void:
	var adjustment = (fitness - baseline) * scaling_factor
	var used_rules = []
	var unused_rules = []
	var compensation
	
	for rule in current_script:
		if rule["wasUsed"] == true:
			used_rules.append(rule)
		elif rule["wasUsed"] == false:
			unused_rules.append(rule)
			
	if len(unused_rules) > 0: # Check if there are any unused rules
		compensation = (len(used_rules) * adjustment) / float(len(unused_rules)) # Ensure float division
	else:
		pass
	
	for rule in current_script:
		if rule.get("wasUsed") == true:
			rule["weight"] += adjustment
		else:
			rule["weight"] += compensation
	# Clamp weight between WMIN and WMAX
		rule["weight"] = clamp(rule["weight"], WMIN, WMAX)
	#print(current_script)
	
func update_rulebase() -> void:
	
	var script_dict := {}
	# Build dictionary from script using ruleID as key
	for r in current_script:
		script_dict[r["ruleID"]] = r
	# Update rulebase weights from script_dict
	for r in rules:
		if script_dict.has(r["ruleID"]):
			r["weight"] = script_dict[r["ruleID"]]["weight"]
