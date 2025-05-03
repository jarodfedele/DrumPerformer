extends Node2D

@onready var highway = $"../../Highway"
@onready var staff = get_parent()

const NotationScene = preload("res://scenes/notation.tscn")
const NotationPageScene = preload("res://scenes/notation_page.tscn")
const Utils = preload("res://scripts/utils.gd")

const XPOS_INDEX = 0
const NOTE_LIST_INDEX = 2
const PAGE_INDEX = 3
	
func _ready():
	spawn_notations()

func generate_notation_page_and_time_lists(notation_list, measure_line_x_list):
	Global.notation_page_list = []
	var measure_offset = Global.MEASURE_START_SPACING - Global.NOTATION_DRAW_AREA_XOFFSET
	var current_xOffset = 0
	for i in range(measure_line_x_list.size()):
		var current_measure_line_xMin = measure_line_x_list[i][0]
		if current_measure_line_xMin >= Global.NOTATION_XMAX+current_xOffset-Global.NOTATION_DRAW_AREA_XOFFSET: #-100
			Global.notation_page_list.append([current_xOffset - measure_offset, null])
			var prev_measure_line_xMax = measure_line_x_list[i-1][1]
			current_xOffset = prev_measure_line_xMax + measure_offset
	
	Global.notation_time_list = []
	for notation in notation_list:
		var time = notation.time
		if time:
			var index = Utils.binary_search_closest_or_less(Global.notation_page_list, notation.xMin, 0)
			var page_time = Global.notation_page_list[index][1]
			if not page_time or time < page_time:
				Global.notation_page_list[index][1] = time
			Global.notation_time_list.append([time, (notation.xMin+notation.xMax)/2])
	
	for i in range(Global.notation_page_list.size()):
		Global.notation_page_list[i][0] -= Global.NOTATION_DRAW_AREA_XOFFSET
		
	for i in range(Global.notation_page_list.size()):
		if Global.notation_page_list[i][1] == null:
			var prev_time = Global.notation_page_list[i-1][1]
			var next_time
			var j = i + 1
			while j < Global.notation_page_list.size():
				next_time = Global.notation_page_list[j][1]
				if next_time != null:
					break
				j += 1
			var num_null_slots = j - i
			for k in range(num_null_slots):
				Global.notation_page_list[i+k][1] = prev_time + (k + 1) * (next_time - prev_time) / float(num_null_slots + 1)
		
	Global.notation_time_list.sort_custom(func(a, b):
		return a[0] < b[0]
	)
	var index = 0
	while index < Global.notation_time_list.size()-1:
		var current_time_point = Global.notation_time_list[index]
		var next_time_point = Global.notation_time_list[index+1]
		if current_time_point[0] == next_time_point[0]:
			if current_time_point[1] > next_time_point[1]:
				Global.notation_time_list.remove_at(index)
			else:
				Global.notation_time_list.remove_at(index+1)
		else:	
			index += 1

func insert_notation_in_page(notation, page_number):
	if page_number < 0 or page_number >= Global.notation_page_list.size():
		return
	
	var notation_page = Global.notation_page_list[page_number][PAGE_INDEX]
			
	var xOffset = Global.notation_page_list[page_number][XPOS_INDEX] - Global.NOTATION_XMIN
	notation.xMin = notation.xMin - xOffset
	notation.xMax = notation.xMax - xOffset
	
	notation.xMin -= Global.NOTATION_XMIN
	notation.yMin -= Global.NOTATION_YMIN
	notation.xMax -= Global.NOTATION_XMIN
	notation.yMax -= Global.NOTATION_YMIN
	
	var sprite = notation.get_node("NotationSprite")
	var line = notation.get_node("NotationLine")
	var color_rect = notation.get_node("NotationColorRect")
	var measure_number = notation.get_node("NotationMeasureNumber")
	
	var category = notation.category
	
	if category == "sprite":
		var file_path = Global.NOTATIONS_PATH + notation.file_name + ".png"
		sprite.texture = load(file_path)

		var desired_width = notation.xMax - notation.xMin
		var desired_height = notation.yMax - notation.yMin

		var tex_width = sprite.texture.get_width()
		var tex_height = sprite.texture.get_height()
		
		var sprite_xCenter = (notation.xMin + notation.xMax)/2
		var sprite_yCenter = (notation.yMin + notation.yMax)/2
		
		sprite.position = Vector2(sprite_xCenter, sprite_yCenter)
		sprite.scale = Vector2(desired_width / tex_width, desired_height / tex_height)
	elif category == "line":
		#TODO: check which values are smaller and bigger
		line.add_point(Vector2(notation.xMin, notation.yMin))
		line.add_point(Vector2(notation.xMax, notation.yMax))
	elif category == "rect":
		color_rect.color = Color(0, 0, 0)
		color_rect.position = Vector2(notation.xMin, notation.yMin)
		color_rect.size = Vector2(notation.xMax - notation.xMin, notation.yMax - notation.yMin)
	elif category == "measure_number":
		measure_number.visible = true
		measure_number.position = Vector2(notation.xMin, notation.yMin)
	else:
		assert(false, "Expected notation category node not found! " + category)
		
	notation_page.add_child(notation)
			
func add_notations_to_page_lists(notation_list, notation_list_copy):	
	for i in range(Global.notation_page_list.size()):
		Global.notation_page_list[i].append([])
		var notation_page = NotationPageScene.instantiate()
		Global.notation_page_list[i].append(notation_page)
		notation_page.visible = false
		add_child(notation_page)
		
	for i in range(notation_list.size()):
		var notation = notation_list[i]
		var notation_copy = notation_list_copy[i]
		
		var page_number = Utils.binary_search_closest_or_less(Global.notation_page_list, notation.xMin, XPOS_INDEX)
	 	
		insert_notation_in_page(notation, page_number)
		insert_notation_in_page(notation_copy, page_number-1)
			
func spawn_notations():
	for child in get_children():
		child.queue_free()

	var measure_line_x_list = []
	var notation_list = []
	var notation_list_copy = []
	
	for data in highway.notation_data:
		for i in range(2):
			var notation = NotationScene.instantiate()
			
			var category = data[0]
			notation.category = category
			notation.time = data[1]
			notation.xMin = data[3]
			notation.yMin = data[4]
			notation.xMax = data[5]
			notation.yMax = data[6]
			var misc = data[7]
			
			var sprite = notation.get_node("NotationSprite")
			var line = notation.get_node("NotationLine")
			var color_rect = notation.get_node("NotationColorRect")
			var measure_number = notation.get_node("NotationMeasureNumber")
			
			if category == "sprite":
				sprite.visible = true
				notation.file_name = data[2]
				if misc == "measureline":
					measure_line_x_list.append([notation.xMin, notation.xMax])
			elif category == "line":
				line.visible = true
			elif category == "rect":
				color_rect.visible = true
			elif category == "measure_number":
				measure_number.visible = true
				var number_text = str(data[2])
				measure_number.text = number_text
				measure_number.z_index = 1
			else:
				assert(false, "Expected notation category node not found! " + category)
			
			if i == 0:
				notation_list.append(notation)
			else:
				notation_list_copy.append(notation)
				
	generate_notation_page_and_time_lists(notation_list, measure_line_x_list)
	
	add_notations_to_page_lists(notation_list, notation_list_copy)
