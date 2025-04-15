extends CharacterBody2D

var Starthp = 100
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 100

@onready var AI_HP = $DummyHP
@onready var animation = $Dummy_Animation
@onready var enemy = get_parent().get_node("Player")
@onready var enemy_animation = enemy.get_node("Animation")

var current_script: Array = []
var rule_engine  # ScriptCreation instance
var rules_base   # Rules instance

func update_facing_direction():
	if enemy.position.x > position.x:
		$AnimatedSprite2D.flip_h = false
		$Dummy_Hitbox.scale.x = 1
		$Dummy_LowerHurtbox.position.x = abs($Dummy_LowerHurtbox.position.x)
		$Dummy_LowerHurtbox.position.x = abs($Dummy_LowerHurtbox.position.x)
	else:
		$AnimatedSprite2D.flip_h = true
		$Dummy_Hitbox.scale.x = -1
		$Dummy_LowerHurtbox.position.x = -abs($Dummy_LowerHurtbox.position.x)
		$Dummy_UpperHurtbox.position.x = -abs($Dummy_UpperHurtbox.position.x)

func _ready():
	AI_HP.value = Starthp
	rules_base = Rules.new()
	rule_engine = ScriptCreation.new(enemy, animation)

func _physics_process(delta):
	update_facing_direction()
	rule_engine.set_ai_reference(self)
	rule_engine.evaluate_and_execute(rules_base.get_rules())
	move_and_slide()
