class_name Beatline extends Line2D

var time : float
var type : int
var highway

var color_r : float
var color_g : float
var color_b : float
var thickness : int

const BEATLINE_SCENE: PackedScene = preload("res://scenes/beatline.tscn")

static func create(time: float, type: int, highway):
	var instance: Beatline = BEATLINE_SCENE.instantiate()
	
	instance.time = time
	instance.type = type
	instance.highway = highway
	
	if instance.type == 0:
		instance.color_r = 80/255.0
	if instance.type == 1:
		instance.color_r = 120/255.0
	if instance.type == 2:
		instance.color_r = 160/255.0
		
	instance.color_g = instance.color_r
	instance.color_b = instance.color_r
	
	instance.thickness = (instance.type + 1 * 2)
	
	return instance
	
func update_position():
	var is_visible = (time >= highway.visible_time_min and time <= highway.visible_time_max)
	
	visible = is_visible
	set_process(is_visible)
	
	if is_visible:
		var lane_start_x1 = highway.get_lane_position(0)[0]
		var lane_start_x2 = highway.get_lane_position(0)[1]
		var lane_end_x1 = highway.get_lane_position(highway.num_lanes)[0]
		var lane_end_x2 = highway.get_lane_position(highway.num_lanes)[1]

		var yPos = highway.get_y_pos_from_time(time)

		var xMin = Utils.get_x_at_y(lane_start_x2, highway.y_min, lane_start_x1, highway.y_max, yPos)
		var xMax = Utils.get_x_at_y(lane_end_x2, highway.y_min, lane_end_x1, highway.y_max, yPos)

		points = [Vector2(xMin, yPos), Vector2(xMax, yPos)]
		width = thickness
		default_color = Color(color_r, color_g, color_b)
