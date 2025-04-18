extends Node
class_name ScriptCreation

var player
var player_anim
var animation
var ai_self

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
			print(ruleID)
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
		"crouch_defense":
			if animation.current_animation != "crouch_defense": animation.play("crouch_defense")
			ai_self.velocity.x = 0
		"jump":
			if ai_self.is_on_floor():
				if animation.current_animation != "jump": animation.play("jump")
				ai_self.velocity.y = -400
		_:
			animation.play("basic_punch")
		
func script_generation():
#	GENERATES THE SCRIPT UP TO MAX_SCRIPT
	pass
