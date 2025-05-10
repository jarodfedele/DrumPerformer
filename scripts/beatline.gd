extends Line2D

@onready var highway = get_parent().get_parent()

var time : float
var color_r : int
var color_g : int
var color_b : int
var thickness : int

func update_position():
	var is_visible = (time >= highway.visible_time_min and time <= highway.visible_time_max)
	
	visible = is_visible
	set_process(is_visible)
	
	if is_visible:
		var lane_start_x1 = highway.get_lane_position(0)[0]
		var lane_start_x2 = highway.get_lane_position(0)[1]
		var lane_end_x1 = highway.get_lane_position(highway.num_lanes)[0]
		var lane_end_x2 = highway.get_lane_position(highway.num_lanes)[1]

		var yPos = highway.get_y_pos_from_time(time, false)

		var xMin = Utils.get_x_at_y(lane_start_x2, Global.HIGHWAY_YMIN, lane_start_x1, Global.HIGHWAY_YMAX, yPos)
		var xMax = Utils.get_x_at_y(lane_end_x2, Global.HIGHWAY_YMIN, lane_end_x1, Global.HIGHWAY_YMAX, yPos)
		
		points = [Vector2(xMin, yPos), Vector2(xMax, yPos)]
		width = thickness
		default_color = Color8(color_r, color_g, color_b)
