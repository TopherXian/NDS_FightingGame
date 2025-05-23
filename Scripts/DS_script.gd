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
	var current_lower_hits_taken = ai_self.lower_hits_taken
	var current_upper_hits_taken = ai_self.upper_hits_taken
	var current_lower_attacks_landed = ai_self.lower_attacks_landed
	var current_upper_attacks_landed = ai_self.upper_attacks_landed

	var corner_move_direction = ai_self.get_distance_from_corner_ds()
	var matched_rules = []

	for rule in rules:
		var conditions = rule["conditions"]
		var match_all = true

		if "distance_from_corner" in conditions:
			if corner_move_direction != 0 and ai_self.is_on_floor():
				ai_self.velocity.y = -450
				ai_self.velocity.x = corner_move_direction * 150 * 1.75
			continue

		if "player_anim" in conditions and conditions["player_anim"] != current_anim:
			match_all = false
			continue

		if match_all and "distance" in conditions:
			var cond = conditions["distance"]
			if not _compare_numeric(cond["op"], dist, cond["value"]):
				match_all = false
				continue

		if match_all and "upper_hits_taken" in conditions:
			var cond = conditions["upper_hits_taken"]
			if not _compare_numeric(cond["op"], current_upper_hits_taken, cond["value"]):
				match_all = false
				continue

		if match_all and "lower_hits_taken" in conditions:
			var cond = conditions["lower_hits_taken"]
			if not _compare_numeric(cond["op"], current_lower_hits_taken, cond["value"]):
				match_all = false
				continue

		if match_all and "lower_attacks_landed" in conditions:
			var cond = conditions["lower_attacks_landed"]
			if not _compare_numeric(cond["op"], current_lower_attacks_landed, cond["value"]):
				match_all = false
				continue

		if match_all and "upper_attacks_landed" in conditions:
			var cond = conditions["upper_attacks_landed"]
			if not _compare_numeric(cond["op"], current_upper_attacks_landed, cond["value"]):
				match_all = false
				continue

		if match_all:
			matched_rules.append(rule)

	# Sort matched rules by prioritization (highest first)
	matched_rules.sort_custom(Callable(self, "_sort_by_priority_desc"))

	if matched_rules.size() > 0:
		var rule = matched_rules[0]
		var actions = rule.get("enemy_actions", [])

		if actions.size() == 0:
			var raw_action = rule.get("enemy_action", "idle")
			actions = [raw_action] if typeof(raw_action) == TYPE_STRING else raw_action

		var valid_actions = []
		for action in actions:
			if typeof(action) == TYPE_STRING:
				valid_actions.append(action)
			else:
				print("Invalid action type in rule %d: %s" % [rule.get("ruleID", -1), str(action)])

		if valid_actions.size() > 0:
			_execute_actions(valid_actions)
			rule["wasUsed"] = true
			append_executed_rule(rule)
			current_rule = " > ".join(valid_actions)

# Custom sort function
func _sort_by_priority_desc(a, b):
	print(a["prioritization"], b["prioritization"])
	return int(b["prioritization"]) - int(a["prioritization"])

# This should already exist — ensure it’s accessible
func _execute_actions(actions: Array):
	if ai_self.active_controller.has_method("queue_actions"):
		var delayed_actions = []
		for action in actions:
			delayed_actions.append({ "action": action, "delay": 0.2 })
		ai_self.active_controller.queue_actions(delayed_actions)


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

# ⚡ Modified to handle single actions
func _execute_single_action(action: String):
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
			if animation.current_animation != "basic_kick": 
				animation.play("basic_kick")
			ai_self.velocity.x = 0
		"basic_punch":
			if animation.current_animation != "basic_punch": 
				animation.play("basic_punch")
			ai_self.velocity.x = 0
		"standing_defense":
			if animation.current_animation != "standing_defense": 
				animation.play("standing_defense")
			ai_self.velocity.x = 0
		"crouching_defense":
			if animation.current_animation != "crouching_defense": 
				animation.play("crouching_defense")
			ai_self.velocity.x = 0
		"jump":
			if ai_self.is_on_floor():
				if animation.has_animation("jump"):
					animation.play("jump")
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
