# NeuroDynamicController.gd
extends DynamicScriptingController
class_name NeuroDynamicController

# --- Configuration ---
const METRICS_ENDPOINT = "http://0.0.0.0:8000/api/v162/metrics_in"
const MODEL_READY_ENDPOINT = "http://0.0.0.0:8000/api/v162/model_0_0_5/load_model"
const PREDICT_ENDPOINT = "http://0.0.0.0:8000/api/v162/predict"
const PREDICTION_INTERVAL = 5  # Seconds between predictions
const METRICS_INTERVAL = 2
const REQUEST_TIMEOUT = 1.0      # Seconds before considering request failed
const HTTP_HEADERS = ["Content-Type: application/json"]

# --- Nodes ---
var prediction_timer: Timer
var metrics_timer: Timer

# --- State Tracking ---
var last_game_state: Dictionary = {}
var last_prediction: Array = []

func _ready():
	# Setup HTTP request
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(MODEL_READY_ENDPOINT, HTTP_HEADERS, HTTPClient.METHOD_POST)
	if error != OK:
		print("Error sending request: ", error)
		return
	# Setup prediction timer
	prediction_timer = Timer.new()
	metrics_timer = Timer.new()
	prediction_timer.wait_time = PREDICTION_INTERVAL
	metrics_timer.wait_time = METRICS_INTERVAL
	prediction_timer.timeout.connect(_on_prediction_timer)
	metrics_timer.timeout.connect(_on_metrics_timer)
	add_child(prediction_timer)
	add_child(metrics_timer)
	prediction_timer.start()
	metrics_timer.start()


func _on_metrics_timer():

	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var game_state = collect_params()
	last_game_state = game_state
	
	var json = JSON.stringify(game_state)
	print_debug(json)
	
	var error = http_request.request(METRICS_ENDPOINT, HTTP_HEADERS, HTTPClient.METHOD_POST, json)
	if error != OK:
		print("Error sending request: ", error)
		return
	

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


func _on_prediction_timer():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(PREDICT_ENDPOINT, HTTP_HEADERS, HTTPClient.METHOD_POST)
	http_request.request_completed.connect(_prediction_req)
	if error != HTTPRequest.RESULT_SUCCESS:
		print_debug(error)
		return
	print_debug(last_prediction)

func _prediction_req(_result, _response_code, _headers, body):
	var weights = JSON.parse_string(body.get_string_from_utf8())
	if weights:
		last_prediction.append(weights.weight_adjustments)
	

func _on_timer_timeout():
	if not is_instance_valid(rules_base):
		print("Rules system not initialized!")
		return

	# Add rule validation
	if rules_base.get_rules().is_empty():
		print("No rules available in rulebase!")
		return
		
	var ai_hp = fighter.get_health()
	var player_hp = opponent.get_health()

		
	if not is_instance_valid(fighter) or not is_instance_valid(rules_base): 
		return

	print("\n=== DS Update Cycle ===")
	print("Current HP: %d/%d" % [fighter.health, fighter.max_health])
	
	# 1. Calculate fitness FIRST
	var fitness = calculate_fitness()
	print("Adapting with fitness: %.2f" % fitness)

	# 2. Apply weight adjustments based on fitness
	rules_base.adjust_script_weights_nds(last_prediction[-1])
	
	# 3. Update rule priorities before generating new script
	rules_base.update_rule_priorities()
	
	# 4. Generate new script AFTER adjustments
	rules_base.generate_script()
	var active_script = rules_base.get_DScript()
	
	# 5. Update internal state
	get_total_weights()
	get_latest_script()
	
	# 6. Logging and cleanup
	log_game_info()
	append_script_to_log()
	reset_counters()

	# (Optional) Debug output
	print("New script contains %d rules" % active_script.size())

func process_prediction(predictions: Array):
	if predictions.is_empty():
		return
	
	# Assuming predictions are in format: [["action1", probability], ...]
	var sorted_predictions = predictions.duplicate()
	sorted_predictions.sort_custom(func(a, b): return a[1] > b[1])
	
	var best_action = sorted_predictions[0][0]

#func _physics_process(delta):
	#if !is_waiting_response:
		## Apply basic physics while waiting for predictions
		#fighter.velocity.y += fighter.gravity * delta
		#fighter.move_and_slide()

func _exit_tree():
	if prediction_timer:
		prediction_timer.stop()
		prediction_timer.queue_free()
