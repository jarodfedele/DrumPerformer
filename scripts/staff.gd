class_name Staff extends Node2D

var is_playable: bool
var is_panorama: bool
var x_min: int
var y_min: int
var x_size: int
var y_size: int
var x_max: int
var y_max: int
var staffline_xOffset: float

var notation_measure_list: Array

var time_xPos_points: Array
var notation_lines: Array

var noteheads: Array

var stem_yPos_both_voices


@onready var song = get_parent()

@onready var background = $Background
@onready var staff_body = $StaffBody
@onready var seek_line = $SeekLine
@onready var notation_display = $NotationDisplay

var notation_line_list
var notation_time_list

var prev_line_number

const XPOS_INDEX = 0
const NOTE_LIST_INDEX = 2
const PAGE_INDEX = 3

const STAFF_SCENE: PackedScene = preload("res://scenes/staff.tscn")
const NOTATION_MEASURE_SCENE = preload("res://scenes/notation_measure.tscn")
const NOTATION_SCENE = preload("res://scenes/notation.tscn")

static func create(is_playable: bool, is_panorama,
	x_min: int, y_min: int, x_size: int, y_size: int):
		
	var instance: Staff = STAFF_SCENE.instantiate()
	
	instance.is_playable = is_playable
	instance.is_panorama = is_panorama
	
	instance.x_min = x_min
	instance.y_min = y_min
	instance.x_size = x_size
	instance.y_size = y_size
	instance.x_max = instance.x_min + instance.x_size
	instance.y_max = instance.y_min + instance.y_size
	
	if instance.is_panorama:
		instance.staffline_xOffset = 0
	else:
		instance.staffline_xOffset = 30

	return instance

func _ready():
	var center_staff_line_yPos = Global.center_staff_line_index*Global.STAFF_SPACE_HEIGHT + 0
	stem_yPos_both_voices = [center_staff_line_yPos-Global.STAFF_SPACE_HEIGHT*7, center_staff_line_yPos+Global.STAFF_SPACE_HEIGHT*5]

	draw_background()
	
	populate_notations()
	
	store_notation_lines()

func get_justify_x_offset(xPos, boundary_x_min, current_x_boundary_max, final_x_boundary_max):
	return Utils.convert_range(xPos, boundary_x_min, current_x_boundary_max, boundary_x_min, final_x_boundary_max) - xPos
	
