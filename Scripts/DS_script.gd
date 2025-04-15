extends Node
class_name ScriptCreation

var enemy
var anim
var ai_self

var speed = 200

func _init(enemy_ref, anim_ref):
	enemy = enemy_ref
	anim = anim_ref

func set_ai_reference(ref):
	ai_self = ref

func evaluate_and_execute(rules: Array):
	var current_anim = enemy.animation.current_animation
	var dist = ai_self.global_position.distance_to(enemy.global_position)

	for rule in rules:
		var conditions = rule["conditions"]
		var match_anim = true
		var match_dist = true

		if "player_anim" in conditions:
			match_anim = (conditions["player_anim"] == current_anim)

		if "distance" in conditions:
			var op = conditions["distance"]["op"]
			var value = conditions["distance"]["value"]
			match_dist = compare_distance(op, dist, value)

		if match_anim and match_dist:
			_execute_action(rule["enemy_action"])
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
			anim.play("walk_forward")
			ai_self.velocity.x = -speed
		"walk_backward":
			anim.play("walk_backward")
			ai_self.velocity.x = speed
		"basic_kick":
			anim.play("basic_kick")
		"basic_punch":
			anim.play("basic_punch")
		"standing_defense":
			anim.play("standing_defense")
		"crouch_defense":
			anim.play("crouch_defense")
		"jump":
			anim.play("jump")
		_:
			print("Unknown action: ", action)
