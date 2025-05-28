extends Control

@onready var chart: Chart = $VBoxContainer/Chart

# This Chart will plot 3 different functions
var f1: Function

var file_path = "res://fitness_record.txt"
var file = FileAccess.open(file_path, FileAccess.READ)

func _ready():
	var x = get_timestamp_indices()
	var y = get_fitness_values()
	#var x: PackedFloat32Array = PackedFloat32Array([0, 1, 2, 3, 4])
	#var y: Array = [0.500, 0.400, 0.560, 0.80, 1.0]
	print("Total points: ", x.size())
	
	var cp: ChartProperties = ChartProperties.new()
	print(cp.get_property_list())
	cp.max_samples = x.size() + 1
	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.TRANSPARENT
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.WHITE_SMOKE
	cp.draw_bounding_box = false
	cp.title = "Fitness Over Time"
	cp.x_label = "Timestamp Indice"
	cp.y_label = "Fitness Value"
	cp.x_scale = 1  # Adjust scale since values are small and spaced by 1
	cp.y_scale = 1  # Adjust scale accordingly
	cp.interactive = true
	cp.x_scale = 4     # Number of units between vertical grid lines
	cp.y_scale = 10   # Number of units between horizontal grid lines (based on your y-values)
	f1 = Function.new(
		x, y, "Fitness",
		{
			color = Color("#36a2eb"),
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	
	chart.plot([f1], cp)
	set_process(false)

func checkFile():
	var file_path = "res://fitness_record.txt"
	var file = FileAccess.open(file_path, FileAccess.READ)
	return file

	
func get_timestamp_indices() -> Array:
	var x_values := []
	var file = checkFile()

	if file:
		var index := 1
		while not file.eof_reached():
			var line = file.get_line()
			if line.begins_with("Timestamp:"):
				x_values.append(index)
				index += 1
	else:
		print("Failed to open file.")

	print("X:", x_values)
	return x_values
	
func get_fitness_values() -> Array:
	var y_values := []
	var file = checkFile()

	if file:
		while not file.eof_reached():
			var line = file.get_line()
			if line.begins_with("Fitness:"):
				var fitness = float(line.strip_edges().replace("Fitness: ", ""))
				y_values.append(fitness)
	else:
		print("Failed to open file.")

	print("Y:", y_values)
	return y_values
