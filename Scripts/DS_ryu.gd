extends CharacterBody2D

var Starthp = 100
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 100

var lower_hits := 0
var upper_hits := 0
var lower_attacks := 0
var upper_attacks := 0
var standing_defense := 0
var crouching_defense := 0

const HITBOX_NAME: StringName = &"Hitbox"
const STANDING_DEFENSE_ANIM: StringName = &"standing_defense"
const CROUCHING_DEFENSE_ANIM: StringName = &"crouching_defense"

@export var defense_damage: int = 7
@export var normal_damage: int = 10

@onready var AI_HP = $DummyHP
@onready var enemy_animation = $Dummy_Animation
@onready var player = get_parent().get_node("Player")
@onready var player_animation = player.get_node("Animation")
@onready var opp_hit_taken = get_parent().get_node("OpponentDetails") 
@export var update_interval : float = 4.0
var _update_timer: Timer
var rule_engine  # ScriptCreation instance
var rules_base   # Rules instance
var damageClass: DummyDamaged

func _update_hit_text():
	opp_hit_taken.text = "Lower Hits Taken: %d
	\nUpper Hits Taken: %d
	\nLower Attacks Hit: %d
	\nUpper Attacks Hit: %d
	\nStanding Defense: %d
	\nCrouching Defense: %d" % [lower_hits, upper_hits, lower_attacks, upper_attacks, standing_defense, crouching_defense]

func update_facing_direction():
	if player.position.x > position.x:
		$AnimatedSprite2D.flip_h = false  # Face right
		#$Dummy_Hitbox.position.x = abs($Dummy_Hitbox.position.x)
		#$DS_Hitbox_Container.scale.x = 1
		$Dummy_LowerHurtbox.position.x = abs($Dummy_LowerHurtbox.position.x)
		$Dummy_UpperHurtbox.position.x = abs($Dummy_UpperHurtbox.position.x)
	else:
		$AnimatedSprite2D.flip_h = true   # Face left
		$Dummy_Hitbox.position.x = -abs($Dummy_Hitbox.position.x)
		#$DS_Hitbox_Container.scale.x = -1
		$Dummy_LowerHurtbox.position.x = -abs($Dummy_LowerHurtbox.position.x)
		$Dummy_UpperHurtbox.position.x = -abs($Dummy_UpperHurtbox.position.x)

func _ready():
	$DummyHP.value = Starthp
	damageClass = DummyDamaged.new()
	damageClass.init($Dummy_Animation, $DummyHP, self)
	
	rules_base = Rules.new()
	rule_engine = ScriptCreation.new(player, enemy_animation)
	rule_engine.set_ai_reference(self)
	_process_timer()

func _physics_process(delta):
	update_facing_direction()
	if not is_on_floor():
		velocity.y += gravity * delta
	rule_engine.evaluate_and_execute(rules_base.get_DScript())
	#print(rule_engine.evaluate_and_execute(rules_base.get_rules()))
	move_and_slide()
	

func _on_dummy_lower_hurtbox_area_entered(area: Area2D) -> void:
	if area.name != HITBOX_NAME:
		return
	match enemy_animation.current_animation:
		STANDING_DEFENSE_ANIM:
			damageClass.take_damage(defense_damage)
			standing_defense += 1
		CROUCHING_DEFENSE_ANIM:
			damageClass.take_damage(defense_damage)
			crouching_defense += 1
		_:
			damageClass.take_damage(normal_damage)
			
	upper_hits += 1
	_update_hit_text()

func _on_dummy_upper_hurtbox_area_entered(area: Area2D) -> void:
	if area.name != HITBOX_NAME:
		return
	match enemy_animation.current_animation:
		STANDING_DEFENSE_ANIM:
			damageClass.take_damage(defense_damage)
			standing_defense += 1
		CROUCHING_DEFENSE_ANIM:
			damageClass.take_damage(defense_damage)
			crouching_defense += 1
		_:
			damageClass.take_damage(normal_damage)
			
	upper_hits += 1
	_update_hit_text()
		

func _on_dummy_hitbox_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area.name == "Upper_Hurtbox":
		upper_attacks += 1
	elif area.name == "Lower_Hurtbox":
		lower_attacks += 1
	pass # Replace with function body.


func _process_timer():
	_update_timer = Timer.new()
	_update_timer.name = "ScriptUpdateTimer" # add timer identity

	_update_timer.wait_time = update_interval
	_update_timer.one_shot = false
	#_update_timer.autostart = true # Start immediately when ready

	# Connect the timeout signal to our update function
	_update_timer.timeout.connect(_on_update_timer_timeout)

	# 4. Add the Timer accs a child of this node so it gets processed by the scene tree
	add_child(_update_timer)

	# Start the timer (if autostart is false or you want to control it)
	_update_timer.start()

	# Generate the first script immediately so it's not empty at the start
	rules_base.generate_and_update_script() 
	print("Rules node ready. Initial script generated.")

func _exit_tree():
	if _update_timer and _update_timer.is_connected("timeout", Callable(self,"_on_update_timer_timeout")):
		_update_timer.timeout.disconnect(Callable(self,"_on_update_timer_timeout"))

# --- Timer Callback Function ---
func _on_update_timer_timeout():
	print("Timer timeout: Updating AI script...")
#	LOWER AND UPPER SUCCESSFUL ATTACKS AND HITS TAKEN AS METRICS, 100 AS THE FULL HP
	var fitness = rule_engine.calculate_fitness(lower_hits, upper_hits, upper_attacks, lower_attacks, standing_defense, crouching_defense, 100)
	print(fitness)
	var script = rules_base.get_DScript()
	rule_engine.adjust_script_weights(script, fitness)
	
	lower_hits = 0
	upper_hits = 0
	upper_attacks = 0
	lower_attacks = 0
	standing_defense = 0
	crouching_defense = 0
	_update_hit_text()
	
	#rules_base.generate_and_update_script()
	#for r in rules_base.generate_and_update_script():
		#r["wasUsed"] = int(randomize(0))
