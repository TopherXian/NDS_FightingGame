# GameSettings.gd
# Autoload Singleton (Configure in Project Settings -> Autoload)
extends Node

# Variables to store the selected control types
# Default values are set here but will be overwritten by the main menu selection
var player1_control_type: String = "Human"
var player2_control_type: String = "Dynamic Scripting"

# You can add other global settings here if needed
# e.g., difficulty, round count, etc.
