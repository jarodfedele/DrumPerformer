class_name Staff extends Node2D

var is_playable: bool
var x_min: int
var y_min: int
var x_size: int
var y_size: int
var x_max: int
var y_max: int

var noteheads: Array

var center_staff_line_yPos

@onready var song = get_parent()

@onready var background = $Background
@onready var notation_pages = $NotationPages
@onready var cover = $Cover
@onready var clef = $Clef
@onready var staff_lines = $StaffLines
@onready var seek_line = $SeekLine

var notation_page_list
var notation_time_list

var prev_page_number

const XPOS_INDEX = 0
const NOTE_LIST_INDEX = 2
const PAGE_INDEX = 3

const STAFF_SCENE: PackedScene = preload("res://scenes/staff.tscn")
const NOTATION_SCENE = preload("res://scenes/notation.tscn")
const NOTATION_PAGE_SCENE = preload("res://scenes/notation_page.tscn")

static func create(is_playable: bool, type: int,
	x_min: int, y_min: int, x_size: int, y_size: int):
		
	var instance: Staff = STAFF_SCENE.instantiate()
	
	instance.is_playable = is_playable
	
	instance.x_min = x_min
	instance.y_min = y_min
	instance.x_size = x_size
	instance.y_size = y_size
	instance.x_max = instance.x_min + instance.x_size
	instance.y_max = instance.y_min + instance.y_size

	return instance

func _ready():
	center_staff_line_yPos = Global.center_staff_line_index*Global.STAFF_SPACE_HEIGHT + y_min
	
	draw_background()
	draw_cover()
	draw_clef()
	draw_staff_lines()
	
func generate_notation_page_and_time_lists(notation_nodes, notation_nodes_copy, measure_line_x_list):
	notation_page_list = []
	var measure_offset = Global.MEASURE_START_SPACING - Global.NOTATION_DRAW_AREA_XOFFSET
	var current_xOffset = 0
	for i in range(measure_line_x_list.size()):
		var current_measure_line_xMin = measure_line_x_list[i][0]
		if current_measure_line_xMin >= x_max+current_xOffset-Global.NOTATION_DRAW_AREA_XOFFSET: #-100
			notation_page_list.append([current_xOffset - measure_offset, null])
			var prev_measure_line_xMax = measure_line_x_list[i-1][1]
			current_xOffset = prev_measure_line_xMax + measure_offset
	
	notation_time_list = []
	for notation in notation_nodes:
		var time = notation.time
		if time:
			var index = Utils.binary_search_closest_or_less(notation_page_list, notation.xMin, 0)
			var page_time = notation_page_list[index][1]
			if not page_time or time < page_time:
				notation_page_list[index][1] = time
			notation_time_list.append([time, (notation.xMin+notation.xMax)/2])
	
	for i in range(notation_page_list.size()):
		notation_page_list[i][0] -= Global.NOTATION_DRAW_AREA_XOFFSET
		
	for i in range(notation_page_list.size()):
		if notation_page_list[i][1] == null:
			var prev_time = notation_page_list[i-1][1]
			var next_time
			var j = i + 1
			while j < notation_page_list.size():
				next_time = notation_page_list[j][1]
				if next_time != null:
					break
				j += 1
			var num_null_slots = j - i
			for k in range(num_null_slots):
				notation_page_list[i+k][1] = prev_time + (k + 1) * (next_time - prev_time) / float(num_null_slots + 1)
		
	notation_time_list.sort_custom(func(a, b):
		return a[0] < b[0]
	)
	var index = 0
	while index < notation_time_list.size()-1:
		var current_time_point = notation_time_list[index]
		var next_time_point = notation_time_list[index+1]
		if current_time_point[0] == next_time_point[0]:
			if current_time_point[1] > next_time_point[1]:
				notation_time_list.remove_at(index)
			else:
				notation_time_list.remove_at(index+1)
		else:	
			index += 1
	
	for i in range(notation_page_list.size()):
		notation_page_list[i].append([])
		var notation_page = NOTATION_PAGE_SCENE.instantiate()
		notation_page_list[i].append(notation_page)
		notation_page.visible = false
		notation_pages.add_child(notation_page)
		
	for i in range(notation_nodes.size()):
		var notation = notation_nodes[i]
		var notation_copy = notation_nodes_copy[i]
		
		var page_number = Utils.binary_search_closest_or_less(notation_page_list, notation.xMin, XPOS_INDEX)
	 	
		insert_notation_in_page(notation, page_number)
		insert_notation_in_page(notation_copy, page_number-1)

