# rules.gd
extends Node
class_name Rules

@export var script_count : int = 6       

var rules: Array = [
	{
		"ruleID": 1,
		"conditions": {
			"player_anim": "walk_forward",
			"distance": { "op": ">=", "value": 100 },
			"upper_hits": { "op": ">=", "value": 1 },
			"lower_hits": { "op": "<", "value": 1 }
		},
		"enemy_action": "walk_forward",
		"weight": 0.5,
		"wasUsed": false,
		"inScript": false
	},
	{
		"ruleID": 2,
		"conditions": {
			"player_anim": "walk_forward",
			"distance": { "op": "<=", "value": 100 },
			"upper_hits": { "op": ">=", "value": 0 },
			"lower_hits": { "op": ">=", "value": 0 }
		},
		"enemy_action": "basic_kick",
		"weight": 0.5,
		"wasUsed": false,
		"inScript": false
	},
	{
		"ruleID": 3,
		"conditions": {
			"player_anim": "basic_punch",
			"distance": { "op": "<=", "value": 50 },
			"upper_hits": { "op": ">=", "value": 4 },
			"lower_hits": { "op": ">=", "value": 0 }
		},
		"enemy_action": "walk_backward",
		"weight": 0.5,
		"wasUsed": false,
		"inScript": false
	},
	{
		"ruleID": 4,
		"conditions": {
			"player_anim": "basic_kick",
			"distance": { "op": "<=", "value": 100 },
			"upper_hits": { "op": ">=", "value": 2 },
			"lower_hits": { "op": ">=", "value": 0 }
		},
		"enemy_action": "standing_defense",
		"weight": 0.5,
		"wasUsed": false,
		"inScript": false
	},
	{
		"ruleID": 5,
		"conditions": {
			"player_anim": "basic_punch",
			"distance": { "op": "<=", "value": 83 },
			"upper_hits": { "op": ">=", "value": 0 },
			"lower_hits": { "op": ">=", "value": 0 }

		},
		"enemy_action": "basic_kick",
		"weight": 0.5,
		"wasUsed": false,
		"inScript": false
	},
	{
		"ruleID": 6,
		"conditions": {
			"player_anim": "crouch_kick",
			"distance": { "op": "<=", "value": 100 },
			"upper_hits": { "op": ">=", "value": 0 },
			"lower_hits": { "op": ">=", "value": 1 }
		},
		"enemy_action": "crouching_defense",
		"weight": 0.5,
		"wasUsed": false,
		"inScript": false
	},
	{
		"ruleID": 7,
		"conditions": {
			"player_anim": "crouch_punch",
			"distance": { "op": "<=", "value": 83 },
			"upper_hits": { "op": ">=", "value": 0 },
			"lower_hits": { "op": ">=", "value": 1 }
		},
		"enemy_action": "crouching_defense",
		"weight": 0.5,
		"wasUsed": false,
		"inScript": false
	},
	{
		"ruleID": 8,
		"conditions": {
			"player_anim": "crouch_kick",
			"distance": { "op": ">=", "value": 100 },
			"upper_hits": { "op": ">=", "value": 0 },
			"lower_hits": { "op": ">=", "value": 1 }
		},
		"enemy_action": "crouching_defense",
		"weight": 0.5,
		"wasUsed": false,
		"inScript": false
	},
	{
		"ruleID": 9,
		"conditions": {
			"player_anim": "crouch_kick",
			"distance": { "op": "<=", "value": 100 },
			"upper_hits": { "op": ">=", "value": 0 },
			"lower_hits": { "op": ">=", "value": 1 }
		},
		"enemy_action": "jump",
		"weight": 0.5,
		"wasUsed": false,
		"inScript": false
	},
	{
		"ruleID": 10,
		"conditions": {
			"player_anim": "jump",
			"distance": { "op": "<=", "value": 100 },
			"upper_hits": { "op": ">=", "value": 0 },
			"lower_hits": { "op": ">=", "value": 0 }
		},
		"enemy_action": "basic_kick",
		"weight": 0.5,
		"wasUsed": false,
		"inScript": false
	},
	{
		"ruleID": 11,
		"conditions": {
			"player_anim": "jump",
			"distance": { "op": "<=", "value": 83 },
			"upper_hits": { "op": ">=", "value": 0 },
			"lower_hits": { "op": ">=", "value": 0 }
		},
		"enemy_action": "basic_punch",
		"weight": 0.5,
		"wasUsed": false,
		"inScript": false
	}
]

var current_script: Array

func generate_and_update_script():
	if script_count <= 0:
		current_script = []
		return

	# Note: For larger rule sets, consider Array.sort_custom() for better performance.
	var sorted_rules = rules.duplicate() # Use duplicate() for a shallow copy
	var n = sorted_rules.size()
	var swapped: bool
	for i in range(n - 1):
		swapped = false
		for j in range(n - i - 1):
			# Sort descending by weight. Use .get() for safety if 'weight' might be missing.
			if sorted_rules[j].get("weight", 0.0) < sorted_rules[j+1].get("weight", 0.0):
				var temp = sorted_rules[j]
				sorted_rules[j] = sorted_rules[j+1]
				sorted_rules[j+1] = temp
				swapped = true
		if not swapped:
			break # Optimization: If no swaps, array is sorted

	# Slice to get the top N rules, ensuring we don't request more than available
	var actual_count = min(script_count, sorted_rules.size())
	current_script = sorted_rules.slice(0, actual_count) # slice(start_inclusive, end_exclusive)

	print("Generated new script with %d rules." % current_script.size())
	#print(current_script)
	# Optional: Print the actual script for debugging
	# print("New Script:", current_script)

func get_rules() -> Array:
	return rules

func get_DScript() -> Array:
		#print(current_script.size())
		return current_script
# --- Optional: Add functions to modify rules or weights if needed ---
# func update_rule_weight(rule_id: int, new_weight: float):
#	 for rule in rules:
#		 if rule.get("ruleID") == rule_id:
#			 rule["weight"] = new_weight
#			 print("Updated weight for rule %d to %f" % [rule_id, new_weight])
#			 # Note: This change will only reflect in the *next* script generation cycle.
#			 break
