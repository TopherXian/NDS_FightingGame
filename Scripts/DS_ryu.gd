extends CharacterBody2D

var Starthp = 100
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 100
@onready var AI_HP = $DS_HP
@onready var animation = $DS_Animation

# Reference to the enemy character
@onready var enemy = get_parent().get_node("Player")
@onready var enemy_animation = enemy.get_node("Animation")

var ruleStorage: RuleBase



func update_facing_direction():
	if enemy.position.x > position.x:
		$AnimatedSprite2D.flip_h = false  # Face right
		$DS_Hitbox_Container.scale.x = 1
		$DS_LowerHurtbox.position.x = abs($DS_LowerHurtbox.position.x)
		$DS_UpperHurtbox.position.x = abs($DS_UpperHurtbox.position.x)
	else:
		$AnimatedSprite2D.flip_h = true   # Face left
		$DS_Hitbox_Container.scale.x = -1
		$DS_LowerHurtbox.position.x = -abs($DS_LowerHurtbox.position.x)
		$DS_UpperHurtbox.position.x = -abs($DS_UpperHurtbox.position.x)
		
func _ready():
	AI_HP.value = Starthp
	ruleStorage = RuleBase.new(animation, self, enemy, enemy_animation)
	
func _physics_process(delta):
	update_facing_direction()
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()
