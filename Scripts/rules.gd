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
		"wasUsed": 0
	},
	{
		"ruleID": 2,
		"conditions": {
			"player_anim": "walk_forward",
			"distance": { "op": "<=", "value": 100 }
		},
		"enemy_action": "basic_kick",
		"weight": 0.5,
		"wasUsed": 0
	},
	{
		"ruleID": 3,
		"conditions": {
			"distance": { "op": "<=", "value": 50 }
		},
		"enemy_action": "walk_backward",
		"weight": 0.5,
		"wasUsed": 0
	},
	{
		"ruleID": 4,
		"conditions": {
			"player_anim": "basic_kick",
			"distance": { "op": "<=", "value": 100 }
		},
		"enemy_action": "standing_defense",
		"weight": 0.5,
		"wasUsed": 0
	},
	{
		"ruleID": 5,
		"conditions": {
			"player_anim": "basic_punch",
			"distance": { "op": "<=", "value": 83 }
		},
		"enemy_action": "basic_kick",
		"weight": 0.5,
		"wasUsed": 0
	},
	{
		"ruleID": 6,
		"conditions": {
			"player_anim": "crouch_kick",
			"distance": { "op": "<=", "value": 100 }
		},
		"enemy_action": "crouch_defense",
		"weight": 0.5,
		"wasUsed": 0
	},
	{
		"ruleID": 7,
		"conditions": {
			"player_anim": "crouch_punch",
			"distance": { "op": "<=", "value": 83 }
		},
		"enemy_action": "crouch_defense",
		"weight": 0.5,
		"wasUsed": 0
	},
	{
		"ruleID": 8,
		"conditions": {
			"player_anim": "crouch_kick",
			"distance": { "op": ">=", "value": 100 }
		},
		"enemy_action": "crouch_defense",
		"weight": 0.5,
		"wasUsed": 0
	},
	{
		"ruleID": 9,
		"conditions": {
			"player_anim": "crouch_kick",
			"distance": { "op": "<=", "value": 100 }
		},
		"enemy_action": "jump",
		"weight": 0.5,
		"wasUsed": 0
	},
	{
		"ruleID": 10,
		"conditions": {
			"player_anim": "jump",
			"distance": { "op": "<=", "value": 100 }
		},
		"enemy_action": "basic_kick",
		"weight": 0.5,
		"wasUsed": 0
	},
	{
		"ruleID": 11,
		"conditions": {
			"player_anim": "jump",
			"distance": { "op": "<=", "value": 83 }
		},
		"enemy_action": "basic_punch",
		"weight": 0.5,
		"wasUsed": 0
	}
]

# Optionally, add helper functions here, e.g. get_rules_by_condition, or random selection, etc.
func get_rules() -> Array:
	#print("Rules Returned:", rules)
	return rules
