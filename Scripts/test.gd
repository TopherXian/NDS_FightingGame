extends CharacterBody2D

var Starthp = 100
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Reference to the enemy character
@onready var enemy = get_parent().get_node("Player")

func _ready():
	$DummyHP.value = Starthp
	
func update_facing_direction():
	if enemy.position.x > position.x:
		$AnimatedSprite2D.flip_h = false  # Face right
	else:
		$AnimatedSprite2D.flip_h = true   # Face left
	
func _physics_process(delta):
	update_facing_direction()
	if not is_on_floor():
		velocity.y += gravity * delta	
	move_and_slide()

func _on_dummy_upper_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		$DummyHP.value -= 10
		$Dummy_Animation.play("hurt")
		_connect_animation_physics()
	if $DummyHP.value <= 0:
		knocked_down()
	else:
		_connect_animation_physics()


func _on_dummy_lower_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		$DummyHP.value -= 10
		$Dummy_Animation.play("hurt")
		_connect_animation_physics()
	if $DummyHP.value <= 0:
		knocked_down()
	else:
		_connect_animation_physics()
		
func _connect_animation_physics():
	if not $Dummy_Animation.is_connected("animation_finished", Callable(self, "on_hurt_finished")):
		$Dummy_Animation.connect("animation_finished", Callable(self, "on_hurt_finished"))
		
func on_hurt_finished(animation):
	$Dummy_Animation.play("idle")
	
func knocked_down():
	$Dummy_Animation.play("knocked_down")
