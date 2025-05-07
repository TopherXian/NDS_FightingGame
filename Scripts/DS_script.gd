extends Node
class_name ScriptCreation

var player
var player_anim
var animation
var ai_self

var executed_rules: Dictionary = {}
var current_rule: String = "No rule"

var speed = 150

#var last_action_time: float = 0.0
#var ACTION_COOLDOWN: float = 0.4

func _init(enemy_ref, enemy_anim, animation_player):
	player = enemy_ref
	player_anim = enemy_anim
	animation = animation_player

func set_ai_reference(ref):
	ai_self = ref

func evaluate_and_execute(rules: Array):
	var current_anim = player_anim.current_animation
	var dist = ai_self.global_position.distance_to(player.global_position)
	var current_lower_hits_taken = ai_self.lower_hits_taken # Get current hits from AI
	var current_upper_hits_taken = ai_self.upper_hits_taken # Get current hits from AI
	var current_lower_attacks_landed = ai_self.lower_attacks_landed
	var current_upper_attacks_landed = ai_self.upper_attacks_landed
	for rule in rules:
		var conditions = rule["conditions"]
		#var ruleID = rule["ruleID"]
		#var match_anim = false
		#var match_dist = false
		#var match_upper_hits = false
		#var match_lower_hits = false
		var match_all = true
		
		if "player_anim" in conditions:
			if conditions["player_anim"] != current_anim:
				match_all = false
				continue # Go to next rule if this condition fails

		if match_all and "distance" in conditions:
			var op = conditions["distance"]["op"]
			var value = conditions["distance"]["value"]
			if not _compare_numeric(op, dist, value):
				match_all = false
				continue # Go to next rule
		
		if match_all and conditions.has("upper_hits_taken"):
			var upper_hit = conditions["upper_hits_taken"]
			if upper_hit is Dictionary and upper_hit.has("op") and upper_hit.has("value"):
				var op = upper_hit["op"]
				var value = upper_hit["value"]
				if not _compare_numeric(op, current_upper_hits_taken, value):
					match_all = false
					continue
			
		if match_all and conditions.has("lower_hits_taken"):
			var lower_hit = conditions["lower_hits_taken"]
			if lower_hit is Dictionary and lower_hit.has("op") and lower_hit.has("value"):
				var op = lower_hit["op"]
				var value = lower_hit["value"]
				if not _compare_numeric(op, current_lower_hits_taken, value):
					match_all = false
					continue

		if match_all and conditions.has("lower_attacks_landed"):
			var lower_attack = conditions["lower_attacks_landed"]
			if lower_attack is Dictionary and lower_attack.has("op") and lower_attack.has("value"):
				var op = lower_attack["op"]
				var value = lower_attack["value"]
				if not _compare_numeric(op, current_lower_attacks_landed, value):
					match_all = false
					continue

		if match_all and conditions.has("upper_attacks_landed"):
			var upper_attack = conditions["upper_attacks_landed"]
			if upper_attack is Dictionary and upper_attack.has("op") and upper_attack.has("value"):
				var op = upper_attack["op"]
				var value = upper_attack["value"]
				if not _compare_numeric(op, current_upper_attacks_landed, value):
					match_all = false
					continue
	# If we reach here and match_all is still true, all present conditions passed
		if match_all:
			_execute_action(rule["enemy_action"])
			rule["wasUsed"] = true
			append_executed_rule(rule)
			#print(rule)
			current_rule = rule["enemy_action"]
			#print("Executing Rule ID:", rule.get("ruleID", "UNKNOWN"), "Weight: ", rule.get("weight", "UNKOWN"))
			break # Execute only the first matching rule


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
			print("Unknown comparison operator: ", op)
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
			animation.play("idle")
			ai_self.velocity.x = 0 

func append_executed_rule(rule: Dictionary) -> void:
	if not rule is Dictionary or not rule.has("ruleID"):
		print("Invalid rule format passed to append_executed_rule: ", rule)
		return

	var id = rule["ruleID"]
	
	if not executed_rules.has(id):
		executed_rules[id] = rule
	#print(rule)

func get_executed_rules() -> Array:
	return executed_rules.values()

func clear_executed_rules() -> void:
	executed_rules.clear()
	
func get_current_rule() -> String:
	return current_rule