func insert_notation_in_page(notation, page_number):
	if page_number < 0 or page_number >= notation_page_list.size():
		return
	
	var notation_page = notation_page_list[page_number][PAGE_INDEX]
			
	var xOffset = notation_page_list[page_number][XPOS_INDEX] - x_min
	notation.xMin = notation.xMin - xOffset
	notation.xMax = notation.xMax - xOffset
	
	notation.xMin -= x_min
	#notation.yMin -= y_min
	notation.xMax -= x_min
	#notation.yMax -= y_min
	
	var node = notation.get_children()[0]
	var category = notation.category
	if category == "sprite" or category == "notehead":
		var file_path = Global.NOTATIONS_PATH + notation.file_name + ".png"
		node.texture = load(file_path)

		var desired_width = notation.xMax - notation.xMin
		var desired_height = notation.yMax - notation.yMin

		var tex_width = node.texture.get_width()
		var tex_height = node.texture.get_height()
		
		var sprite_xCenter = (notation.xMin + notation.xMax)/2
		var sprite_yCenter = (notation.yMin + notation.yMax)/2
		
		node.position = Vector2(sprite_xCenter, sprite_yCenter)
		node.scale = Vector2(desired_width / tex_width, desired_height / tex_height)
	elif category == "line":
		#TODO: check which values are smaller and bigger
		node.add_point(Vector2(notation.xMin, notation.yMin))
		node.add_point(Vector2(notation.xMax, notation.yMax))
	elif category == "rect":
		node.color = Color(0, 0, 0)
		node.position = Vector2(notation.xMin, notation.yMin)
		node.size = Vector2(notation.xMax - notation.xMin, notation.yMax - notation.yMin)
	elif category == "measure_number":
		node.visible = true
		node.position = Vector2(notation.xMin, notation.yMin)
	else:
		assert(false, "Expected notation category node not found! " + category)
		
	notation_page.add_child(notation)
			
func populate_notations():
	for child in notation_pages.get_children():
		child.queue_free()
	
	noteheads = []
	
	var measure_line_x_list = []
	var notation_nodes = []
	var notation_nodes_copy = []
	
	for data in song.notation_data:
		for i in range(2):
			var notation = NOTATION_SCENE.instantiate()
			
			var category = data[0]
			notation.category = category
			notation.time = data[1]
			notation.xMin = data[3] + x_min
			notation.yMin = data[4] + y_min
			notation.xMax = data[5] + x_min
			notation.yMax = data[6] + y_min
			var misc = data[7]
			
			var node
			
			if category == "sprite" or category == "notehead":
				node = Sprite2D.new()
				notation.file_name = data[2]
				if category == "sprite" and misc == "measureline":
					measure_line_x_list.append([notation.xMin, notation.xMax])
				if category == "notehead":
					notation.midi_id = misc
					node.z_index = 1
					#TODO: all these assignments are running twice!
					#if i == 0:
					noteheads.append(notation)
			elif category == "line":
				node = Line2D.new()
				node.default_color = Color(0, 0, 0)
				node.width = 2
			elif category == "rect":
				node = ColorRect.new()
			elif category == "measure_number":
				node = Label.new()
				var number_text = str(data[2])
				node.text = number_text
				node.z_index = 1
				
				var label_settings = LabelSettings.new()
				var font = SystemFont.new()
				font.font_names = ["Verdana"]
				label_settings.font = font
				label_settings.font_size = 14
				label_settings.font_color = Color(0, 0, 0)
				node.set_label_settings(label_settings)
			else:
				assert(false, "Expected notation category node not found! " + category)
			
			notation.add_child(node)
			
			if i == 0:
				notation_nodes.append(notation)
			else:
				notation_nodes_copy.append(notation)
				
	generate_notation_page_and_time_lists(notation_nodes, notation_nodes_copy, measure_line_x_list)

func get_current_notation_xOffset():
	var page_number = get_current_page_number(true)
	return float(notation_page_list[page_number][0] - x_min)
			
func get_current_notation_xPos():
	var index = Utils.binary_search_closest_or_less(notation_time_list, song.current_song_time, 0)
	if index >= notation_time_list.size()-1:
		return
	var current_time_point = notation_time_list[index]
	var next_time_point = notation_time_list[index+1]
	return Utils.convert_range(song.current_song_time, current_time_point[0], next_time_point[0], current_time_point[1], next_time_point[1]) - get_current_notation_xOffset()

