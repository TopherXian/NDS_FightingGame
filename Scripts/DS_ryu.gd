extends CharacterBody2D

var Starthp = 100
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 100


@onready var AI_HP = $DummyHP
@onready var enemy_animation = $Dummy_Animation
@onready var player = get_parent().get_node("Player")
@onready var player_animation = player.get_node("Animation")

var current_script: Array = []
var rule_engine  # ScriptCreation instance
var rules_base   # Rules instance
var damageClass: DummyDamaged


func update_facing_direction():
	if player.position.x > position.x:
		$AnimatedSprite2D.flip_h = false  # Face right
		$Dummy_Hitbox.position.x = abs($Dummy_Hitbox.position.x)
		$Dummy_LowerHurtbox.position.x = abs($Dummy_LowerHurtbox.position.x)
		$Dummy_UpperHurtbox.position.x = abs($Dummy_UpperHurtbox.position.x)
	else:
		$AnimatedSprite2D.flip_h = true   # Face left
		$Dummy_Hitbox.position.x = -abs($Dummy_Hitbox.position.x)
		$Dummy_LowerHurtbox.position.x = -abs($Dummy_LowerHurtbox.position.x)
		$Dummy_UpperHurtbox.position.x = -abs($Dummy_UpperHurtbox.position.x)

func _ready():
	$DummyHP.value = Starthp
	damageClass = DummyDamaged.new()
	damageClass.init($Dummy_Animation, $DummyHP, self)
	rules_base = Rules.new()
	rule_engine = ScriptCreation.new(player, enemy_animation)

func _physics_process(delta):
	update_facing_direction()
	if not is_on_floor():
		velocity.y += gravity * delta
	rule_engine.set_ai_reference(self)
	rule_engine.evaluate_and_execute(rules_base.get_rules())
	#print(rule_engine.evaluate_and_execute(rules_base.get_rules()))
	move_and_slide()
	
func _on_dummy_lower_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		damageClass.take_damage()
		
func _on_dummy_upper_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		damageClass.take_damage()
