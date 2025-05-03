# GameSettings.gd
# Autoload Singleton (Configure in Project Settings -> Autoload)
extends Node

var player1_control_type: String = "Human"
var player2_control_type: String = "Dynamic Scripting"

var match_count: int = 1
var round_active: bool = true
