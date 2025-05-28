# NeuroDynamicController.gd
extends DynamicScriptingController
class_name NeuroDynamicController

# --- Configuration ---
const METRICS_ENDPOINT = "http://0.0.0.0:8000/api/v162/metrics_in"
const MODEL_READY_ENDPOINT = "http://0.0.0.0:8000/api/v162/model_0_0_5/load_model"
const PREDICT_ENDPOINT = "http://0.0.0.0:8000/api/v162/predict"
const PREDICTION_INTERVAL = 0.5  # Seconds between predictions
const REQUEST_TIMEOUT = 1.0      # Seconds before considering request failed

# --- Nodes ---
var http_request: HTTPRequest
var prediction_timer: Timer

# --- State Tracking ---
var is_waiting_response: bool = false
var last_game_state: Dictionary = {}
var last_prediction: Array = []

# func _ready():
# 	# Setup HTTP request
# 	http_request = HTTPRequest.new()
# 	add_child(http_request)
# 	http_request.request_completed.connect(_on_request_completed)
# 	var error = http_request.request(MODEL_READY_ENDPOINT, ["Content-Type: application/json"], HTTPClient.METHOD_POST)
# 	if error != OK:
# 		print("Error sending request: ", error)
# 		return
# 	# Setup prediction timer
# 	prediction_timer = Timer.new()
# 	prediction_timer.wait_time = PREDICTION_INTERVAL
# 	prediction_timer.timeout.connect(_on_prediction_timer)
# 	add_child(prediction_timer)
# 	prediction_timer.start()


func _on_prediction_timer():
	if !is_waiting_response:
		send_game_state()

func collect_params() -> Dictionary:
	var prev_params = {
		"attacks_landed": {
			"lower": fighter.lower_attacks_landed,
			"upper": fighter.upper_attacks_landed,
		},
		"current_hp": opponent_HP.value, # 👈 Add this line
		"defenses": {
			"crouching": fighter.crouching_defenses,
			"standing": fighter.standing_defenses,
		},
		"lower_hits": fighter.lower_hits_taken,
		"upper_hits": fighter.upper_hits_taken,
	}
	return prev_params

func send_game_state():
	if is_waiting_response:
		return
	
	var game_state = collect_params()
	last_game_state = game_state
	
	var json = JSON.stringify(game_state)
	var headers = ["Content-Type: application/json"]
	
	var error = http_request.request(METRICS_ENDPOINT, headers, HTTPClient.METHOD_POST, json)
	if error != OK:
		print("Error sending request: ", error)
		return
	
	is_waiting_response = true
	prediction_timer.start(REQUEST_TIMEOUT)  # Start timeout

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	is_waiting_response = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		print("HTTP request failed. Using fallback behavior.")
		execute_fallback_action()
		return
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		print("Failed to parse JSON response")
		return
	
	var response = json.data
	process_prediction(response.get("predictions", []))

func process_prediction(predictions: Array):
	if predictions.is_empty():
		return
	
	# Assuming predictions are in format: [["action1", probability], ...]
	var sorted_predictions = predictions.duplicate()
	sorted_predictions.sort_custom(func(a, b): return a[1] > b[1])
	
	var best_action = sorted_predictions[0][0]
	execute_ai_action(best_action)

func execute_ai_action(action: String):
	match action:
		"walk_forward":
			fighter.velocity.x = fighter.movement_system.speed
			animation_player.play("walk_forward")
		"walk_backward":
			fighter.velocity.x = -fighter.movement_system.speed
			animation_player.play("walk_backward")
		"basic_punch":
			if fighter.is_on_floor() and !fighter.attack_system.is_attacking:
				fighter.attack_system.handle_punch()
		"basic_kick":
			if fighter.is_on_floor() and !fighter.attack_system.is_attacking:
				fighter.attack_system.handle_kick()
		"jump":
			if fighter.is_on_floor():
				fighter.movement_system.handle_jump()
		"crouch_defense":
			animation_player.play("crouching_defense")
		"standing_defense":
			animation_player.play("standing_defense")
		_:
			animation_player.play("idle")

func execute_fallback_action():
	# Fallback to decision tree or other AI when model is unavailable
	var distance = fighter.global_position.distance_to(opponent.global_position)
	if distance > 150:
		execute_ai_action("walk_forward")
	else:
		execute_ai_action("basic_punch")

#func _physics_process(delta):
	#if !is_waiting_response:
		## Apply basic physics while waiting for predictions
		#fighter.velocity.y += fighter.gravity * delta
		#fighter.move_and_slide()

func _exit_tree():
	if http_request:
		http_request.queue_free()
	if prediction_timer:
		prediction_timer.stop()
		prediction_timer.queue_free()
