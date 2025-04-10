extends CharacterBody2D

var Starthp = 100
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 100

# CLASSES
var movementClass: DummyMovement
var attackClass: DummyAttack
var damageClass: DummyDamaged

# Reference to the enemy character
@onready var enemy = get_parent().get_node("Player")
@onready var enemy_animation = enemy.get_node("Animation")
func _ready():
	$DummyHP.value = Starthp
	damageClass = DummyDamaged.new()
	damageClass.init($Dummy_Animation, $DummyHP, self)
	movementClass = DummyMovement.new($Dummy_Animation, self, enemy)
	attackClass = DummyAttack.new($Dummy_Animation, self, enemy)

func _on_dummy_lower_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		damageClass.take_damage()
		
func _on_dummy_upper_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		damageClass.take_damage()

func update_facing_direction():
	if enemy.position.x > position.x:
		$AnimatedSprite2D.flip_h = false  # Face right
		$Dummy_Hitbox_Container.scale.x = 1
		$Dummy_LowerHurtbox.position.x = abs($Dummy_LowerHurtbox.position.x)
		$Dummy_UpperHurtbox.position.x = abs($Dummy_UpperHurtbox.position.x)
		movementClass.dummy_move(speed)
	else:
		$AnimatedSprite2D.flip_h = true   # Face left
		$Dummy_Hitbox_Container.scale.x = -1
		$Dummy_LowerHurtbox.position.x = -abs($Dummy_LowerHurtbox.position.x)
		$Dummy_UpperHurtbox.position.x = -abs($Dummy_UpperHurtbox.position.x)
		movementClass.dummy_move(-speed)
		
	
func _physics_process(delta):
	update_facing_direction()
	if not is_on_floor():
		velocity.y += gravity * delta
	if $DummyHP.value > 0:
		if enemy_animation.current_animation == "crouch":
			attackClass.get_crouchAttacks()
		else:
			attackClass.get_basicAttacks()
	move_and_slide()
