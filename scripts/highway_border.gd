extends Line2D

@onready var highway = get_parent()

func _ready():
	var border_points = highway.get_border_points()
	
	add_point(border_points[3])
	add_point(border_points[0])
	add_point(border_points[1])
	add_point(border_points[2])
	#add_point(border_points[3])
