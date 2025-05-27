class_name Staff extends Node2D

var is_playable: bool
var is_panorama: bool
var x_min: int
var y_min: int
var x_size: int
var y_size: int
var x_max: int
var y_max: int
var staffline_x_min
var staffline_x_max
var default_center_staff_line_yPos
var clef_xMin
var clef_yMin
var clef_xMax
var clef_yMax
var clef_scale

var notation_measure_list: Array

var time_xPos_points: Array
var notation_lines: Array

var noteheads: Array

var stem_yPos_both_voices

@onready var song = get_parent()

@onready var background = $Background
@onready var contents_sub_viewport = $ContentsSubViewport
@onready var notation_display = %NotationDisplay
@onready var seek_line = $SeekLine
@onready var contents_display = $ContentsDisplay

var notation_line_list
var notation_time_list

var prev_line_number

const XPOS_INDEX = 0
const NOTE_LIST_INDEX = 2
const PAGE_INDEX = 3

const STAFF_SCENE: PackedScene = preload("res://scenes/staff.tscn")
const NOTATION_MEASURE_SCENE = preload("res://scenes/notation_measure.tscn")
const NOTATION_SCENE = preload("res://scenes/notation.tscn")

const EDGE_FADE_1 = 0.246
const EDGE_FADE_2 = 0.021

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
		instance.staffline_x_min = instance.x_min + 60
		instance.staffline_x_max = instance.x_max
	else:
		instance.staffline_x_min = instance.x_min + 60
		instance.staffline_x_max = instance.x_max - 30
	
	instance.default_center_staff_line_yPos = Global.center_staff_line_index * Global.STAFF_SPACE_HEIGHT
	
	instance.clef_xMin = Global.STAFF_SPACE_HEIGHT * 2 + instance.staffline_x_min
	instance.clef_yMin = instance.default_center_staff_line_yPos - Global.STAFF_SPACE_HEIGHT
	instance.clef_yMax = instance.default_center_staff_line_yPos + Global.STAFF_SPACE_HEIGHT
	var texture = load(Global.CLEF_PATH) as Texture2D
	var tex_size_x = float(texture.get_width())
	var tex_size_y = float(texture.get_height())
	var aspect_ratio = tex_size_x/tex_size_y
	var clef_ySize = instance.clef_yMax - instance.clef_yMin
	var scaling_factor = clef_ySize/tex_size_y
	var clef_xSize = tex_size_x*scaling_factor
	instance.clef_xMax = instance.clef_xMin + clef_xSize
	instance.clef_scale = Vector2(clef_xSize / tex_size_x, clef_ySize / tex_size_y)
	
	return instance

func _ready():
	stem_yPos_both_voices = [default_center_staff_line_yPos-Global.STAFF_SPACE_HEIGHT*7, default_center_staff_line_yPos+Global.STAFF_SPACE_HEIGHT*5]

	draw_background()
	
	populate_notations()
	
	store_notation_lines()
	
	contents_display.texture = contents_sub_viewport.get_texture()
	contents_display.material.set_shader_parameter("edge_fade_1", EDGE_FADE_1)
	contents_display.material.set_shader_parameter("edge_fade_2", EDGE_FADE_2)
	contents_display.material.set_shader_parameter("bounds_min", Vector2(x_min, y_min))
	contents_display.material.set_shader_parameter("bounds_max", Vector2(x_min+x_size, y_min+y_size))
	contents_display.material.set_shader_parameter("custom_bounds", true)
	
func create_measure_number_node(measure_number_text):
	var node = Label.new()
	node.text = measure_number_text

	var label_settings = LabelSettings.new()
	var font = SystemFont.new()
	font.font_names = ["Verdana"]
	label_settings.font = font
	label_settings.font_size = 14
	label_settings.font_color = Color(0, 0, 0)
	node.set_label_settings(label_settings)
	
	return node
	
func get_justify_x_offset(xPos, boundary_x_min, current_x_boundary_max, final_x_boundary_max):
	return Utils.convert_range(xPos, boundary_x_min, current_x_boundary_max, boundary_x_min, final_x_boundary_max) - xPos
	