func get_consecutive_measure_x_offsets(starting_measure_index) -> Array:
	var x_offsets = []
	var ended_last_measure = true
	
	var initial_x_offset = staffline_xOffset
	var x_offset = initial_x_offset
	var staffline_x_max = x_max-staffline_xOffset
	
	var measure_index = starting_measure_index
	
	var attempting_to_squeeze_additional_measure = false
	var smallest_min_gap = 10000
	
	var boundary_x_min
	var final_x_boundary_max = staffline_x_max
	var prev_x_boundary_max
	while measure_index < notation_measure_list.size():
		var notation_measure = notation_measure_list[measure_index]
		smallest_min_gap = min(smallest_min_gap, notation_measure.min_gap_ratio_both_voices[0], notation_measure.min_gap_ratio_both_voices[1])
		
		var x_padding
		if measure_index == starting_measure_index:
			x_padding = Global.STAFF_SPACE_HEIGHT * 6 + x_min #TODO: clef offset
		elif notation_measure.has_time_sig :
			x_padding = Global.STAFF_SPACE_HEIGHT * 1
		else:
			x_padding = Global.STAFF_SPACE_HEIGHT * 1.8
		x_offset += x_padding
		x_offsets.append(x_offset)
		if measure_index == starting_measure_index:
			boundary_x_min = x_offset
		x_offset += notation_measure.size_x
		var current_x_boundary_max = x_offset
			
		if x_offset > staffline_x_max:
			if !is_panorama:
				var line_x_size = current_x_boundary_max - boundary_x_min
				var desired_x_size = final_x_boundary_max - boundary_x_min
				var ratio = smallest_min_gap * (desired_x_size/float(line_x_size))
				if ratio < 0.8 and measure_index > starting_measure_index:
					x_offsets.pop_back()
					current_x_boundary_max = prev_x_boundary_max
				print(str(x_offsets.size()) + " " + str(ratio))
				
				#justify
				for i in range(x_offsets.size()):	
					var justified_measure_index = starting_measure_index + i
					var justified_notation_measure = notation_measure_list[justified_measure_index]
					for notation in justified_notation_measure.get_children():
						var xMin = notation.xMin + x_offsets[i]
						var xMax = notation.xMax + x_offsets[i]
						var justify_xMin_offset = get_justify_x_offset(xMin, boundary_x_min, current_x_boundary_max, final_x_boundary_max)
						var justify_xMax_offset = get_justify_x_offset(xMax, boundary_x_min, current_x_boundary_max, final_x_boundary_max)
						
						if notation.category == "multirest_rect":
							notation.xMin += justify_xMin_offset
							notation.xMax += justify_xMax_offset
						else:
							notation.xMin += justify_xMax_offset
							notation.xMax += justify_xMax_offset
						
						var notation_child_node = notation.get_child_node()
						if notation.category == "stem":
							for beam in notation_child_node.get_children():
								var beam_xMin = beam.position.x + x_offsets[i]
								var beam_xMax = beam_xMin + beam.size.x
								var justify_beam_xMin_offset = get_justify_x_offset(beam_xMin, boundary_x_min, current_x_boundary_max, final_x_boundary_max)
								var justify_beam_xMax_offset = get_justify_x_offset(beam_xMax, boundary_x_min, current_x_boundary_max, final_x_boundary_max)
								beam_xMin += justify_beam_xMin_offset - x_offsets[i]
								beam_xMax += justify_beam_xMax_offset - x_offsets[i]
								beam.position.x = beam_xMin
								beam.size.x = beam_xMax - beam_xMin
								
								if starting_measure_index == 0:
									print("JUSTIFY: " + str(beam_xMin) + " " + str(beam_xMax) + " " + str(boundary_x_min) + " " + str(current_x_boundary_max) + " " + str(final_x_boundary_max) + " " + str(justify_beam_xMin_offset) + " " + str(justify_beam_xMax_offset))
							
			ended_last_measure = false
			break
		
		prev_x_boundary_max = current_x_boundary_max
		measure_index += 1
	
	return [x_offsets, ended_last_measure]

func store_notation_lines():
	notation_lines = []
	
	var starting_measure_index = 0
	while true:
		var starting_measure_time = notation_measure_list[starting_measure_index].time_xPos_points[0][0]
		var consecutive_measure_x_offsets = get_consecutive_measure_x_offsets(starting_measure_index)
		var x_offsets = consecutive_measure_x_offsets[0]
		var ended_last_measure = consecutive_measure_x_offsets[1]
		var num_drawn_measures = x_offsets.size()
		notation_lines.append([starting_measure_time, starting_measure_index, x_offsets, ended_last_measure])

		if ended_last_measure:
			break
		
		starting_measure_index += num_drawn_measures
	
	for notation_measure in notation_measure_list:
		notation_measure.set_notation_positions()
		
