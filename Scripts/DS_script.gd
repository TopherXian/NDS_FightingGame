extends Node
class_name ScriptCreation

var player
var player_anim
var animation
var ai_self

var baseline = 0.5
var WMAX = 1.0
var WMIN = 0.1
var scaling_factor = 0.1

var speed = 150

func _init(enemy_ref, enemy_anim):
	player = enemy_ref
	player_anim = enemy_ref.animation
	animation = enemy_anim

func set_ai_reference(ref):
	ai_self = ref

func evaluate_and_execute(rules: Array):
	var current_anim = player_anim.current_animation
	var dist = ai_self.global_position.distance_to(player.global_position)
	var current_lower_hits = ai_self.lower_hits # Get current hits from AI
	var current_upper_hits = ai_self.upper_hits # Get current hits from AI

	for rule in rules:
		var conditions = rule["conditions"]
		var ruleID = rule["ruleID"]
		var match_anim = false
		var match_dist = false
		var match_upper_hits = false
		var match_lower_hits = false
		
		if "player_anim" in conditions:
			match_anim = (conditions["player_anim"] == current_anim)

		if "distance" in conditions:
			var op = conditions["distance"]["op"]
			var value = conditions["distance"]["value"]
			match_dist = _compare_numeric(op, dist, value)
		
		if "upper_hits" in conditions:
			var op = conditions["distance"]["op"]
			var value = conditions["distance"]["value"]
			match_upper_hits = _compare_numeric(op, dist, value)
			
		if "lower_hits" in conditions:
			var op = conditions["distance"]["op"]
			var value = conditions["distance"]["value"]
			match_lower_hits = _compare_numeric(op, dist, value)

		if match_anim and match_dist and (match_upper_hits or match_lower_hits):
			_execute_action(rule["enemy_action"])
			rule["wasUsed"] = true
			#print(rule)
			break


# --- Helper function for numerical comparisons ---
# Renamed from compare_distance to be more generic
func _compare_numeric(op: String, current_value: int, rule_value: int) -> bool:
	match op:
		">=":
			return current_value >= rule_value
		"<=":
			return current_value <= rule_value
		">":
			return current_value > rule_value
		"<":
			return current_value < rule_value
		"==":
			return current_value == rule_value # Simple comparison for now
		_:
			printerr("Unknown comparison operator: ", op)
			return false

func _execute_action(action: String):
	match action:
		"walk_forward":
			animation.play("walk_forward")
			if player.global_position.x > ai_self.global_position.x:
				ai_self.velocity.x = speed
			else:
				ai_self.velocity.x = -speed
		"walk_backward":
			animation.play("walk_backward")
			if player.global_position.x > ai_self.global_position.x:
				ai_self.velocity.x = -speed
			else:
				ai_self.velocity.x = speed
		"basic_kick":
			if animation.current_animation != "basic_kick": animation.play("basic_kick")
			ai_self.velocity.x = 0 # Stop horizontal movement during attack
		"basic_punch":
			if animation.current_animation != "basic_punch": animation.play("basic_punch")
			ai_self.velocity.x = 0
		"standing_defense":
			if animation.current_animation != "standing_defense": animation.play("standing_defense")
			ai_self.velocity.x = 0
		"crouching_defense":
			if animation.current_animation != "crouching_defense": animation.play("crouching_defense")
			ai_self.velocity.x = 0
		"jump":
			if ai_self.is_on_floor():
				if animation.current_animation != "jump": animation.play("jump")
				ai_self.velocity.y = -400
		_:
			animation.play("basic_punch")
		
func calculate_fitness(DS_lower_hits_taken : int, DS_upper_hits_taken : int, DS_upper_successful_attacks : int, DS_lower_successful_attacks : int, DS_standing_defended : int, DS_crouching_defended : int, maxHP):
	var bot_dmg_taken :=(10 * (DS_lower_hits_taken + DS_upper_hits_taken)) 
	var bot_dmg_output := (10 * (DS_upper_successful_attacks + DS_lower_successful_attacks))
	
	var dmg_score = (bot_dmg_taken - bot_dmg_output)/maxHP
	
	var offensiveness = (0.002 * DS_upper_successful_attacks + 0.002 * DS_lower_successful_attacks)
#	ADD FIRST THE FUNCTIONALITIES FOR THE CROUCHING AND STANDING DEFENSE
	var defensiveness = (0.003 * DS_standing_defended + 0.003 * DS_crouching_defended)
	var penalties = (-0.005 * DS_lower_hits_taken + -0.005 * DS_upper_hits_taken)
	var raw = baseline + 0.5 + dmg_score + offensiveness + defensiveness + penalties
	return max(0.0, min(1.0, raw))
	
func adjust_script_weights(script : Array, fitness: int):
	var adjustment = (fitness - baseline) * scaling_factor
	var used_rules = []
	var unused_rules = []
	for rules in script:
		if rules["wasUsed"] == true:
			used_rules.append(rules)
		elif rules["wasUsed"] == false:
			unused_rules.append(rules)
		else:
			return script
	var compensation = (len(used_rules) * adjustment) / len(unused_rules)
	
	for rules in script:
		if rules.get("wasUsed") == true:
			rules["weight"] += adjustment
		else:
			rules["weight"] += compensation
	# Clamp weight between WMIN and WMAX
		rules["weight"] = clamp(rules["weight"], WMIN, WMAX)
	#print(script)
	return script
	
func update_rulebase(rulebase: Array, script: Array) -> Array:
	
	var script_dict := {}
	# Build dictionary from script using ruleID as key
	for r in script:
		script_dict[r["ruleID"]] = r
	# Update rulebase weights from script_dict
	for r in rulebase:
		if script_dict.has(r["ruleID"]):
			r["weight"] = script_dict[r["ruleID"]]["weight"]
	return rulebase
