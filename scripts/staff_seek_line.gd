extends Line2D

@onready var highway = $"../../Highway"
@onready var staff = get_parent()

const Utils = preload("res://scripts/utils.gd")

func _physics_process(delta):
	var seek_x = staff.get_current_notation_xPos()
	
	# Update the line's points
	clear_points()
	if seek_x:
		add_point(Vector2(seek_x, Global.NOTATION_YMIN))
		add_point(Vector2(seek_x, Global.NOTATION_YMAX))
