# Rules.gd
extends Node
class_name Rules

var script_size: int = 14

# New variables for HP-based adaptation
var hp_difference_momentum: float = 0.0
var last_ai_hp: float = 100.0
var last_player_hp: float = 100.0
const HP_MOMENTUM_WEIGHT: float = 0.3  # Impact of HP changes on rule weights

var rule_success_counts = {}

# --- Configuration ---
const INITIAL_WEIGHT: float = 0.5
const WEIGHT_DECAY: float = 0.15      # Penalty for recently used rules
const WEIGHT_RECOVERY: float = 0.02   # Global recovery rate
const FITNESS_REWARD: float = 0.12    # Reward multiplier for successful rules
const PRIORITY_DECAY_TIME: float = 5.0 # Seconds until priority boost decays

var _current_script: Array = []
var _last_used_rules: Array = []
var _rule_usage_times: Dictionary = {}  # Tracks last usage timestamps
var weight_history: Array = []

var rules = [
	{
		"ruleID": 1, "prioritization": 1,
		"conditions": { "distance": { "op": ">=", "value": 90 } },
		"enemy_action": ["walk_forward"], "weight": 0.5, "wasUsed": false, "inScript": false, "history": []
	},
	{
		"ruleID": 2, "prioritization": 11,
		"conditions": { "distance": { "op": "<=", "value": 90 }},
		"enemy_action": ["basic_kick"], "weight": 0.5, "wasUsed": false, "inScript": false, "history": []
	},
	{
		"ruleID": 3, "prioritization": 12,
		"conditions": { "distance": { "op": "<=", "value": 75 } },
		"enemy_action": ["basic_punch"], "weight": 0.5, "wasUsed": false, "inScript": false, "history": []
	},
	{
		"ruleID": 4, "prioritization": 21,
		"conditions": { "player_anim": "basic_kick", "distance": { "op": ">=", "value": 90 }, "upper_hits_taken": { "op": ">=", "value": 1 } },
		"enemy_action": ["standing_defense"], "weight": 0.5, "wasUsed": false, "inScript": false, "history": []
	},
	{
		"ruleID": 5, "prioritization": 22,
		"conditions": { "player_anim": "basic_punch", "distance": { "op": ">=", "value": 75 }, "upper_hits_taken": { "op": ">=", "value": 1 } },
		"enemy_action": ["standing_defense"], "weight": 0.5, "wasUsed": false, "inScript": false, "history": []
	},
	{
		"ruleID": 6, "prioritization": 24,
		"conditions": { "player_anim": "crouch_punch", "distance": { "op": ">=", "value": 75 }, "lower_hits_taken": { "op": ">=", "value": 1 } },
		"enemy_action": ["crouching_defense"], "weight": 0.5, "wasUsed": false, "inScript": false, "history": []
	},
	{
		"ruleID": 7, "prioritization": 23,
		"conditions": { "player_anim": "crouch_kick", "distance": { "op": ">=", "value": 60 }, "lower_hits_taken": { "op": ">=", "value": 1 } },
		"enemy_action": ["crouching_defense"], "weight": INITIAL_WEIGHT, "wasUsed": false, "inScript": false, "history": []
	},
	{
		"ruleID": 8, "prioritization": 31,
		"conditions": { "player_anim": "crouch_punch", "distance": { "op": ">=", "value": 75 }, "lower_hits_taken": { "op": ">=", "value": 3 } },
		"enemy_action": ["crouching_defense", "crouch_punch"], "weight": INITIAL_WEIGHT, "wasUsed": false, "inScript": false, "history": []
	},
	{
		"ruleID": 9, "prioritization": 32,
		"conditions": { "player_anim": "crouch_kick", "distance": { "op": ">=", "value": 60 }, "lower_hits_taken": { "op": ">=", "value": 3 } },
		"enemy_action": ["crouching_defense", "crouch_kick"], "weight": INITIAL_WEIGHT, "wasUsed": false, "inScript": false, "history": []
	},
	{
		"ruleID": 10,
		"prioritization": 99,
		"conditions": {
			"distance_from_corner": {"op": "<=", "value": 83},
			"player_anim": "!knocked_down"  # Only trigger if player is active
		},
		"enemy_action": ["corner_escape"],
		"weight": INITIAL_WEIGHT + 0.3,
		"wasUsed": false,
		"inScript": false, "history": []
	},

	{
		"ruleID": 11, "prioritization": 33,
		"conditions": { "player_anim": "basic_punch", "distance": { "op": ">=", "value": 75 }, "upper_hits_taken": { "op": ">=", "value": 3 } },
		"enemy_action": ["standing_defense", "basic_punch"], "weight": INITIAL_WEIGHT, "wasUsed": false, "inScript": false, "history": []
	},
	{
		"ruleID": 12, "prioritization": 34,
		"conditions": { "player_anim": "basic_kick", "distance": { "op": ">=", "value": 90 }, "upper_hits_taken": { "op": ">=", "value": 3 } },
		"enemy_action": ["standing_defense", "basic_kick"], "weight": INITIAL_WEIGHT, "wasUsed": false, "inScript": false, "history": []
	},
	{
		"ruleID": 13, "prioritization": 2,
		"conditions": { "distance": { "op": "<=", "value": 80 }, "lower_hits_taken": { "op": ">=", "value": 3 } },
		"enemy_action": ["walk_backward"], "weight": INITIAL_WEIGHT, "wasUsed": false, "inScript": false, "history": []
	},
	{
		"ruleID": 14, "prioritization": 100,
		"conditions": { "player_anim": "idle" },
		"enemy_action": ["idle"], "weight": INITIAL_WEIGHT, "wasUsed": false, "inScript": false, "history": []
	},

	#{
		#"ruleID": 1, "prioritization": 50,
		#"conditions": { "player_anim": "walk_forward", "distance": { "op": ">=", "value": 100 }, "upper_hits_taken": { "op": ">=", "value": 1 } },
		#"enemy_action": ["walk_forward"], "weight": 0.6, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 2, "prioritization": 10,
		#"conditions": { "player_anim": "walk_forward", "distance": { "op": "<=", "value": 80 }, "upper_attacks_landed": { "op": ">=", "value": 0 }, "lower_attacks_landed": { "op": ">=", "value": 0 } },
		#"enemy_action": ["basic_kick"], "weight": INITIAL_WEIGHT, "wasUsed": false, "inScript": false # Increased weight
	#},
	#{
		#"ruleID": 3, "prioritization": 70,
		#"conditions": { "player_anim": "basic_punch", "distance": { "op": "<=", "value": 50 }, "upper_hits_taken": { "op": ">=", "value": 1 } },
		#"enemy_action": ["walk_backward"], "weight": 0.8, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 4, "prioritization": 80,
		#"conditions": { "player_anim": "basic_kick", "distance": { "op": "<=", "value": 100 }, "upper_hits_taken": { "op": ">=", "value": 1 } },
		#"enemy_action": ["standing_defense"], "weight": 0.9, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 6, "prioritization": 85,
		#"conditions": { "player_anim": "crouch_kick", "distance": { "op": "<=", "value": 100 } },
		#"enemy_action": ["crouching_defense"], "weight": 0.9, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 7, "prioritization": 32,
		#"conditions": { "player_anim": "crouch_punch", "distance": { "op": "<=", "value": 83 }, "upper_hits_taken": { "op": ">=", "value": 0 }, "lower_hits_taken": { "op": ">=", "value": 1 } },
		#"enemy_action": ["crouching_defense"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 10, "prioritization": 90,
		#"conditions": { "player_anim": "jump", "distance": { "op": "<=", "value": 100 } },
		#"enemy_action": ["basic_kick"], "weight": 0.6, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 11, "prioritization": 95,
		#"conditions": { "player_anim": "jump", "distance": { "op": "<=", "value": 83 } },
		#"enemy_action": ["basic_punch"], "weight": 0.7, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 12, "prioritization": 65,
		#"conditions": { "player_anim": "walk_backward", "distance": { "op": ">=", "value": 80 } },
		#"enemy_action": ["walk_forward"], "weight": 0.7, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 13, "prioritization": 75,
		#"conditions": { "player_anim": "standing_defense", "distance": { "op": "<=", "value": 70 }, "upper_attacks_landed": { "op": ">=", "value": 1 } },
		#"enemy_action": ["basic_punch"], "weight": 0.6, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 14,
		#"conditions": { "player_anim": "crouching_defense", "distance": { "op": "<=", "value": 90 }, "upper_hits": { "op": "<=", "value": 1 }, "lower_hits": { "op": ">=", "value": 1 } },
		#"enemy_action": ["basic_kick"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 15,
		#"conditions": { "player_anim": "walk_forward", "distance": { "op": ">=", "value": 150 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		#"enemy_action": ["jump"], "weight": 0., "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 16, "prioritization": 60,
		#"conditions": { "player_anim": "basic_punch", "distance": { "op": "<=", "value": 60 }, "upper_attacks_landed": { "op": "==", "value": 0 } },
		#"enemy_action": ["basic_punch"], "weight": 0.6, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 17, "prioritization": 23, 
		#"conditions": { "player_anim": "basic_kick", "distance": { "op": "<=", "value": 110 }, "upper_hits_taken": { "op": ">=", "value": 1 }, "lower_hits_taken": { "op": ">=", "value": 0 } },
		#"enemy_action": ["walk_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 18,
		#"conditions": { "player_anim": "jump", "distance": { "op": ">=", "value": 120 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		#"enemy_action": ["walk_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 19, "prioritization": 55,
		#"conditions": { "player_anim": "crouch_punch", "distance": { "op": "<=", "value": 70 }, "lower_hits_taken": { "op": ">=", "value": 2 } },
		#"enemy_action": ["jump"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 20,
		#"conditions": { "player_anim": "walk_forward", "distance": { "op": "<=", "value": 130 }, "upper_hits": { "op": ">=", "value": 2 }, "lower_hits": { "op": "<=", "value": 1 } },
		#"enemy_action": ["standing_defense"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 21, "prioritization": 33,
		#"conditions": { "player_anim": "hurt", "distance": { "op": "<=", "value": 100 }, "upper_attacks_landed": { "op": ">=", "value": 2 }, "lower_attacks_landed": { "op": ">=", "value": 2 } },
		#"enemy_action": ["walk_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 22,
		#"conditions": { "player_anim": "basic_kick", "distance": { "op": ">=", "value": 130 }, "upper_hits": { "op": "==", "value": 0 }, "lower_hits": { "op": "==", "value": 0 } },
		#"enemy_action": ["walk_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 13, "prioritization": 12,
		#"conditions": { "player_anim": "basic_kick", "distance": { "op": ">=", "value": 100 }, "upper_attacks_landed": { "op": ">=", "value": 0 }, "lower_attacks_landed": { "op": ">=", "value": 1 } },
		#"enemy_action": ["crouch_punch"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 25, "prioritization": 13,
		#"conditions": { "player_anim": "basic_punch", "distance": { "op": ">=", "value": 83 }, "upper_attacks_landed": { "op": ">=", "value": 0 }, "lower_attacks_landed": { "op": ">=", "value": 1 } },
		#"enemy_action": ["crouch_punch"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 26, "prioritization": 14,
		#"conditions": { "player_anim": "basic_punch", "distance": { "op": ">=", "value": 100 }, "upper_attacks_landed": { "op": "==", "value": 0 }, "lower_attacks_landed": { "op": ">=", "value": 1 } },
		#"enemy_action": ["crouch_kick"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 27, "prioritization": 34,
		#"conditions": { "player_anim": "basic_punch", "distance": { "op": ">=", "value": 90 }, "upper_hits_taken": { "op": ">=", "value": 1 }, "lower_hits_taken": { "op": "==", "value": 0 } },
		#"enemy_action": ["standing_defense"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 28, "prioritization": 35,
		#"conditions": { "player_anim": "basic_kick", "distance": { "op": ">=", "value": 80 }, "upper_hits_taken": { "op": ">=", "value": 1 }, "lower_hits_taken": { "op": "==", "value": 0 } },
		#"enemy_action": ["standing_defense"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 30, "prioritization": 100,
		#"conditions": { 
			#"player_anim": "basic_kick", 
			#"distance": { "op": "<=", "value": 94 },
			#"upper_hits_taken": { "op": ">=", "value": 2 }
		#},
		#"enemy_action": ["jump", "walk_forward"], 
		#"weight": 0.8, 
		#"wasUsed": false, 
		#"inScript": false
	#},
		#{
		#"ruleID": 31, "prioritization": 100,
		#"conditions": { 
			#"player_anim": "basic_punch", 
			#"distance": { "op": "<=", "value": 94 },
			#"upper_hits_taken": { "op": ">=", "value": 2 }
		#},
		#"enemy_action": ["jump", "walk_forward"], 
		#"weight": 0.8, 
		#"wasUsed": false, 
		#"inScript": false
	#}
]