func get_consecutive_measure_x_offsets(starting_measure_index) -> Array:
	var x_offsets = []
	var ended_last_measure = true
	
	var initial_x_offset = staffline_x_min - x_min
	var x_offset = initial_x_offset
	
	var measure_index = starting_measure_index
	
	var attempting_to_squeeze_additional_measure = false
	var smallest_min_gap = 10000
	
	var boundary_x_min
	var final_x_boundary_max = staffline_x_max
	var prev_x_boundary_max
	while measure_index < notation_measure_list.size():
		var notation_measure = notation_measure_list[measure_index]
		notation_measure.is_new_line = (measure_index == 0 or (measure_index == starting_measure_index and !is_panorama))
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
				if ratio < 0.85 and measure_index > starting_measure_index:
					x_offsets.pop_back()
					current_x_boundary_max = prev_x_boundary_max
				
				#add time signature at end of line if changing
				var last_measure_index = starting_measure_index+x_offsets.size()-1
				var last_measure = notation_measure_list[last_measure_index]
				if last_measure_index < notation_measure_list.size()-1:
					var next_measure = notation_measure_list[last_measure_index+1]
					if next_measure.has_time_sig:
						var time_sig_size_x = next_measure.time_sig_notation.xMax - next_measure.time_sig_notation.xMin
						var time_sig_notation_copy = next_measure.time_sig_notation.duplicate()
						last_measure.add_child(time_sig_notation_copy)
						time_sig_notation_copy.xMin = last_measure.size_x + Global.TIME_SIG_X_PADDING
						time_sig_notation_copy.xMax = time_sig_notation_copy.xMin + time_sig_size_x
						current_x_boundary_max += Global.TIME_SIG_X_PADDING + time_sig_size_x
						var time_sig_size_y = time_sig_notation_copy.yMax - time_sig_notation_copy.yMin
						time_sig_notation_copy.yMin = default_center_staff_line_yPos - Global.STAFF_SPACE_HEIGHT*2
						time_sig_notation_copy.yMax = time_sig_notation_copy.yMin + time_sig_size_y
				
				#justify
				for i in range(x_offsets.size()):	
					var justified_measure_index = starting_measure_index + i
					var justified_notation_measure = notation_measure_list[justified_measure_index]
					
					for point in justified_notation_measure.time_xPos_points:
						var xPos = point[1] + x_offsets[i]
						var justify_xPos_offset = get_justify_x_offset(xPos, boundary_x_min, current_x_boundary_max, final_x_boundary_max)
						point[1] += justify_xPos_offset
						
					for notation in justified_notation_measure.get_children():
						var xMin = notation.xMin + x_offsets[i]
						var xMax = notation.xMax + x_offsets[i]
						var justify_xMin_offset = get_justify_x_offset(xMin, boundary_x_min, current_x_boundary_max, final_x_boundary_max)
						var justify_xMax_offset = get_justify_x_offset(xMax, boundary_x_min, current_x_boundary_max, final_x_boundary_max)
						
						if notation.category == "multirest_rect" or notation.category == "tuplet_line":
							notation.xMin += justify_xMin_offset
							notation.xMax += justify_xMax_offset
						elif notation.category == "notehead" and notation.voice_index == 2:
							notation.xMin += justify_xMin_offset
							notation.xMax += justify_xMin_offset
						else:
							notation.xMin += justify_xMax_offset
							notation.xMax += justify_xMax_offset
						
						var voice_2_extra_x_offset = Global.STAFF_SPACE_HEIGHT*2 * (final_x_boundary_max/float(current_x_boundary_max)-1)
						if notation.voice_index == 2:
							notation.xMin += voice_2_extra_x_offset
							notation.xMax += voice_2_extra_x_offset
							
						var notation_child_node = notation.get_child_node()
						if notation.category == "stem":
							for beam in notation_child_node.get_children():
								var beam_xMin = beam.position.x + x_offsets[i]
								var beam_xMax = beam_xMin + beam.size.x
								var justify_beam_xMin_offset = get_justify_x_offset(beam_xMin, boundary_x_min, current_x_boundary_max, final_x_boundary_max)
								var justify_beam_xMax_offset = get_justify_x_offset(beam_xMax, boundary_x_min, current_x_boundary_max, final_x_boundary_max)
								beam_xMin += justify_beam_xMin_offset - x_offsets[i]
								beam_xMax += justify_beam_xMax_offset - x_offsets[i]
								if notation.voice_index == 2:
									beam_xMin += voice_2_extra_x_offset
									beam_xMax += voice_2_extra_x_offset
								beam.position.x = beam_xMin
								beam.size.x = beam_xMax - beam_xMin

			ended_last_measure = false
			break
		
		prev_x_boundary_max = current_x_boundary_max
		measure_index += 1
	
	return [x_offsets, ended_last_measure]