func draw_staff_line_body(staffline_x_min, staffline_x_max, center_staff_line_yPos, clef_filename):
	#staff lines
	for i in range(5):
		var yPos = center_staff_line_yPos + (i-2)*Global.STAFF_SPACE_HEIGHT
		var line = Line2D.new()
		line.default_color = Color(0, 0, 0)
		line.width = 2
		line.add_point(Vector2(staffline_x_min, yPos))
		line.add_point(Vector2(staffline_x_max, yPos))

		staff_body.add_child(line)
	
	#clef
	var clef_xMin = Global.STAFF_SPACE_HEIGHT * 2 + staffline_x_min
	var clef_yMin = center_staff_line_yPos - Global.STAFF_SPACE_HEIGHT
	var clef_yMax = center_staff_line_yPos + Global.STAFF_SPACE_HEIGHT

	var file_path = Global.NOTATIONS_PATH + clef_filename + ".png"
	var clef_node = Sprite2D.new()
	clef_node.texture = load(file_path)
	var tex_size_x = float(clef_node.texture.get_width())
	var tex_size_y = float(clef_node.texture.get_height())
	var aspect_ratio = tex_size_x/tex_size_y
	
	var clef_ySize = clef_yMax - clef_yMin
	var scaling_factor = clef_ySize/tex_size_y
	var clef_xSize = tex_size_x*scaling_factor
	var clef_xMax = clef_xMin + clef_xSize
	
	clef_node.centered = false
	clef_node.position = Vector2(clef_xMin, clef_yMin)
	clef_node.scale = Vector2(clef_xSize / tex_size_x, clef_ySize / tex_size_y)

	staff_body.add_child(clef_node)
		
func display_measures_from_index(starting_notation_line_number, staffline_id):
	var notation_line_number = starting_notation_line_number + staffline_id
	if notation_line_number >= notation_lines.size():
		return
		
	var starting_measure_index = notation_lines[notation_line_number][1]
	var x_offsets = notation_lines[notation_line_number][2]
	var ended_last_measure = notation_lines[notation_line_number][3]
	
	var line_yMin = y_min + staffline_id*Global.NOTATION_YSIZE #TODO: NUMSTAFFLINES
	var center_staff_line_yPos = Global.center_staff_line_index*Global.STAFF_SPACE_HEIGHT + line_yMin
		
	var measure_index = starting_measure_index
	for x_offset in x_offsets:
		var notation_measure = notation_measure_list[measure_index]
		notation_display.add_child(notation_measure)
		notation_measure.position.x = x_offset
		notation_measure.position.y = line_yMin

		for point in notation_measure.time_xPos_points:
			var time = point[0]
			var xPos = point[1] + x_offset 
			time_xPos_points.append([time, xPos])
			
		measure_index += 1
	
	#staff lines
	var staffline_x_min = x_min + staffline_xOffset
	var staffline_x_max
	if ended_last_measure:
		var last_notation_measure = notation_measure_list[notation_measure_list.size()-1]
		staffline_x_max = last_notation_measure.position.x + last_notation_measure.size_x
	else:
		staffline_x_max = x_max
	staffline_x_max -= staffline_xOffset
	
	draw_staff_line_body(staffline_x_min, staffline_x_max, center_staff_line_yPos, "clef_percussion")
	
	var next_starting_measure_index
	if !ended_last_measure and !is_panorama:
		next_starting_measure_index = starting_measure_index + x_offsets.size()
	return next_starting_measure_index
		
func add_beam_type(current_notation, prev_notation, beam_int_type, voice_index):
	var current_stem_node = current_notation.get_child_node()
	var prev_stem_node = prev_notation.get_child_node()
	var beam_integers = current_notation.beam_integers
	var num_beams = beam_integers.count(beam_int_type)
	
	for beam_id in range(num_beams):
		var stem_yPos = stem_yPos_both_voices[voice_index-1]
		var yOffset = beam_id*(Global.BEAM_YSIZE+Global.BEAM_YSPACING)
		var beam_yMin
		if voice_index == 2:
			beam_yMin = stem_yPos - yOffset - Global.BEAM_YSIZE
		else:
			beam_yMin = stem_yPos + yOffset
		
		var beam_x_size
		var beam_xMin
		if beam_int_type == 0: #full
			beam_x_size = current_notation.xMin - prev_notation.xMin
			beam_xMin = prev_notation.xMin
		if beam_int_type == 1: #stub right
			beam_x_size = Global.BEAM_XSTUB
			beam_xMin = prev_notation.xMin
		if beam_int_type == 2: #stub left
			beam_x_size = Global.BEAM_XSTUB
			beam_xMin = current_notation.xMin - beam_x_size	
		var beam_node = ColorRect.new()
		beam_node.color = Color(0, 0, 0)
		beam_node.position = Vector2(beam_xMin, beam_yMin)
		beam_node.size = Vector2(beam_x_size, Global.BEAM_YSIZE)
		prev_stem_node.add_child(beam_node)
		