func initialize_rules():
	# Add initial randomness to weights
	for rule in rules:
		rule["weight"] = clamp(
			INITIAL_WEIGHT + randf_range(-0.1, 0.1),
			0.1,  # Minimum weight
			1.0   # Maximum weight
		)
		_rule_usage_times[rule["ruleID"]] = 0.0
		rule["in_script"] = false
		_log_weight_change(rule, "INIT", rule.weight)
		
		rule_success_counts[rule.ruleID] = {"hits": 0, "uses": 0}

		
func generate_script() -> Array:
	update_rule_priorities()  # Apply time-based adjustments
	
	for rule in rules:
		rule["in_script"] = false
	
	# Convert weights to probabilities using softmax
	var total_weight = 0.0
	for rule in rules:
		total_weight += exp(rule["weight"])
	
	var selected_rules = []
	var remaining_rules = rules.duplicate()
	
	while selected_rules.size() < script_size and remaining_rules.size() > 0:
		var rand_val = randf() * total_weight
		var cumulative = 0.0
		
		for rule in remaining_rules:
			cumulative += exp(rule["weight"])
			if cumulative >= rand_val:
				selected_rules.append(rule)
				remaining_rules.erase(rule)
				total_weight -= exp(rule["weight"])
				_rule_usage_times[rule["ruleID"]] = Time.get_ticks_msec()
				break
	
	_last_used_rules = selected_rules.duplicate()
	_current_script = selected_rules
	for rule in selected_rules:
		rule["in_script"] = true
		_log_weight_change(rule, "SCRIPT_SELECTION", rule.weight)
	
	return selected_rules

