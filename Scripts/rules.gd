# rules.gd
extends Node
class_name Rules

@export var script_count : int = 6       

var rules: Array = [
	{
		"ruleID": 1,
		"conditions": {
			"player_anim": "walk_forward",
			"distance": { "op": ">=", "value": 100 }
		},
		"enemy_action": "walk_forward",
		"weight": 0.5,
		"wasUsed": 0,
		"inScript": 0
	},
	{
		"ruleID": 2,
		"conditions": {
			"player_anim": "walk_forward",
			"distance": { "op": "<=", "value": 100 }
		},
		"enemy_action": "basic_kick",
		"weight": 0.5,
		"wasUsed": 0,
		"inScript": 0
	},
	{
		"ruleID": 3,
		"conditions": {
			"distance": { "op": "<=", "value": 50 }
		},
		"enemy_action": "walk_backward",
		"weight": 0.5,
		"wasUsed": 0,
		"inScript": 0
	},
	{
		"ruleID": 4,
		"conditions": {
			"player_anim": "basic_kick",
			"distance": { "op": "<=", "value": 100 }
		},
		"enemy_action": "standing_defense",
		"weight": 0.5,
		"wasUsed": 0,
		"inScript": 0
	},
	{
		"ruleID": 5,
		"conditions": {
			"player_anim": "basic_punch",
			"distance": { "op": "<=", "value": 83 }
		},
		"enemy_action": "basic_kick",
		"weight": 0.5,
		"wasUsed": 0,
		"inScript": 0
	},
	{
		"ruleID": 6,
		"conditions": {
			"player_anim": "crouch_kick",
			"distance": { "op": "<=", "value": 100 }
		},
		"enemy_action": "crouch_defense",
		"weight": 0.5,
		"wasUsed": 0,
		"inScript": 0
	},
	{
		"ruleID": 7,
		"conditions": {
			"player_anim": "crouch_punch",
			"distance": { "op": "<=", "value": 83 }
		},
		"enemy_action": "crouch_defense",
		"weight": 0.5,
		"wasUsed": 0,
		"inScript": 0
	},
	{
		"ruleID": 8,
		"conditions": {
			"player_anim": "crouch_kick",
			"distance": { "op": ">=", "value": 100 }
		},
		"enemy_action": "crouch_defense",
		"weight": 0.5,
		"wasUsed": 0,
		"inScript": 0
	},
	{
		"ruleID": 9,
		"conditions": {
			"player_anim": "crouch_kick",
			"distance": { "op": "<=", "value": 100 }
		},
		"enemy_action": "jump",
		"weight": 0.5,
		"wasUsed": 0,
		"inScript": 0
	},
	{
		"ruleID": 10,
		"conditions": {
			"player_anim": "jump",
			"distance": { "op": "<=", "value": 100 }
		},
		"enemy_action": "basic_kick",
		"weight": 0.5,
		"wasUsed": 0,
		"inScript": 0
	},
	{
		"ruleID": 11,
		"conditions": {
			"player_anim": "jump",
			"distance": { "op": "<=", "value": 83 }
		},
		"enemy_action": "basic_punch",
		"weight": 0.5,
		"wasUsed": 0,
		"inScript": 0
	}
]

var current_script: Array

func generate_and_update_script():

	if script_count <= 0:
		current_script = []
		return

	# --- Sorting Logic (Your Bubble Sort) ---
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
	# --- End Sorting ---

	# Slice to get the top N rules, ensuring we don't request more than available
	var actual_count = min(script_count, sorted_rules.size())
	current_script = sorted_rules.slice(0, actual_count) # slice(start_inclusive, end_exclusive)

	print("Generated new script with %d rules." % current_script.size())
	# Optional: Print the actual script for debugging
	# print("New Script:", current_script)

func get_rules() -> Array:
		print(current_script.size())
		return current_script
