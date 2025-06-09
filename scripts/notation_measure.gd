extends Node2D

var min_gap_ratio_both_voices: Array
var time_xPos_points: Array
var size_x: float
var has_time_sig: bool = false
var time_sig_notation
var is_new_line
var measure_index: int
var measure_number_text: String
var beams_over_prev_measure_count_both_voices = [0, 0]
var hairpin_nodes

func get_measure_time():
	return time_xPos_points[0][0]
	
func get_first_stem_notation():
	for notation in get_children():
		if notation.category == "stem":
			return notation
			
func get_last_stem_notation():
	var reversed_children = get_children().duplicate()
	reversed_children.reverse()
	for notation in reversed_children:
		if notation.category == "stem":
			return notation
			
func get_leftmost_notation():
	var leftmost_notation
	for notation in get_children():
		if leftmost_notation == null or notation.xMin < leftmost_notation.xMin:
			leftmost_notation = notation
	return leftmost_notation
			
func get_measure_number_notation():
	for notation in get_children():
		var category = notation.category
		if category == "measure_number":
			return notation
			
func get_measure_line_notation():
	for notation in get_children():
		var category = notation.category
		if category == "measure_line":
			return notation
			
func set_notation_positions():
	for notation in get_children():
		var node_type = notation.node_type
		
		var category = notation.category
		var xMin = notation.xMin
		var xMax = notation.xMax
		var xSize = xMax - xMin
		var xCenter = (xMin+xMax)*0.5
		var yMin = notation.yMin
		var yMax = notation.yMax
		var ySize = yMax - yMin
		var yCenter = (yMin+yMax)*0.5
		
		for child_node in notation.get_children():
			if child_node is Sprite2D:
				child_node.position += Vector2(xMin, yMin)
			elif child_node is Line2D:
				#TODO: check which values are smaller and bigger
				child_node.add_point(Vector2(xMin, yMin))
				child_node.add_point(Vector2(xMax, yMax))
			elif child_node is ColorRect:
				child_node.color = Color(0, 0, 0)
				child_node.size = Vector2(xSize, ySize)
				child_node.position = Vector2(xMin, yMin)
			elif child_node is Label:
				if notation.category == "measure_line":
					var font = child_node.get_theme_font("font")
					var text_width = font.get_string_size(child_node.text).x
					child_node.position = Vector2(xCenter-text_width*0.5, yMin+Global.MEASURE_NUMBER_Y_OFFSET)
				else:
					child_node.position += Vector2(xMin, yMin)
			else:
				assert(false, "Expected notation category node not found! " + category)

func has_whole_rest():
	for notation in get_children():
		if notation.category == "wholerest":
			return true
	return false
		
func construct(test_index):
	time_xPos_points = []
	
	#get measure size_x and normalize x positions
	var xMin
	var xMax
	for notation in get_children():
		#get xMin and xMax of entire measure
		if notation.xMin != null and !(notation.node_type == "Label") and notation.category != "staff_text" and notation.category != "tempo":
			if xMin == null:
				xMin = notation.xMin
			else:
				xMin = min(xMin, notation.xMin)
			if xMax == null:
				xMax = notation.xMax
			else:
				xMax = max(xMax, notation.xMax)
	if xMin:
		size_x = xMax - xMin
		for notation in get_children():
			notation.xMin -= xMin
			notation.xMax -= xMin
	
	#store time in xPos for cursor
	for notation in get_children():
		var time = notation.time
		if time:
			time_xPos_points.append([time, (notation.xMin+notation.xMax)/2])
				
	#actually important: remove duplicate times
	var index = 0
	while index < time_xPos_points.size()-1:
		var current_time_point = time_xPos_points[index]
		var next_time_point = time_xPos_points[index+1]
		if current_time_point[0] == next_time_point[0]:
			if current_time_point[1] > next_time_point[1]:
				time_xPos_points.remove_at(index)
			else:
				time_xPos_points.remove_at(index+1)
		else:	
			index += 1
	
	
