extends Polygon2D

@onready var highway = get_parent()

func _ready():
	highway.reset_lane_positions() #have to do it as a child before parent
	highway.reset_chart_data() #have to do it as a child before parent
	
	var border_points = highway.get_border_points()

	polygon = border_points
