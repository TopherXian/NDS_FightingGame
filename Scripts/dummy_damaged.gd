extends Node
class_name DummyDamaged

var anim_player: AnimationPlayer
var hp_bar: ProgressBar
var enemy: CharacterBody2D
var is_stunned: bool = false
var stun_timer: float = 0.0
var recovery_timer: float = 0.0
var is_in_recovery: bool = false

# Damage and stun configuration
const LIGHT_HIT_STUN = 0.2
const MEDIUM_HIT_STUN = 0.4
const HEAVY_HIT_STUN = 0.6
const KNOCKDOWN_STUN = 1.0

const LIGHT_DAMAGE = 10.0
const MEDIUM_DAMAGE = 15.0
const HEAVY_DAMAGE = 20.0

const KNOCKBACK_FORCE = 150.0
const KNOCKBACK_UP_FORCE = -100.0

func init(anim: AnimationPlayer, hp: ProgressBar, enemy_instance: CharacterBody2D):
	anim_player = anim
	hp_bar = hp
	enemy = enemy_instance
	_connect_animation_signals()

func _connect_animation_signals():
	if not anim_player.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		anim_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

func take_damage(damage: float = LIGHT_DAMAGE, attacker_position: Vector2 = Vector2.ZERO) -> void:
	# Apply damage
	hp_bar.value -= damage
	
	# Determine hit intensity
	var hit_intensity = _get_hit_intensity(damage)
	
	# Calculate knockback
	var knockback_direction = (enemy.global_position - attacker_position).normalized()
	var knockback = knockback_direction * KNOCKBACK_FORCE * hit_intensity
	
	# Apply knockback with proper vertical force
	enemy.velocity.x = knockback.x
	enemy.velocity.y = KNOCKBACK_UP_FORCE * hit_intensity
	
	# Set stun duration based on hit intensity
	_apply_stun(hit_intensity)
	
	# Play appropriate hit animation
	_play_hit_animation(hit_intensity)

func update(delta: float) -> void:
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			if hp_bar.value > 0:  # Only recover if still alive
				_start_recovery()
			else:
				_play_knocked_down()
	
	if is_in_recovery:
		recovery_timer -= delta
		if recovery_timer <= 0:
			is_in_recovery = false
			_complete_recovery()

func _get_hit_intensity(damage: float) -> float:
	if damage >= HEAVY_DAMAGE:
		return 1.0
	elif damage >= MEDIUM_DAMAGE:
		return 0.7
	else:
		return 0.5

func _apply_stun(intensity: float) -> void:
	is_stunned = true
	if intensity >= 1.0:
		stun_timer = HEAVY_HIT_STUN
	elif intensity >= 0.7:
		stun_timer = MEDIUM_HIT_STUN
	else:
		stun_timer = LIGHT_HIT_STUN

func _play_hit_animation(intensity: float) -> void:
	if hp_bar.value <= 0:
		anim_player.play("knocked_down")
	elif intensity >= 1.0:
		anim_player.play("heavy_hit")
	else:
		anim_player.play("hurt")

func _start_recovery() -> void:
	is_in_recovery = true
	recovery_timer = 0.2
	anim_player.play("recovery")

func _complete_recovery() -> void:
	if hp_bar.value > 0:
		anim_player.play("idle")

func _play_knocked_down() -> void:
	anim_player.play("knocked_down")

func _on_animation_finished(anim_name: String) -> void:
	match anim_name:
		"hurt", "heavy_hit":
			if not is_stunned and hp_bar.value > 0:
				_start_recovery()
		"recovery":
			if not is_stunned and hp_bar.value > 0:
				anim_player.play("idle")
		"knocked_down":
			if hp_bar.value > 0:
				_start_recovery()

# Getters for state checking
func is_currently_stunned() -> bool:
	return is_stunned

func is_currently_recovering() -> bool:
	return is_in_recovery

func get_remaining_stun_time() -> float:
	return stun_timer if is_stunned else 0.0

func get_current_hp_percent() -> float:
	return hp_bar.value / hp_bar.max_value
