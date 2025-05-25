extends Node2D

var min_gap_ratio_both_voices: Array
var time_xPos_points: Array
var size_x: float
var has_time_sig: bool = false
var time_sig_notation

func set_notation_positions():
	for notation in get_children():
		var node_type = notation.node_type
		
		var category = notation.category
		var xMin = notation.xMin
		var xMax = notation.xMax
		var xSize = xMax - xMin
		var yMin = notation.yMin
		var yMax = notation.yMax
		var ySize = yMax - yMin
		
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
				child_node.position = Vector2(xMin, yMin)
			else:
				assert(false, "Expected notation category node not found! " + category)
		
func construct(test_index):
	time_xPos_points = []
	
	#get measure xMin and xMax
	var xMin
	var xMax
	for notation in get_children():
		#get xMin and xMax of entire measure
		if notation.xMin != null and !(notation.node_type == "Label"):
			if xMin == null:
				xMin = notation.xMin
			else:
				xMin = min(xMin, notation.xMin)
			if xMax == null:
				xMax = notation.xMax
			else:
				xMax = max(xMax, notation.xMax)
	
	#get measure size_x and normalize x positions
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
	
	
