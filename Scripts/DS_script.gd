# DS_script.gd
extends Node
class_name ScriptCreation
var rule_base
var player : CharacterBody2D
const MAX_RULES = 4

var selected_rules: Array = []

func _init(player_char: CharacterBody2D, player_animation: AnimationPlayer):
#	LOAD THE RULES
	rule_base = Rules.new()
	print(rule_base.rules)
	preprocess_rules(rule_base, player_char, player_animation)

func preprocess_rules(rule: Dictionary, player, player_animation):
	var distance : float
	var conditions = rule["conditions"]
	print(conditions)
