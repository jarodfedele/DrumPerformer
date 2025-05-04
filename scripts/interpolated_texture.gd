extends TextureRect

@onready var highway = get_parent().get_parent()

var points : Array

var repeat_factor = 3.0  # Repeat texture this many times over the quadrilateral height

#current variables in points table
var current_point_index
var current_start_time
var current_end_time
var current_yMin
var current_valMin
var current_yMax
var current_valMax
var current_is_gradient

var quad_yMin
var quad_yMax
var quad_ySize

func _physics_process(delta):
	current_point_index = 0 #TODO: initial binary search to get first correct index for the frame
	update_current_point_index_variables(0)
		
	var alpha_values = []
	
	for row_index in range(quad_ySize):
		var current_y_pixel = quad_yMax - row_index
		get_current_point_index(current_y_pixel)
		
		var val
		if current_point_index != null and current_y_pixel >= current_yMin and current_y_pixel < current_yMax:
			val = get_value(current_y_pixel, current_yMin, current_valMin, current_yMax, current_valMax, current_is_gradient)
		else:
			val = 0
		alpha_values.append(val)
		
	var alpha_tex = Global.generate_alpha_texture(alpha_values)
	material.set_shader_parameter("val_map", alpha_tex)
	material.set_shader_parameter("val_map_height", alpha_values.size())

func get_value(y_pixel, yPos_start, val_start, yPos_end, val_end, is_gradient):
	if not is_gradient:
		return val_start
	return Utils.convert_range(y_pixel, yPos_start, yPos_end, val_start, val_end)

func update_current_point_index_variables(new_point_index):
	current_point_index = new_point_index
	
	if current_point_index >= points.size():
		current_point_index = null
		return
		
	var point_data = points[current_point_index]
	
	current_start_time = point_data[0]
	current_end_time = point_data[2]
	current_yMax = highway.get_y_pos_from_time(current_start_time, false)
	current_valMax = point_data[1]
	current_yMin = highway.get_y_pos_from_time(current_end_time, false)
	current_valMin = point_data[3]
	current_is_gradient = point_data[4]
	
	return true

func get_current_point_index(current_y_pixel):
	if current_point_index == null:
		return
		
	var point_index = current_point_index
	var new_index = false
	while point_index < points.size():
		var point_yMin
		if point_index == current_point_index:
			point_yMin = current_yMin
		else:
			var point_data = points[point_index]
			point_yMin = highway.get_y_pos_from_time(point_data[2], false)
		
		if current_y_pixel >= point_yMin:
			break
			
		point_index = point_index + 1
		new_index = true
	
	if point_index != current_point_index:
		update_current_point_index_variables(point_index)