func adjust_script_weights(fitness: float, ai_hp: float, player_hp: float):
	# 1. Calculate HP difference momentum
	var hp_diff = (ai_hp - player_hp) / max(ai_hp + player_hp, 1.0)
	hp_difference_momentum = lerp(hp_difference_momentum, hp_diff, 0.2)
	
	# 2. Update success rates
	var success_rates = {}
	for rule in rules:
		var stats = rule_success_counts[rule.ruleID]
		success_rates[rule.ruleID] = stats.hits / float(max(stats.uses, 1))
	
	# 3. Adjust weights with multiple factors
	for rule in rules:
		var base_adjustment = 0.0
		var success_factor = success_rates[rule.ruleID]
		var hp_factor = _get_hp_based_modifier(rule, hp_diff)
		var momentum_factor = hp_difference_momentum * HP_MOMENTUM_WEIGHT
		
		# Composite adjustment
		var total_adjustment = (base_adjustment 
			+ success_factor * 0.1
			+ hp_factor
			+ momentum_factor)
			
		rule.weight = clamp(rule.weight + total_adjustment, 0.1, 1.0)
		_log_weight_change(rule, "COMPOSITE_ADJUST", rule.weight)

func _get_hp_based_modifier(rule: Dictionary, hp_diff: float) -> float:
	# Classify rule types (implement based on your rule actions)
	var is_defensive = "defense" in rule.enemy_action
	var is_aggressive = "attack" in rule.enemy_action
	
	# If AI is losing HP (negative diff), boost defensive rules
	if hp_diff < -0.2:  # Losing significantly
		return 0.1 if is_defensive else -0.05
	# If AI is winning, boost aggressive rules
	elif hp_diff > 0.2:  # Winning significantly
		return 0.1 if is_aggressive else -0.05
	return 0.0
		
