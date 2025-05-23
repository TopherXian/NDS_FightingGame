extends Resource
class_name AIConfig

@export_category("Decision Tree")
@export_range(0, 1) var attack_chance_idle: float = 0.6
@export_range(0, 1) var defense_probability: float = 0.5
@export_range(0, 200) var defense_trigger_range: float = 75.0
@export_range(0, 2) var defense_cooldown_time: float = 0.25
@export_range(0, 200) var attack_opportunity_range: float = 90.0
@export_range(0, 1) var proactive_attack_chance: float = 0.8
@export_range(0, 1) var proactive_approach_chance: float = 0.5

@export_category("Dynamic Scripting")
@export var baseline_fitness: float = 0.5
@export var damage_weight: float = 0.7
@export_range(0.1, 2.0) var weight_scaling: float = 0.5