func get_notation_page(page_number):
	if page_number == null or page_number < 0 or page_number >= notation_page_list.size():
		return
	return notation_page_list[page_number][PAGE_INDEX]
	
func get_current_page_number(force_valid):
	var page_number = Utils.binary_search_closest_or_less(notation_page_list, song.current_song_time, 1)
	
	if force_valid:
		page_number = max(page_number, 0)
		page_number = min(page_number, notation_page_list.size())
		
	return page_number

func update_contents():
	var current_page_number = get_current_page_number(true)
	if current_page_number != prev_page_number:
		var current_notation_page = get_notation_page(current_page_number)
		var prev_notation_page = get_notation_page(prev_page_number)
		if current_notation_page:
			current_notation_page.visible = true
		if prev_notation_page:
			prev_notation_page.visible = false
	prev_page_number = current_page_number
	
	# Update seek line
	seek_line.clear_points()
	var seek_x = get_current_notation_xPos()
	if seek_x:
		seek_line.add_point(Vector2(seek_x, y_min))
		seek_line.add_point(Vector2(seek_x, y_max))

func take_screenshots():
	if notation_page_list.size() == 0:
		return

	var children = notation_pages.get_children()
	print(children.size())
	for i in range(children.size()):
		var notation_page = children[i]
		notation_page.visible = true
		notation_page.take_screenshot(i)
		await get_tree().process_frame
		notation_page.visible = false

	#clear junk from each notation page
	for notation_page in notation_pages.get_children():
		for child in notation_page.get_children():
			child.queue_free()	
	await get_tree().process_frame

	#add .png texture to each notatio page
	children = notation_pages.get_children()
	for i in range(children.size()):
		var notation_page = children[i]
		var tex_rect = TextureRect.new()
		
		var image = Image.new()
		if image.load("user://test_notation_page_" + str(i) + ".png") == OK:
			var tex = ImageTexture.create_from_image(image)
			tex_rect.texture = tex
		
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		
		tex_rect.position = Vector2(x_min, y_min)
		tex_rect.size = Vector2(Global.NOTATION_XSIZE*2, Global.NOTATION_YSIZE) #TODO
		
		tex_rect.visible = true
		notation_page.add_child(tex_rect)
	
	await get_tree().process_frame

	get_notation_page(0).visible = true

	print("CHILDREN: " + str(notation_pages.get_children().size()))

func draw_background():
	background.polygon = [
		Vector2(x_min, y_min),
		Vector2(x_max, y_min),
		Vector2(x_max, y_max),
		Vector2(x_min, y_max)
	]
	background.color = Global.STAFF_BACKGROUND_COLOR

func draw_cover():
	var cover_x_max = Global.NOTATION_DRAW_AREA_XOFFSET+Global.NOTATION_BOUNDARYXMINOFFSET+12
	cover.polygon = [
		Vector2(x_min, y_min),
		Vector2(cover_x_max, y_min),
		Vector2(cover_x_max, y_max),
		Vector2(x_min, y_max)
	]
	cover.color = Global.STAFF_BACKGROUND_COLOR

func draw_clef():
	var xMin = Global.STAFF_SPACE_HEIGHT * 2 + x_min
	var yMin = center_staff_line_yPos - Global.STAFF_SPACE_HEIGHT
	var xMax = xMin + 150 #TODO
	var yMax = center_staff_line_yPos + Global.STAFF_SPACE_HEIGHT
	
	var xCenter = (xMin + xMax) * 0.5
	var yCenter = (yMin + yMax) * 0.5
	
	var scale_factor = 0.07 #TODO: set programatically
	clef.scale = scale*scale_factor
	clef.position = Vector2(xMin + 10, yCenter)

func draw_staff_lines():
	for child in staff_lines.get_children():
		child.queue_free()
	
	for i in range(5):
		var yPos = center_staff_line_yPos + (i-2)*Global.STAFF_SPACE_HEIGHT
		var line = Line2D.new()
		line.default_color = Color(0, 0, 0)
		line.width = 2
		line.add_point(Vector2(x_min, yPos))
		line.add_point(Vector2(x_max, yPos))

		staff_lines.add_child(line)