func add_beam_nodes(stem_notation_nodes_both_voices, voice_index):
	var stem_notation_nodes = stem_notation_nodes_both_voices[voice_index-1]
	for i in range(1, stem_notation_nodes.size()):
		var current_notation = stem_notation_nodes[i]
		var prev_notation = stem_notation_nodes[i-1]
		add_beam_type(current_notation, prev_notation, 0, voice_index)
		add_beam_type(current_notation, prev_notation, 1, voice_index)
		add_beam_type(current_notation, prev_notation, 2, voice_index)
		
func populate_notations():
	noteheads = []
	var stem_notation_nodes_both_voices = [[], []]
	
	notation_measure_list = []
	
	var current_notation
	var prev_category
	var prev_notation_measure
	
	for measure_data in song.notation_data:
		var notation_measure = NOTATION_MEASURE_SCENE.instantiate()
		notation_measure_list.append(notation_measure)
		
		var time_sig_notations = []
		
		for data in measure_data:
			var category = data[0]
			
			if category == "gaps":
				notation_measure.min_gap_ratio_both_voices = [data[1], data[2]]
			else:
				var time = data[1]
				if time == -1:
					time = null
				var file_name = data[2]
				var misc
				if data.size() > 7:
					misc = data[7]
				
				var xMin = data[3] * Global.STAFF_SPACE_HEIGHT
				var yMin = data[4] * Global.STAFF_SPACE_HEIGHT
				var xMax = data[5] * Global.STAFF_SPACE_HEIGHT
				var yMax = data[6] * Global.STAFF_SPACE_HEIGHT
				
				#if prev_category != "timesig":
				current_notation = NOTATION_SCENE.instantiate()
				current_notation.category = category
				current_notation.time = time
				current_notation.xMin = xMin
				current_notation.yMin = yMin
				current_notation.xMax = xMax
				current_notation.yMax = yMax
				
				var node
				
				if category == "sprite" or category == "notehead" or category == "measureline" or category == "timesig" or category == "wholerest" or category == "multirest_number":
					node = Sprite2D.new()
					current_notation.node_type = "Sprite2D"
					var file_path = Global.NOTATIONS_PATH + file_name + ".png"
					node.texture = load(file_path)
					
					var desired_width = xMax - xMin
					var desired_height = yMax - yMin

					var tex_width = node.texture.get_width()
					var tex_height = node.texture.get_height()
					
					node.centered = false
					node.scale = Vector2(desired_width / tex_width, desired_height / tex_height)
				
					if category == "notehead":
						current_notation.midi_id = misc
						node.z_index = 1
						noteheads.append(current_notation)
					if category == "timesig":
						time_sig_notations.append(current_notation)
						
				elif category == "line" or category == "stem" or category == "multirest_line":
					node = Line2D.new()
					current_notation.node_type = "Line2D"
					node.default_color = Color(0, 0, 0)
					node.width = 2
					if category == "stem":
						var digits = []
						for c in str(int(misc)).split(""):
							digits.append(int(c))
						current_notation.voice_index = digits[0]
						digits.remove_at(0)
						current_notation.beam_integers = digits
						stem_notation_nodes_both_voices[current_notation.voice_index-1].append(current_notation)
				elif category == "rect" or category == "multirest_rect":
					node = ColorRect.new()
					current_notation.node_type = "ColorRect"
				elif category == "measure_number":
					node = Label.new()
					current_notation.node_type = "Label"
					var number_text = str(file_name)
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
				
				current_notation.add_child(node)

				if (category == "measureline" and file_name != "measure_end") or category == "wholerest" or category.begins_with("multirest"):
					prev_notation_measure.add_child(current_notation)
				else:
					notation_measure.add_child(current_notation)
			
			prev_category = category
		
		if time_sig_notations.size() > 0:
			notation_measure.has_time_sig = true
			var time_sig_x_min
			var time_sig_y_min
			var time_sig_x_max
			var time_sig_y_max
			for time_sig_notation in time_sig_notations:
				if not time_sig_x_min:
					time_sig_x_min = time_sig_notation.xMin
					time_sig_y_min = time_sig_notation.yMin
					time_sig_x_max = time_sig_notation.xMax
					time_sig_y_max = time_sig_notation.yMax
				else:
					time_sig_x_min = min(time_sig_x_min, time_sig_notation.xMin)
					time_sig_y_min = min(time_sig_y_min, time_sig_notation.yMin)
					time_sig_x_max = max(time_sig_x_max, time_sig_notation.xMax)
					time_sig_y_max = max(time_sig_y_max, time_sig_notation.yMax)
					
			var notation = NOTATION_SCENE.instantiate()
			notation.category = "timesig"
			notation.xMin = time_sig_x_min
			notation.yMin = time_sig_y_min
			notation.xMax = time_sig_x_max
			notation.yMax = time_sig_y_max
				
			for time_sig_notation in time_sig_notations:
				var child_node = time_sig_notation.get_child_node()
				time_sig_notation.remove_child(child_node)
				notation.add_child(child_node)
				
				child_node.position.x = time_sig_notation.xMin - notation.xMin
				child_node.position.y = time_sig_notation.yMin - notation.yMin
				
				time_sig_notation.queue_free()
			
			notation_measure.add_child(notation)
										
		prev_notation_measure = notation_measure
	
	for i in range(notation_measure_list.size()):
		var notation_measure = notation_measure_list[i]
		notation_measure.construct(i)
	
	#after construct, add beams
	add_beam_nodes(stem_notation_nodes_both_voices, 1)
	add_beam_nodes(stem_notation_nodes_both_voices, 2)
	
