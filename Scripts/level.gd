extends Node2D

@onready var label = $TimerLabel
@onready var timer = $Timer
@onready var playermetrics = $PlayerDetails
@onready var AImetrics = $OpponentDetails

@onready var playerLowerHurttbox = $Player/Lower_Hurtbox
@onready var playerUpperHurttbox = $Player/Upper_Hurtbox
@onready var playerHitbox = $Player/Hitbox_Container/Hitbox

@onready var AILowerHurtbox = $Dummy_Ryu/Dummy_LowerHurtbox
@onready var AIUpperHurtbox = $Dummy_Ryu/Dummy_UpperHurtbox
@onready var AIHitbox = $Dummy_Ryu/Dummy_Hitbox

func _ready():
	timer.start()
		
	
func time_left():
	var time = timer.time_left
	return time

func _process(_delta):
	label.text = "%02d" % int(time_left())
