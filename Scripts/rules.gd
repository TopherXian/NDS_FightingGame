extends Node
class_name RuleBase

var DS_anim : AnimationPlayer
var player_anim : AnimationPlayer
var enemy : CharacterBody2D
var player : CharacterBody2D

var rules: Array = []

func _init(enemy_animation: AnimationPlayer, DS_char: CharacterBody2D, player_animation: AnimationPlayer, player_char: CharacterBody2D):
	DS_anim = enemy_animation
	player_anim = player_animation
	enemy = DS_char
	player = player_char

func _ready():
	_load_rules()

func _load_rules():
	rules = [
		{
			"ruleID": 1,
			"rule_name": "crouch_kick",
			"conditions": {
				"distance": {
					"op": "<=",
					"value": 100
				},
				"player_animation": "crouch"
			},
			"action": "crouch_kick",
			"weight": 0.1,
			"wasUsed": 0
		},
				{
			"ruleID": 2,
			"rule_name": "crouch_punch",
			"conditions": {
				"distance": {
					"op": "<=",
					"value": 83
				},
				"player_animation": "crouch"
			},
			"action": "crouch_punch",
			"weight": 0.1,
			"wasUsed": 0
		},
				{
			"ruleID": 3,
			"rule_name": "basic_kick",
			"conditions": {
				"distance": {
					"op": "<=",
					"value": 100
				},
				"player_animation": "idle"
			},
			"action": "basic_kick",
			"weight": 0.1,
			"wasUsed": 0
		},
				{
			"ruleID": 4,
			"rule_name": "basic_punch",
			"conditions": {
				"distance": {
					"op": "<=",
					"value": 83
				},
				"player_animation": "idle"
			},
			"action": "basic_punch",
			"weight": 0.1,
			"wasUsed": 0
		},
						{
			"ruleID": 5,
			"rule_name": "walk_forward",
			"conditions": {
				"distance": {
					"op": ">",
					"value": 100
				},
				"player_animation": "idle"
			},
			"action": "basic_punch",
			"weight": 0.1,
			"wasUsed": 0
		},
						{
			"ruleID": 6,
			"rule_name": "walk_backward",
			"conditions": {
				"distance": {
					"op": "<=",
					"value": 50
				},
				"player_animation": "walk_backward"
			},
			"action": "walk_backward",
			"weight": 0.1,
			"wasUsed": 0
		}
	]
