# rules.gd
extends Node
class_name Rules

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

func get_new_script(script_count: int) -> Array:

	if script_count <= 0:
		return []

	var sorted_rules = rules.duplicate() # Use duplicate() for a shallow copy

	var n = sorted_rules.size()

	var swapped: bool
	for i in range(n - 1):
		swapped = false

		for j in range(n - i - 1):
			if sorted_rules[j]["weight"] < sorted_rules[j+1]["weight"]:
				var temp = sorted_rules[j]
				sorted_rules[j] = sorted_rules[j+1]
				sorted_rules[j+1] = temp
				swapped = true

		# Optimization: If no swaps occurred in a pass, the array is sorted
		if not swapped:
			break

	var top_rules = sorted_rules.slice(0, script_count) # slice(start_inclusive, end_exclusive)
	print(top_rules.size())
	return top_rules