func get_index_in_line(notation_measure):
	var notation_measure_index = notation_measure.measure_index
	var line_number = Utils.binary_search_closest_or_less(notation_lines, notation_measure_index, 1)
	return notation_lines[line_number][1] - notation_measure_index
	
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
		if is_panorama:
			starting_measure_index -= 1

	for measure_index in range(notation_measure_list.size()):
		var notation_measure = notation_measure_list[measure_index]
		
		var measure_number_notation = notation_measure.get_measure_number_notation()
		if measure_number_notation != null:
			var measure_number_child_node = measure_number_notation.get_child_node()
			measure_number_notation.remove_child(measure_number_child_node)
			measure_number_notation.queue_free()

			if notation_measure.is_new_line:
				var leftmost_notation = notation_measure.get_leftmost_notation()
				leftmost_notation.add_child(measure_number_child_node)
			else:
				var prev_notation_measure = notation_measure_list[notation_measure.measure_index-1]
				var prev_measure_line_notation = prev_notation_measure.get_measure_line_notation()
				prev_measure_line_notation.add_child(measure_number_child_node)

	for measure_index in range(notation_measure_list.size()):
		var notation_measure = notation_measure_list[measure_index]
		notation_measure.set_notation_positions()

func draw_staff_line_body(line_x_min, line_x_max, center_staff_line_yPos):
	#staff lines
	for i in range(5):
		var yPos = center_staff_line_yPos + (i-2)*Global.STAFF_SPACE_HEIGHT
		var line = Line2D.new()
		line.default_color = Color(0, 0, 0)
		line.width = 2
		line.add_point(Vector2(line_x_min, yPos))
		line.add_point(Vector2(line_x_max, yPos))

		notation_display.add_child(line)

func get_line_yMin(staffline_id):
	return y_min + staffline_id*Global.NOTATION_YSIZE
	
func get_center_staff_line_yPos(staffline_id):
	return default_center_staff_line_yPos + get_line_yMin(staffline_id)

