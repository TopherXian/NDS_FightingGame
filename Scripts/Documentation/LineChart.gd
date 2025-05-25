extends Control  # Assuming this node has a Chart node as child

@onready var chart = $Chart  # Update if needed

func _ready():
	# Clear existing data
	chart.clear_all_plotters()

	# Set up some fake (x, y) points
	var data_points = PackedVector2Array([
		Vector2(0, 1),
		Vector2(1, 3),
		Vector2(2, 2),
		Vector2(3, 5),
		Vector2(4, 4)
	])

	# Create the LinePlotter from static points
	var LinePlotter = preload("res://addons/easy_charts/control_charts/plotters/line_plotter.gd")
	var line_plotter = LinePlotter.from_points(data_points)

	# Customize the line appearance
	line_plotter.color = Color.BLUE
	line_plotter.thickness = 3.0

	# Add the plotter to the chart
	chart.add_plotter(line_plotter)
