extends Node
class_name ScriptCreation

var player
var player_anim
var animation
var ai_self

var max_script = 6
var speed = 200

func _init(enemy_ref, playerAnim_ref, enemy_anim):
	player = enemy_ref
	player_anim = playerAnim_ref
	animation = enemy_anim

func set_ai_reference(ref):
	ai_self = ref

func evaluate_and_execute(rules: Array):
	var current_anim = player_anim.current_animation
	var dist = ai_self.global_position.distance_to(player.global_position)

	for rule in rules:
		var conditions = rule["conditions"]
		var ruleID = rule["ruleID"]
		var match_anim = false
		var match_dist = false

		if "player_anim" in conditions:
			match_anim = (conditions["player_anim"] == current_anim)

		if "distance" in conditions:
			var op = conditions["distance"]["op"]
			var value = conditions["distance"]["value"]
			match_dist = compare_distance(op, dist, value)

		if match_anim and match_dist:
			_execute_action(rule["enemy_action"])
			print(ruleID)
			break

func compare_distance(op: String, dist: float, value: float) -> bool:
	match op:
		">=":
			return dist >= value
		"<=":
			return dist <= value
		">":
			return dist > value
		"<":
			return dist < value
		"==":
			return dist == value
		_:
			return false

func _execute_action(action: String):
	match action:
		"walk_forward":
			animation.play("walk_forward")
			ai_self.velocity.x = -speed
		"walk_backward":
			animation.play("walk_backward")
			ai_self.velocity.x = speed
		"basic_kick":
			animation.play("basic_kick")
		"basic_punch":
			animation.play("basic_punch")
		"standing_defense":
			animation.play("standing_defense")
		"crouch_defense":
			animation.play("crouch_defense")
		"jump":
			animation.play("jump")
		_:
			print("Unknown action: ", action)

func script_generation():
#	GENERATES THE SCRIPT UP TO MAX_SCRIPT
	pass