func display_measures_from_index(starting_notation_line_number, staffline_id):
	var notation_line_number = starting_notation_line_number + staffline_id
	if notation_line_number < 0 or notation_line_number >= notation_lines.size():
		return
	
	var line_yMin = get_line_yMin(staffline_id)
	var center_staff_line_yPos = get_center_staff_line_yPos(staffline_id)
	
	var starting_measure_index = notation_lines[notation_line_number][1]
	var x_offsets = notation_lines[notation_line_number][2]
	var ended_last_measure = notation_lines[notation_line_number][3]
	
	#clef
	if !is_panorama or staffline_id == 0:
		var clef_node = Sprite2D.new()
		clef_node.texture = load(Global.CLEF_PATH)
		clef_node.centered = false
		clef_node.position = Vector2(clef_xMin, center_staff_line_yPos-Global.STAFF_SPACE_HEIGHT)
		clef_node.scale = clef_scale
		notation_display.add_child(clef_node)
	
	var measure_number_node = create_measure_number_node(notation_measure_list[starting_measure_index].measure_number_text)
	notation_display.add_child(measure_number_node)
	var font = measure_number_node.get_theme_font("font")
	var text_width = font.get_string_size(measure_number_node.text).x
	measure_number_node.position = Vector2((clef_xMin+clef_xMax)*0.5 - text_width*0.5, center_staff_line_yPos-(Global.STAFF_SPACE_HEIGHT*2)+Global.MEASURE_NUMBER_Y_OFFSET)
	
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
		
		#draw beams over measures
		if measure_index > 0:
			for voice_index in range(2):
				for beam_id in range(notation_measure.beams_over_prev_measure_count_both_voices[voice_index]):
					var prev_notation_measure = notation_measure_list[measure_index-1]
					
					var prev_stem_notation = prev_notation_measure.get_last_stem_notation()
					var current_stem_notation = notation_measure.get_first_stem_notation()
					var prev_stem_node = prev_stem_notation.get_child_node()
					var current_stem_node = current_stem_notation.get_child_node()
					
					if measure_index == starting_measure_index:
						var beam1_xMin = prev_stem_notation.xMin+prev_notation_measure.position.x
						var beam1_xMax = prev_notation_measure.get_measure_line_notation().xMax+prev_notation_measure.position.x
						var beam1_x_size = beam1_xMax - beam1_xMin
						var stem1_yPos = prev_stem_notation.yMin+prev_notation_measure.position.y
						add_beam_node(notation_display, beam1_xMin, beam1_x_size, stem1_yPos, beam_id, voice_index, true)
						
						var beam2_x_size = Global.START_OF_MEASURE_DRAW_DISTANCE
						var beam2_xMin = current_stem_notation.xMin+notation_measure.position.x - beam2_x_size
						var stem2_yPos = current_stem_notation.yMin+notation_measure.position.y
						add_beam_node(notation_display, beam2_xMin, beam2_x_size, stem2_yPos, beam_id, voice_index, true)
					
					else:
						var beam_xMin = prev_stem_notation.xMin+prev_notation_measure.position.x
						var beam_xMax = current_stem_notation.xMin+notation_measure.position.x
						var beam_x_size = beam_xMax - beam_xMin
						var stem_yPos = prev_stem_notation.yMin+notation_measure.position.y
						add_beam_node(notation_display, beam_xMin, beam_x_size, stem_yPos, beam_id, voice_index, true)
						
		measure_index += 1
	
	#staff lines
	var line_x_max
	if ended_last_measure:
		var last_notation_measure = notation_measure_list[notation_measure_list.size()-1]
		line_x_max = last_notation_measure.position.x + last_notation_measure.size_x
	else:
		line_x_max = staffline_x_max
	draw_staff_line_body(staffline_x_min, line_x_max, center_staff_line_yPos)
	
	var next_starting_measure_index
	if !ended_last_measure and !is_panorama:
		next_starting_measure_index = starting_measure_index + x_offsets.size()
	return next_starting_measure_index

func add_beam_node(stem_node, beam_xMin, beam_x_size, stem_yPos, beam_id, voice_index, over_measure):
	var yOffset = beam_id*(Global.BEAM_YSIZE+Global.BEAM_YSPACING)
	var beam_yMin
	if voice_index == 2:
		beam_yMin = stem_yPos - yOffset - Global.BEAM_YSIZE
	else:
		beam_yMin = stem_yPos + yOffset
		
	var beam_node = ColorRect.new()
	beam_node.color = Color(0, 0, 0)
	beam_node.position = Vector2(beam_xMin, beam_yMin)
	beam_node.size = Vector2(beam_x_size, Global.BEAM_YSIZE)
	stem_node.add_child(beam_node)
		