func _log_weight_change(rule: Dictionary, reason: String, new_weight: float):
	var entry = {
		"timestamp": Time.get_datetime_string_from_system(),
		"ruleID": rule["ruleID"],
		"old_weight": rule.get("weight", 0.0),
		"new_weight": new_weight,
		"reason": reason
	}
	weight_history.append(entry)
	rule["history"].append(entry)
	
# Call this when a rule successfully hits the opponent
func record_rule_success(rule_id: int):
	if rule_success_counts.has(rule_id):
		var stats = rule_success_counts[rule_id]
		stats.uses += 1
		stats.hits += 1
		
		# Update weight based on success rate
		var success_rate = stats.hits / float(stats.uses)
		var weight_change = clamp(success_rate * 0.1, -0.05, 0.1)
		rules[rule_id].weight = clamp(rules[rule_id].weight + weight_change, 0.1, 1.0)
		
		_log_weight_change(rules[rule_id], "SUCCESS", rules[rule_id].weight)

func update_rule_priorities():
	var current_time = Time.get_ticks_msec()
	
	for rule in rules:
		var time_since_last_use = (current_time - _rule_usage_times[rule["ruleID"]]) / 1000.0
		var priority_boost = clamp(
			(1.0 - exp(-time_since_last_use / PRIORITY_DECAY_TIME)) * 0.3,
			0.0,
			0.3
		)
		
		rule["weight"] = clamp(
			rule["weight"] + priority_boost,
			0.1,
			1.0
		)

func get_DScript() -> Array:
	return _current_script.duplicate()

func get_rules() -> Array:
	return rules.duplicate()

func reset_weights():
	for rule in rules:
		rule["weight"] = clamp(
			INITIAL_WEIGHT + randf_range(-0.1, 0.1),
			0.1,
			1.0
		)
		
func get_rule_by_action(action) -> Dictionary:
	for rule in rules:
		var enemy_action = rule.get("enemy_action")
		
		# Handle array-based enemy_actions
		if enemy_action is Array:
			if action in enemy_action:
				return rule
		# Handle single string actions
		elif enemy_action == action:
			return rule
			
	return {}
