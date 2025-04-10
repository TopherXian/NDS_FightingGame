extends Node
class_name DummyAttack

var player : CharacterBody2D
var enemy : CharacterBody2D
var animation_player : AnimationPlayer
var current_attack : String = ""
var attack_cooldown : float = 0.0
var can_attack : bool = true

# Attack ranges and damage values
const PUNCH_RANGE = 83
const KICK_RANGE = 100
const HEAVY_RANGE = 90

const BASIC_PUNCH_DAMAGE = 10.0
const HEAVY_PUNCH_DAMAGE = 20.0
const BASIC_KICK_DAMAGE = 15.0
const HEAVY_KICK_DAMAGE = 25.0

func _init(anim: AnimationPlayer, enemy_instance: CharacterBody2D, player_char: CharacterBody2D):
	animation_player = anim
	enemy = enemy_instance
	player = player_char
	_connect_animation_signals()

func _connect_animation_signals():
	if not animation_player.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

func perform_attack(attack_type: String) -> bool:
	if not can_attack:
		return false
		
	var distance = enemy.global_position.distance_to(player.global_position)
	
	match attack_type:
		"basic_punch":
			if distance <= PUNCH_RANGE:
				_start_attack("basic_punch", 0.3)
				return true
		"heavy_punch":
			if distance <= HEAVY_RANGE:
				_start_attack("heavy_punch", 0.5)
				return true
		"basic_kick":
			if distance <= KICK_RANGE:
				_start_attack("basic_kick", 0.4)
				return true
		"heavy_kick":
			if distance <= HEAVY_RANGE:
				_start_attack("heavy_kick", 0.6)
				return true
	
	return false

func get_basicAttacks() -> void:
	if not can_attack:
		return
		
	var distance = enemy.global_position.distance_to(player.global_position)
	if distance <= PUNCH_RANGE:
		_start_attack("basic_punch", 0.3)
	elif distance <= KICK_RANGE:
		_start_attack("basic_kick", 0.4)

func get_crouchAttacks() -> void:
	if not can_attack:
		return
		
	var distance = enemy.global_position.distance_to(player.global_position)
	if distance <= PUNCH_RANGE:
		_start_attack("crouch_punch", 0.3)
	elif distance <= KICK_RANGE:
		_start_attack("crouch_kick", 0.4)

func _start_attack(attack_name: String, cooldown: float) -> void:
	current_attack = attack_name
	can_attack = false
	attack_cooldown = cooldown
	animation_player.play(attack_name)

func update_attack_cooldown(delta: float) -> void:
	if not can_attack:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true
			attack_cooldown = 0.0
			if current_attack != "":
				current_attack = ""
				# Only play idle if not already in another animation
				if animation_player.current_animation == current_attack:
					animation_player.play("idle")

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == current_attack:
		# Animation finished but might still be in cooldown
		if attack_cooldown <= 0:
			current_attack = ""
			can_attack = true
			animation_player.play("idle")

func get_current_attack() -> String:
	return current_attack

func is_attacking() -> bool:
	return current_attack != ""

# Utility function to get attack damage
func get_attack_damage(attack_type: String) -> float:
	match attack_type:
		"basic_punch", "crouch_punch":
			return BASIC_PUNCH_DAMAGE
		"heavy_punch":
			return HEAVY_PUNCH_DAMAGE
		"basic_kick", "crouch_kick":
			return BASIC_KICK_DAMAGE
		"heavy_kick":
			return HEAVY_KICK_DAMAGE
		_:
			return 0.0