func add_beam_type(current_notation, prev_notation, beam_int_type, voice_index):
	var current_stem_node = current_notation.get_child_node()
	var prev_stem_node = prev_notation.get_child_node()
	var beam_integers = current_notation.beam_integers
	var num_beams = beam_integers.count(beam_int_type)

	for beam_id in range(num_beams):	
		var beam_x_size
		var beam_xMin
		
		var beam_over_measure = false
		if beam_int_type == 0: #full
			beam_x_size = current_notation.xMin - prev_notation.xMin
			beam_xMin = prev_notation.xMin
			if beam_x_size < 0:
				beam_over_measure = true
				var notation_measure = current_notation.get_parent()
				notation_measure.beams_over_prev_measure_count_both_voices[voice_index-1] += 1
		if beam_int_type == 1: #stub right
			beam_x_size = Global.BEAM_XSTUB
			beam_xMin = prev_notation.xMin
		if beam_int_type == 2: #stub left
			beam_x_size = Global.BEAM_XSTUB
			beam_xMin = current_notation.xMin - beam_x_size
			
		if !beam_over_measure:
			add_beam_node(prev_stem_node, beam_xMin, beam_x_size, stem_yPos_both_voices[voice_index-1], beam_id, voice_index, false)
		
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
		notation_measure.measure_index = notation_measure_list.size()
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
				
				if category == "sprite" or category == "notehead" or category == "measure_line" or category == "timesig" or category == "wholerest" or category == "multirest_number":
					node = Sprite2D.new()
					current_notation.node_type = "Sprite2D"
					var file_path = Global.NOTATIONS_PATH + file_name + ".png"
					node.texture = load(file_path)
					
					node.centered = false
					Utils.set_sprite_position_and_scale(node, 0, 0, xMax-xMin, yMax-yMin)
					
					if category == "notehead":
						var note_str = str(misc)
						current_notation.voice_index = int(note_str.substr(0, 1))
						current_notation.midi_id = int(note_str.substr(1))
						node.z_index = 1
						noteheads.append(current_notation)
					if category == "timesig":
						time_sig_notations.append(current_notation)
						
				elif category == "line" or category == "stem" or category == "multirest_line" or category == "tuplet_line":
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
					var measure_number_text = str(file_name)
					node = create_measure_number_node(measure_number_text)
					current_notation.node_type = "Label"
					notation_measure.measure_number_text = measure_number_text
				else:
					assert(false, "Expected notation category node not found! " + category)
				
				current_notation.add_child(node)

				if (category == "measure_line" and file_name != "measure_end") or category == "wholerest" or category.begins_with("multirest"):
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
			notation_measure.time_sig_notation = notation
			
		prev_notation_measure = notation_measure
	
	for i in range(notation_measure_list.size()):
		var notation_measure = notation_measure_list[i]
		notation_measure.construct(i)
	
	#after construct, add beams
	add_beam_nodes(stem_notation_nodes_both_voices, 1)
	add_beam_nodes(stem_notation_nodes_both_voices, 2)
	
func get_current_notation_seek_xPos():
	if time_xPos_points == null:
		return [null, null]
	var index = Utils.binary_search_closest_or_less(time_xPos_points, song.current_song_time, 0)
	if index < 0 or index >= time_xPos_points.size()-1:
		return [null, null]
	var current_time_point = time_xPos_points[index]
	var next_time_point = time_xPos_points[index+1]
	
	var current_time = current_time_point[0]
	var next_time = next_time_point[0]
	var current_xPos = current_time_point[1]
	var next_xPos = next_time_point[1]
	
	var xPos
	var is_next_line = false
	if next_xPos < current_xPos:
		var current_line_x_distance = staffline_x_max - current_xPos
		var next_line_x_distance = Global.START_OF_MEASURE_DRAW_DISTANCE
		var total_x_distance = float(current_line_x_distance + next_line_x_distance)
		var percentage_through_total_distance = Utils.convert_range(song.current_song_time, current_time, next_time, 0.0, 1.0)
		var percentage_current_line_distance = current_line_x_distance/total_x_distance
		var percentage_next_line_distance = 1.0 - percentage_current_line_distance
		if percentage_through_total_distance < percentage_current_line_distance:
			xPos = Utils.convert_range(percentage_through_total_distance, 0.0, percentage_current_line_distance, current_xPos, staffline_x_max)
		else:
			xPos = Utils.convert_range(percentage_through_total_distance-percentage_current_line_distance, 0.0, percentage_next_line_distance, next_xPos-next_line_x_distance, next_xPos)
			is_next_line = true
	else:
		xPos = Utils.convert_range(song.current_song_time, current_time, next_time, current_xPos, next_xPos)
	
	return [xPos, is_next_line]

