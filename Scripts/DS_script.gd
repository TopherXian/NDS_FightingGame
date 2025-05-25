extends Node
class_name ScriptCreation

var player
var player_anim
var animation
var ai_self

var executed_rules: Dictionary = {}
var current_rule: String = "No rule"
var current_rule_dict: Dictionary = {}

var rules_base: Rules

var speed = 150

#var last_action_time: float = 0.0
#var ACTION_COOLDOWN: float = 0.4

func _init(enemy_ref, enemy_anim, animation_player):
	player = enemy_ref
	player_anim = enemy_anim
	animation = animation_player
	
	if FileAccess.file_exists("res://Scripts/rules.gd"):
		var RulesClass = load("res://Scripts/rules.gd")
		if RulesClass:
			rules_base = RulesClass.new()
			# Pass fighter reference if Rules need it (e.g., for fitness calc access)
			# rules_base.set_fighter_reference(fighter)
		else: print("DSScript: Failed to load Rules.gd")
	else: print("DSScript: Rules.gd not found.")

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

	# In DS_script.gd's evaluate_and_execute function:
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
			# Set the current_rule_id in the DSController
			if ai_self and ai_self.active_controller:
				ai_self.active_controller.current_rule_id = rule["ruleID"]  # <-- Add this line

# Custom sort function
func _sort_by_priority_desc(a, b):
	#print(a["prioritization"], b["prioritization"])
	return int(b["prioritization"]) - int(a["prioritization"])

# This should already exist — ensure it’s accessible
func _execute_actions(actions: Array):
	if actions.is_empty():
		current_rule_dict = {}
		return
	
	# Get first valid action
	var first_action = actions[0]
	if typeof(first_action) == TYPE_DICTIONARY:
		first_action = first_action.get("action", "")
		
	# Find deepest matching rule
	var matched_rule = rules_base.get_rule_by_action(first_action)
	if not matched_rule.is_empty():
		current_rule_dict = matched_rule
	else:
		current_rule_dict = {}
	
	if ai_self.active_controller.has_method("queue_actions"):
		var delayed_actions = []
		for action in actions:
			delayed_actions.append({ "action": action, "delay": 0.2 })
		ai_self.active_controller.queue_actions(delayed_actions)
		
func record_rule_success_calling_function():
	if current_rule_dict.has("ruleID"):
		rules_base.record_rule_success(current_rule_dict.ruleID)
	return

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
