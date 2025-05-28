extends Control

@onready var chart: Chart = $VBoxContainer/Chart

# This Chart will plot 3 different functions
var f1: Function
var total_rule_ids = 0

func _ready():
	
	get_rule_occurrences()
	# Let's create our @x values
	var x: Array = get_total_unique_rules()
	#var x = get_total_unique_rules()    # ["Rule 1", "Rule 2", ...] sorted ascending by ID
	#print("X: ", x)
#
	## NOTE: `x.size() == y.size()` or `x.size() == y[n].size()`
	var y = get_rule_occurrences() 
		 # [count_for_rule_1, count_for_rule_2, ...] aligned with x
	#print("Y: ", y)
	# Let's customize the chart properties, which specify how the chart
	# should look, plus some additional elements like labels, the scale, etc...
	var max_y = y.max()
	var cp: ChartProperties = ChartProperties.new()
	#print(cp.get_property_list())
	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.TRANSPARENT
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.WHITE_SMOKE
	cp.y_scale = 10
	cp.draw_origin = true
	cp.draw_bounding_box = false
	cp.draw_vertical_grid = false
	cp.interactive = true # false by default, it allows the chart to create a tooltip to show point values
	
	var padded_y = y.duplicate()
	var padded_x = x.duplicate()
	if padded_y.size() > 0 and padded_y.min() > 0:
		padded_y.append(0)
		padded_x.append("")
	# and interecept clicks on the plot
	
	# Let's add values to our functions
	f1 = Function.new(
		padded_x,
		padded_y, 
		"RuleID", # This will create a function with x and y values taken by the Arrays 
						# we have created previously. This function will also be named "Pressure"
						# as it contains 'pressure' values.
						# If set, the name of a function will be used both in the Legend
						# (if enabled thourgh ChartProperties) and on the Tooltip (if enabled).
		{
			type = Function.Type.BAR,
			bar_size = 10
		}
	)
	
	# Now let's plot our data
	chart.plot([f1], cp)
func checkFile():
	var file_path = "res://training.txt"
	var file = FileAccess.open(file_path, FileAccess.READ)
	return file


func get_total_unique_rules() -> Array:
	var unique_rule_ids := {}
	var file = checkFile()
	
	if file:
		var text = file.get_as_text()
		var json_data = JSON.parse_string(text)
		
		if typeof(json_data) == TYPE_DICTIONARY and json_data.has("scripts"):
			for script in json_data["scripts"]:
				if script.has("scripts_generated"):
					var rules = script["scripts_generated"].get("rules", [])
					for rule in rules:
						if rule.has("rule_id"):
							var id = int(rule["rule_id"])
							unique_rule_ids[id] = true
	else:
		print("Failed to open file.")
		return []
	
	# Sort rule IDs ascending
	var sorted_ids = unique_rule_ids.keys()
	sorted_ids.sort()
	
	# Format them as strings for labels
	var formatted_rules := []
	for id in sorted_ids:
		formatted_rules.append("Rule %d" % id)
	print(formatted_rules)
	return formatted_rules

# Returns: [count1, count2, ...] in the same order as above
func get_rule_occurrences() -> Array:
	var rule_counts := {}
	var file = checkFile()

	if file:
		var text = file.get_as_text()
		var json_data = JSON.parse_string(text)

		if typeof(json_data) == TYPE_DICTIONARY and json_data.has("scripts"):
			for script in json_data["scripts"]:
				if script.has("scripts_generated"):
					var rules = script["scripts_generated"].get("rules", [])
					for rule in rules:
						if rule.has("rule_id"):
							var id = int(rule["rule_id"])
							rule_counts[id] = rule_counts.get(id, 0) + 1
	else:
		print("Failed to open file.")
		return []

	var sorted_ids = rule_counts.keys()
	sorted_ids.sort()

	var result := []
	for id in sorted_ids:
		result.append(rule_counts[id])
	print(result)
	return result