func get_current_line_number_and_percentage_to_next_line(force_valid):
	var line_number = Utils.binary_search_closest_or_less(notation_lines, song.current_song_time, 0)
	
	var percentage_to_next_line
	if line_number == -1 or line_number == notation_lines.size()-1:
		percentage_to_next_line = 0
	else:
		var current_measure_index = notation_lines[line_number][1]
		var next_measure_index = notation_lines[line_number+1][1]
		var current_line_start_time = notation_measure_list[current_measure_index].time_xPos_points[0][0]
		var next_line_start_time = notation_measure_list[next_measure_index].time_xPos_points[0][0]
		percentage_to_next_line = Utils.convert_range(song.current_song_time, current_line_start_time, next_line_start_time, 0.0, 1.0)
	
	if force_valid:
		line_number = max(line_number, 0)
		line_number = min(line_number, notation_lines.size()-1)
		
	return [line_number, percentage_to_next_line]

func update_contents():
	#update page
	var get_current_line_number_and_percentage_to_next_line = get_current_line_number_and_percentage_to_next_line(true)
	var current_line_number = get_current_line_number_and_percentage_to_next_line[0]
	var percentage_to_next_line = get_current_line_number_and_percentage_to_next_line[1]
	
	if current_line_number != prev_line_number:
		for child in notation_display.get_children():
			notation_display.remove_child(child)
		
		time_xPos_points = []
		if is_panorama:
			display_measures_from_index(current_line_number, 0)
		else:
			for staffline_id in range(Global.NUM_NOTATION_ROWS+2):
				display_measures_from_index(current_line_number-2, staffline_id)
	
	prev_line_number = current_line_number
	
	# Update seek line
	seek_line.clear_points()
	var notation_xPos_data = get_current_notation_seek_xPos()
	var seek_x = notation_xPos_data[0]
	var is_next_line = notation_xPos_data[1]
	if seek_x:
		var seek_yMin
		var seek_yMax
		if is_panorama:
			seek_yMin = y_min + Global.STAFF_SPACE_HEIGHT
			seek_yMax = y_max - Global.STAFF_SPACE_HEIGHT
		else:
			var line_num = 2
			if is_next_line:
				line_num += 1
				
			var seek_yCenter = get_center_staff_line_yPos(line_num)
			seek_yMin = seek_yCenter - Global.STAFF_SPACE_HEIGHT*9
			seek_yMax = seek_yCenter + Global.STAFF_SPACE_HEIGHT*6
		seek_line.add_point(Vector2(seek_x, seek_yMin))
		seek_line.add_point(Vector2(seek_x, seek_yMax))
	
	if !is_panorama:
		var y_animated_offset = int(Utils.convert_range(percentage_to_next_line, 0, 1, 0, -Global.NOTATION_YSIZE))
		notation_display.position.y = y_animated_offset
		seek_line.position.y = y_animated_offset
		
func draw_background():
	background.modulate.a = 0.93
	background.position = Vector2(x_min, y_min)
	background.size = Vector2(x_size, y_size)
	
	background.material.set_shader_parameter("edge_fade_1", EDGE_FADE_1)
	background.material.set_shader_parameter("edge_fade_2", EDGE_FADE_2)
	background.material.set_shader_parameter("bounds_min", Vector2(0, 0))
	background.material.set_shader_parameter("bounds_max", Vector2(x_size, y_size))
	background.material.set_shader_parameter("custom_bounds", false)
	
	const SPIRAL_X_RADIUS = 20
	const SPIRAL_Y_SIZE = 20
	var num_steps
	var spiral_xPos
	if is_panorama:
		num_steps = 6
		spiral_xPos = SPIRAL_X_RADIUS*0.9
	else:
		num_steps = 21
		spiral_xPos = SPIRAL_X_RADIUS*0.5

	for i in range(num_steps):
		var spiral = Sprite2D.new()
		spiral.texture = load("res://textures/spiral.png")
		background.add_child(spiral)
		
		spiral.centered = false
		var spiral_yPos = y_size*(i/float(num_steps)) + SPIRAL_Y_SIZE*0.75
		Utils.set_sprite_position_and_scale(spiral, spiral_xPos-SPIRAL_X_RADIUS, spiral_yPos, spiral_xPos+SPIRAL_X_RADIUS, spiral_yPos+SPIRAL_Y_SIZE)
		
