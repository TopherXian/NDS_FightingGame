extends Node2D

@onready var label = $TimerLabel
@onready var timer = $Timer

func _ready():
	timer.start()
	
func time_left():
	var time = timer.time_left
	return time

func _process(delta):
	label.text = "%02d" % int(time_left())
