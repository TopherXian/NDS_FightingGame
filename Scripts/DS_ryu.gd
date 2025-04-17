extends CharacterBody2D

var Starthp = 100
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 100


@onready var AI_HP = $DummyHP
@onready var enemy_animation = $Dummy_Animation
@onready var player = get_parent().get_node("Player")
@onready var player_animation = player.get_node("Animation")

@export var update_interval : float = 4.0
var _update_timer: Timer
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
	_process_timer()

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
		

func _process_timer():
	_update_timer = Timer.new()
	_update_timer.name = "ScriptUpdateTimer" # add timer identity

	_update_timer.wait_time = update_interval
	_update_timer.one_shot = false
	#_update_timer.autostart = true # Start immediately when ready

	# Connect the timeout signal to our update function
	_update_timer.timeout.connect(_on_update_timer_timeout)

	# 4. Add the Timer as a child of this node so it gets processed by the scene tree
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
	rules_base.generate_and_update_script()
	