func get_current_notation_xPos():
	if time_xPos_points == null:
		return
	var index = Utils.binary_search_closest_or_less(time_xPos_points, song.current_song_time, 0)
	if index < 0 or index >= time_xPos_points.size()-1:
		return
	var current_time_point = time_xPos_points[index]
	var next_time_point = time_xPos_points[index+1]
	return Utils.convert_range(song.current_song_time, current_time_point[0], next_time_point[0], current_time_point[1], next_time_point[1])

func get_current_line_number(force_valid):
	var line_number = Utils.binary_search_closest_or_less(notation_lines, song.current_song_time, 0)
	
	if force_valid:
		line_number = max(line_number, 0)
		line_number = min(line_number, notation_lines.size()-1)
		
	return line_number

func update_contents():
	#update page
	var current_line_number = get_current_line_number(true)
	if current_line_number != prev_line_number:
		for child in notation_display.get_children():
			notation_display.remove_child(child)
		for child in staff_body.get_children():
			child.queue_free()
		
		time_xPos_points = []
		for staffline_id in range(Global.NUM_NOTATION_ROWS):
			display_measures_from_index(current_line_number, staffline_id)
				
	prev_line_number = current_line_number
	
	# Update seek line
	seek_line.clear_points()
	var seek_x = get_current_notation_xPos()
	if seek_x:
		seek_line.add_point(Vector2(seek_x, y_min))
		seek_line.add_point(Vector2(seek_x, y_min + Global.NOTATION_YSIZE))
		
func draw_background():
	background.polygon = [
		Vector2(x_min, y_min),
		Vector2(x_max, y_min),
		Vector2(x_max, y_max),
		Vector2(x_min, y_max)
	]
	background.color = Global.STAFF_BACKGROUND_COLOR
