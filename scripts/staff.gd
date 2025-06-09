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
var initial_x_offset
var default_center_staff_line_yPos
var clef_xMin
var clef_yMin
var clef_xMax
var clef_yMax
var clef_scale

var notation_measure_list : Array

var time_xPos_points : Array
var notation_lines : Array
var notation_page_starting_time_pos_list : Array

var noteheads : Array
var hairpins : Array
var tempos : Array

var stem_yPos_both_voices

@onready var song = get_parent()

@onready var background = $Background
@onready var contents_sub_viewport = $ContentsSubViewport
@onready var notation_display = %NotationDisplay
@onready var seek_line = $SeekLine
@onready var contents_display = $ContentsDisplay
@onready var panorama_clef = %PanoramaClef
@onready var panorama_staff_line_stubs = %PanoramaStaffLineStubs

var notation_line_list
var notation_time_list

var prev_line_number

const XPOS_INDEX = 0
const NOTE_LIST_INDEX = 2
const PAGE_INDEX = 3

const STAFF_SCENE: PackedScene = preload("res://scenes/staff.tscn")
const NOTATION_MEASURE_SCENE = preload("res://scenes/notation_measure.tscn")
const NOTATION_SCENE = preload("res://scenes/notation.tscn")
const DYNAMIC_SCENE = preload("res://scenes/dynamic.tscn")

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
	instance.initial_x_offset = instance.staffline_x_min - instance.x_min
	
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
	
	instance.notation_page_starting_time_pos_list = []
	
	return instance

func _ready():
	stem_yPos_both_voices = [default_center_staff_line_yPos-Global.STAFF_SPACE_HEIGHT*7, default_center_staff_line_yPos+Global.STAFF_SPACE_HEIGHT*5]

	draw_background()
	
	populate_notations()
	
	store_notation_lines()
	
	panorama_clef.visible = is_panorama
	if is_panorama:
		panorama_clef.texture = load(Global.CLEF_PATH)
		panorama_clef.centered = false
		panorama_clef.position = Vector2(clef_xMin, default_center_staff_line_yPos-Global.STAFF_SPACE_HEIGHT+y_min)
		panorama_clef.scale = clef_scale
	
	var bound_xMin
	if is_panorama:
		bound_xMin = clef_xMax  + Global.STAFF_SPACE_HEIGHT*0.5
		
		#staff lines
		for i in range(5):
			var yPos = default_center_staff_line_yPos + (i-2)*Global.STAFF_SPACE_HEIGHT + y_min
			var line = Line2D.new()
			line.default_color = Color.BLACK
			line.width = 2
			line.add_point(Vector2(staffline_x_min, yPos))
			line.add_point(Vector2(bound_xMin + Global.STAFF_SPACE_HEIGHT*3, yPos))
			panorama_staff_line_stubs.add_child(line)
	else:
		bound_xMin = x_min
	contents_display.texture = contents_sub_viewport.get_texture()
	contents_display.material.set_shader_parameter("edge_fade_1", EDGE_FADE_1)
	contents_display.material.set_shader_parameter("edge_fade_2", EDGE_FADE_2)
	contents_display.material.set_shader_parameter("bounds_min", Vector2(bound_xMin, y_min))
	contents_display.material.set_shader_parameter("bounds_max", Vector2(x_min+x_size, y_min+y_size))
	contents_display.material.set_shader_parameter("custom_bounds", true)
		
	if is_panorama:
		var line_yMin = get_line_yMin(0)
		var x_offsets = notation_lines[0][2]
		var measure_index = 0
		for x_offset in x_offsets:
			var notation_measure = notation_measure_list[measure_index]
			notation_measure.position.x = x_offset
			notation_measure.position.y = line_yMin
			measure_index += 1
		
		for line_number in range(notation_page_starting_time_pos_list.size()):
			var position_x_offset = notation_page_starting_time_pos_list[line_number][1]
			if line_number > 0:
				position_x_offset += -initial_x_offset*2
			position_x_offset = -position_x_offset + notation_page_starting_time_pos_list[0][1]
			notation_page_starting_time_pos_list[line_number][1] = position_x_offset
		
		display_measures_from_index(0, 0)
	else:
		var initial_y_offset = get_line_yMin(0) + (y_size*0.5)
		for notation_line_number in range(notation_lines.size()):
			var line_yMin = get_line_yMin(notation_line_number)
			var starting_measure_index = notation_lines[notation_line_number][1]
			var x_offsets = notation_lines[notation_line_number][2]
			
			var measure_index = starting_measure_index
			for x_offset in x_offsets:
				var notation_measure = notation_measure_list[measure_index]
				notation_measure.position.x = x_offset
				notation_measure.position.y = line_yMin
				measure_index += 1
			
			display_measures_from_index(notation_line_number, 0)
			
			var starting_notation_measure = notation_measure_list[starting_measure_index]
			var time = starting_notation_measure.time_xPos_points[0][0]
			notation_page_starting_time_pos_list.append([time, -(line_yMin-initial_y_offset), starting_notation_measure])
		
	add_hairpins_to_display()
	add_ties_to_display()
	
func create_measure_number_node(measure_number_text):
	var node = Label.new()
	node.text = measure_number_text

	var label_settings = LabelSettings.new()
	var font = FontFile.new()
	font.set_data(Global.FONT_ACADEMICO_REGULAR.get_data())

	label_settings.font = font
	label_settings.font_size = 16
	label_settings.font_color = Color.BLACK
	node.set_label_settings(label_settings)
	
	return node
	
func get_justify_x_offset(xPos, boundary_x_min, current_x_boundary_max, final_x_boundary_max):
	return Utils.convert_range(xPos, boundary_x_min, current_x_boundary_max, boundary_x_min, final_x_boundary_max) - xPos
	
func get_consecutive_measure_x_offsets(starting_measure_index) -> Array:
	var x_offsets = []
	var ended_last_measure = true
	
	var x_offset = initial_x_offset
	var panorama_position_x = x_offset
	if is_panorama:
		var time = notation_measure_list[0].time_xPos_points[0][0]
		notation_page_starting_time_pos_list.append([time, panorama_position_x, notation_measure_list[0]])
		
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
		
		if is_panorama:
			var recent_panorama_x_position = notation_page_starting_time_pos_list[notation_page_starting_time_pos_list.size()-1][1]
			if x_offset-recent_panorama_x_position+x_min > staffline_x_max*0.95 and measure_index > 0:
				var time = notation_measure.time_xPos_points[0][0]
				var prev_measure = notation_measure_list[measure_index-1]
				var prev_x_offset = x_offsets[x_offsets.size()-2] + prev_measure.size_x
				notation_page_starting_time_pos_list.append([time, prev_x_offset, notation_measure])
				
		if x_offset > staffline_x_max and !is_panorama:
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
						var leger_line_justify_xPos = Utils.convert_range(0.75, 0, 1, xMin, xMax)
						var justify_xMin_offset = get_justify_x_offset(xMin, boundary_x_min, current_x_boundary_max, final_x_boundary_max)
						var justify_xMax_offset = get_justify_x_offset(xMax, boundary_x_min, current_x_boundary_max, final_x_boundary_max)
						var justify_leger_line_offset = get_justify_x_offset(leger_line_justify_xPos, boundary_x_min, current_x_boundary_max, final_x_boundary_max)
						
						if notation.category == "multirest_rect" or notation.category == "tuplet_line":
							notation.xMin += justify_xMin_offset
							notation.xMax += justify_xMax_offset
						elif notation.category == "leger_line":
							notation.xMin += justify_leger_line_offset
							notation.xMax += justify_leger_line_offset
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
	
	if !is_panorama and starting_measure_index + x_offsets.size() >= notation_measure_list.size():
		ended_last_measure = true
	
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
		
		fix_rest_collision(notation_measure, 1)
		fix_rest_collision(notation_measure, 2)
		fix_staff_text_and_tempo_collision(notation_measure)

func is_any_collision(rects_to_move, rects_static):
	for rect in rects_to_move:
		for rect_static in rects_static:
			if rect.intersects(rect_static):
				return true
	return false
	
func get_collision_y_offset(rects_to_move: Array, rects_static: Array, move_up: bool):
	const EXTRA_PIXELS = 4
	for i in range(rects_static.size()):
		var rect_static = rects_static[i]
		rect_static.position.y -= EXTRA_PIXELS / 2.0
		rect_static.size.y += EXTRA_PIXELS
		rects_static[i] = rect_static
		
	var direction
	if move_up:
		direction = -1
	else:
		direction = 1
	var increment = Global.STAFF_SPACE_HEIGHT * direction
	
	var y_offset = 0
	while is_any_collision(rects_to_move, rects_static):
		y_offset += increment
		for i in range(rects_to_move.size()):
			var rect = rects_to_move[i]
			rect.position.y += increment
			rects_to_move[i] = rect
		
	return y_offset
			
func fix_rest_collision(notation_measure, voice_index: int):
	var rests = []
	var static_notations = []
	for notation in notation_measure.get_children():
		var category = notation.category
		if category == "rest" and notation.voice_index == voice_index:
			rests.append(notation)
		if category == "notehead" or category == "gracenotehead":
			static_notations.append(notation)
	
	var rects_to_move = []
	var rects_static = []
	for notation in rests:
		var rect = Utils.make_rect(notation.xMin, notation.yMin, notation.xMax, notation.yMax)
		rects_to_move.append(rect)
	for notation in static_notations:
		var rect = Utils.make_rect(notation.xMin, notation.yMin, notation.xMax, notation.yMax)
		rects_static.append(rect)
		
	var collision_y_offset = get_collision_y_offset(rects_to_move, rects_static, voice_index==1)
	for rest in rests:
		rest.yMin += collision_y_offset
		rest.yMax += collision_y_offset
		rest.position.y += collision_y_offset

func fix_staff_text_and_tempo_collision(notation_measure):
	var staff_text_notations = []
	var static_notations = []
	for notation in notation_measure.get_children():
		var category = notation.category
		if category == "staff_text" or category == "tempo":
			staff_text_notations.append(notation)
		if category == "notehead" or category == "gracenotehead" or category == "rest" or category == "stem" or category == "gracestem" or category == "tuplet_line" or category == "tuplet_number" or category == "articulation":
			static_notations.append(notation)
	
	var rects_to_move = []
	var rects_static = []
	for notation in staff_text_notations:
		var rect = Utils.make_rect(notation.xMin, notation.yMin, notation.xMax, notation.yMax)
		rects_to_move.append(rect)
	for notation in static_notations:
		var rect = Utils.make_rect(notation.xMin, notation.yMin, notation.xMax, notation.yMax)
		rects_static.append(rect)
	var collision_y_offset = get_collision_y_offset(rects_to_move, rects_static, true)
	for notation in staff_text_notations:
		notation.yMin += collision_y_offset
		notation.yMax += collision_y_offset
		notation.position.y += collision_y_offset
				
func get_measure_from_time(time): #TODO: binary search optimization
	for notation_measure in notation_measure_list:
		if time >= notation_measure.get_measure_time():
			return notation_measure
		
func draw_staff_line_body(line_x_min, line_x_max, center_staff_line_yPos):
	#staff lines
	for i in range(5):
		var yPos = center_staff_line_yPos + (i-2)*Global.STAFF_SPACE_HEIGHT
		var line = Line2D.new()
		line.default_color = Color.BLACK
		line.width = 2
		line.add_point(Vector2(line_x_min, yPos))
		line.add_point(Vector2(line_x_max, yPos))

		notation_display.add_child(line)

func get_line_yMin(staffline_id):
	if is_panorama:
		staffline_id = 0
	return y_min + staffline_id*Global.NOTATION_YSIZE
	
func get_center_staff_line_yPos(staffline_id):
	return default_center_staff_line_yPos + get_line_yMin(staffline_id)

func update_notation_line(notation_line_number, staffline_id):
	var line_yMin = get_line_yMin(staffline_id)
	var starting_measure_index = notation_lines[notation_line_number][1]
	var x_offsets = notation_lines[notation_line_number][2]
	
	var measure_index = starting_measure_index
	for x_offset in x_offsets:
		var notation_measure = notation_measure_list[measure_index]
		notation_measure.position.x = x_offset
		notation_measure.position.y = line_yMin
		measure_index += 1
		
func update_notation_measure_positions(current_line_number, starting_staffline_id):
	if is_panorama:
		pass
	else:
		for notation_line_number in range(notation_lines.size()):
			var staffline_id = notation_line_number - current_line_number + starting_staffline_id
			update_notation_line(notation_line_number, staffline_id)
			#var line_yMin = get_line_yMin(staffline_id)
			#var starting_measure_index = notation_lines[notation_line_number][1]
			#var x_offsets = notation_lines[notation_line_number][2]
			#
			#var measure_index = starting_measure_index
			#for x_offset in x_offsets:
				#var notation_measure = notation_measure_list[measure_index]
				#notation_measure.position.x = x_offset
				#notation_measure.position.y = line_yMin
				#measure_index += 1

func display_measures_from_index(starting_notation_line_number, staffline_id):
	var notation_line_number = starting_notation_line_number + staffline_id
	if notation_line_number < 0 or notation_line_number >= notation_lines.size():
		return
	
	var line_yMin = get_line_yMin(staffline_id)
	var center_staff_line_yPos = get_center_staff_line_yPos(starting_notation_line_number)
	
	var starting_measure_index = notation_lines[notation_line_number][1]
	var x_offsets = notation_lines[notation_line_number][2]
	var ended_last_measure = notation_lines[notation_line_number][3]
	
	#clef
	if !is_panorama:
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
						var beam1_xMax = staffline_x_max
						var beam1_x_size = beam1_xMax - beam1_xMin
						var stem1_yPos = prev_stem_notation.yMin+prev_notation_measure.position.y
						add_beam_node(prev_notation_measure, beam1_xMin, beam1_x_size, stem1_yPos, beam_id, voice_index, true)
						
						var beam2_x_size = Global.START_OF_MEASURE_DRAW_DISTANCE
						var beam2_xMin = current_stem_notation.xMin+notation_measure.position.x - beam2_x_size
						var stem2_yPos = current_stem_notation.yMin+notation_measure.position.y
						add_beam_node(notation_measure, beam2_xMin, beam2_x_size, stem2_yPos, beam_id, voice_index, true)
					
					else:
						var beam_xMin = prev_stem_notation.xMin+prev_notation_measure.position.x
						var beam_xMax = current_stem_notation.xMin+notation_measure.position.x
						var beam_x_size = beam_xMax - beam_xMin
						var stem_yPos = prev_stem_notation.yMin+notation_measure.position.y
						add_beam_node(prev_notation_measure, beam_xMin, beam_x_size, stem_yPos, beam_id, voice_index, true)
						
		measure_index += 1

	#staff lines
	var line_x_max
	if ended_last_measure:
		var last_notation_measure = notation_measure_list[notation_measure_list.size()-1]
		line_x_max = last_notation_measure.position.x + last_notation_measure.size_x
		if !is_panorama:
			line_x_max = min(line_x_max, staffline_x_max)
	else:
		line_x_max = staffline_x_max
	draw_staff_line_body(staffline_x_min, line_x_max, center_staff_line_yPos)
	
	#var next_starting_measure_index
	#if !ended_last_measure and !is_panorama:
		#next_starting_measure_index = starting_measure_index + x_offsets.size()
	#return next_starting_measure_index

func add_beam_node(parent_node, beam_xMin, beam_x_size, stem_yPos, beam_id, voice_index, over_measure):
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
	if over_measure:
		beam_node.position.x -= parent_node.position.x
		beam_node.position.y -= parent_node.position.y
		var notation = NOTATION_SCENE.instantiate()
		notation.category = "beam"
		notation.add_child(beam_node)
		parent_node.add_child(notation)
	else:
		parent_node.add_child(beam_node)
		
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
		
func add_normal_beam_nodes(stem_notation_nodes_both_voices, voice_index):
	var stem_notation_nodes = stem_notation_nodes_both_voices[voice_index-1]
	for i in range(1, stem_notation_nodes.size()):
		var current_notation = stem_notation_nodes[i]
		var prev_notation = stem_notation_nodes[i-1]
		add_beam_type(current_notation, prev_notation, 0, voice_index)
		add_beam_type(current_notation, prev_notation, 1, voice_index)
		add_beam_type(current_notation, prev_notation, 2, voice_index)
		
func populate_notations():
	noteheads = []
	hairpins = []
	tempos = []
	
	var stem_notation_nodes_both_voices = [[], []]
	
	notation_measure_list = []
	
	var current_notation
	var prev_category
	var prev_notation_measure
	
	for measure_data_index in range(song.notation_data.size()):
		var measure_data = song.notation_data[measure_data_index]
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
				
				if category == "sprite" or category == "notehead" or category == "rest" or category == "flag" or category == "graceflag" or category == "dot" or category == "articulation" or category == "ghost" or category == "measure_line" or category == "timesig" or category == "wholerest" or category == "multirest_number" or category == "tuplet_number" or category == "roll" or category == "choke" or category == "dynamic_sprite":
					node = Sprite2D.new()
					current_notation.node_type = "Sprite2D"
					var file_path = Global.NOTATIONS_PATH + file_name + ".png"
					node.texture = load(file_path)
					
					node.centered = false
					Utils.set_sprite_position_and_scale(node, 0, 0, xMax-xMin, yMax-yMin)
					
					if category == "notehead" or category == "gracenotehead":
						var note_str = str(misc)
						current_notation.voice_index = int(note_str.substr(0, 1))
						current_notation.has_tie = int(note_str.substr(1, 1)) == 1
						current_notation.midi_id = int(note_str.substr(2))
						node.z_index = 1
						noteheads.append(current_notation)
					if category == "rest":
						var note_str = str(misc)
						current_notation.voice_index = int(note_str)
					if category == "timesig":
						time_sig_notations.append(current_notation)
						
				elif category == "line" or category == "wholerest_dummy" or category == "stem" or category == "gracestem" or category == "graceline" or category == "leger_line" or  category == "multirest_line" or category == "tuplet_line" or category == "dummyline":
					node = Line2D.new()
					current_notation.node_type = "Line2D"
					node.default_color = Color(0, 0, 0)
					if category == "wholerest_dummy":
						node.default_color.a = 0
					node.width = 2
					if category == "stem":
						var digits = []
						for c in str(int(misc)).split(""):
							digits.append(int(c))
						current_notation.voice_index = digits[0]
						digits.remove_at(0)
						current_notation.beam_integers = digits
						stem_notation_nodes_both_voices[current_notation.voice_index-1].append(current_notation)
				elif category == "rect" or category == "multirest_rect" or category == "gracebeam":
					node = ColorRect.new()
					current_notation.node_type = "ColorRect"
				elif category == "staff_text":
					node = Label.new()
					node.text = str(misc)
					
					var label_settings = LabelSettings.new()
					var font = FontFile.new()
					font.set_data(Global.FONT_ACADEMICO_ITALIC.get_data())

					label_settings.font = font
					var font_size = 20
					label_settings.font_size = font_size
					label_settings.font_color = Color.BLACK
					node.set_label_settings(label_settings)
					
					var text_width = font.get_string_size(node.text).x
					
					current_notation.xMax = current_notation.xMin + text_width
					current_notation.yMax = default_center_staff_line_yPos - Global.STAFF_SPACE_HEIGHT*3
					current_notation.yMin = current_notation.yMax - font.get_ascent(font_size)
					
				elif category == "measure_number":
					var measure_number_text = str(file_name)
					node = create_measure_number_node(measure_number_text)
					current_notation.node_type = "Label"
					notation_measure.measure_number_text = measure_number_text
				elif category == "tempo":
					for extra_index in range(7, data.size()):
						var str = data[extra_index]
						var key_and_value = str.split("=")
						var key = key_and_value[0]
						var value = key_and_value[1]
						if key == "bpm":
							var parts = value.split(",")
							var bpm_basis_filename = parts[0]
							var bpm_basis_has_dot = bpm_basis_filename.ends_with("d")
							if bpm_basis_has_dot:
								bpm_basis_filename = bpm_basis_filename.substr(0, bpm_basis_filename.length()-1)
							var bpm_value = parts[1]
							current_notation.bpm_basis_filename = bpm_basis_filename
							current_notation.bpm_basis_has_dot = bpm_basis_has_dot
							current_notation.bpm_value = bpm_value
						if key == "direction":
							var performance_direction = value
							current_notation.performance_direction = performance_direction
					current_notation.yMax = default_center_staff_line_yPos - Global.STAFF_SPACE_HEIGHT*3
					current_notation.yMin = current_notation.yMax - Global.STAFF_SPACE_HEIGHT*2
					
					var bpm_basis_filename = current_notation.bpm_basis_filename
					var bpm_basis_has_dot = current_notation.bpm_basis_has_dot
					var bpm_value = current_notation.bpm_value
					var performance_direction = current_notation.performance_direction
					
					var bound_yMax = current_notation.yMax
					var bound_yMin = current_notation.yMin
					var bound_size = bound_yMax-bound_yMin
					
					var current_x_position_offset = 0
					
					var sprite
					var tex_size_x
					var tex_size_y
					var desired_size_x
					var desired_size_y
					var scaling_factor
					
					if bpm_value:
						sprite = Sprite2D.new()
						sprite.texture = load(Global.NOTATIONS_PATH + bpm_basis_filename + ".png")
						tex_size_x = float(sprite.texture.get_width())
						tex_size_y = float(sprite.texture.get_height())
						desired_size_y = bound_yMax - bound_yMin
						scaling_factor = desired_size_y/tex_size_y
						desired_size_x = tex_size_x*scaling_factor
						sprite.centered = false
						sprite.scale = Vector2(desired_size_x/tex_size_x, desired_size_y/tex_size_y)
						sprite.position.x += current_x_position_offset
						current_notation.add_child(sprite)
						
						if bpm_basis_has_dot:
							current_x_position_offset += Global.STAFF_SPACE_HEIGHT*1.3
							
							sprite = Sprite2D.new()
							sprite.texture = load(Global.NOTATIONS_PATH + "dot.png")
							tex_size_x = float(sprite.texture.get_width())
							tex_size_y = float(sprite.texture.get_height())
							desired_size_y = bound_yMax - bound_yMin
							scaling_factor = desired_size_y/tex_size_y
							desired_size_x = tex_size_x*scaling_factor
							sprite.centered = false
							sprite.scale = Vector2(desired_size_x/tex_size_x, desired_size_y/tex_size_y)*0.13
							sprite.position.x += current_x_position_offset
							sprite.position.y += bound_size*0.8
							current_notation.add_child(sprite)
							
							current_x_position_offset += Global.STAFF_SPACE_HEIGHT*0.8
						else:
							current_x_position_offset += Global.STAFF_SPACE_HEIGHT*1.7
						
						var label
						var text
						var label_settings
						var font
						var font_size
						var text_size
						var text_width
						var text_height
						
						label = Label.new()
						text = "= " + bpm_value
						if performance_direction:
							text += "  " + performance_direction
						label.text = text

						label_settings = LabelSettings.new()
						font = FontFile.new()
						font.set_data(Global.FONT_ACADEMICO_BOLD.get_data())

						label_settings.font = font
						font_size = 22
						label_settings.font_size = font_size
						label_settings.font_color = Color.BLACK
						label.set_label_settings(label_settings)
						
						text_size = font.get_string_size(label.text, 0, -1, font_size)
						text_width = text_size.x
						text_height = text_size.y
						
						label.position.x += current_x_position_offset
						label.position.y += (bound_yMax-bound_yMin) - font.get_ascent(font_size) - Global.STAFF_SPACE_HEIGHT*0.1
						
						current_notation.add_child(label)
						
						current_x_position_offset += text_width + Global.STAFF_SPACE_HEIGHT*1.3
					
					current_notation.xMax = current_notation.xMin + current_x_position_offset
					
					tempos.append(current_notation)
					
				elif category == "dynamic_hairpin":
					current_notation.hairpin_type = str(misc)
					hairpins.append(current_notation)
				else:
					assert(false, "Expected notation category node not found! " + category)
				
				if node != null:
					current_notation.add_child(node)

				if (category == "measure_line" and file_name != "measure_end") or ((category == "wholerest" or category == "wholerest_dummy") and int(misc) == 0) or category.begins_with("multirest"):
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
	add_normal_beam_nodes(stem_notation_nodes_both_voices, 1)
	add_normal_beam_nodes(stem_notation_nodes_both_voices, 2)
	
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

func get_line_number_and_percentage_to_next_line(time, force_valid):
	var arr
	var line_number
	if is_panorama:
		arr = notation_page_starting_time_pos_list
		line_number = Utils.binary_search_closest_or_less(arr, time, 0)
	else:
		arr = notation_lines
		line_number = Utils.binary_search_closest_or_less(arr, time, 0)
	
	var percentage_to_next_line
	var current_measure
	var next_measure
	if line_number == -1 or line_number == arr.size()-1:
		percentage_to_next_line = 0
	else:
		if is_panorama:
			current_measure = arr[line_number][2]
			next_measure = arr[line_number+1][2]
		else:
			current_measure = notation_measure_list[notation_lines[line_number][1]]
			next_measure = notation_measure_list[notation_lines[line_number+1][1]]
		var current_line_start_time = current_measure.time_xPos_points[0][0]
		var next_line_start_time = next_measure.time_xPos_points[0][0]
		percentage_to_next_line = Utils.convert_range(time, current_line_start_time, next_line_start_time, 0.0, 1.0)
	
	if force_valid:
		line_number = max(line_number, 0)
		line_number = min(line_number, arr.size()-1)
	
	return [line_number, percentage_to_next_line]

func add_hairpins_to_display():
	var hairpin_line_nodes = []
	
	for hairpin_id in range(0, hairpins.size(), 2):
		var hairpin_start = hairpins[hairpin_id]
		var hairpin_end = hairpins[hairpin_id+1]
			
		var notation_measure_start = hairpin_start.get_parent()
		var notation_measure_end = hairpin_end.get_parent()
		var measure_index_start = notation_measure_start.measure_index
		var measure_index_end = notation_measure_end.measure_index
		var line_number_start = Utils.binary_search_closest_or_less(notation_lines, measure_index_start, 1)
		var line_number_end = Utils.binary_search_closest_or_less(notation_lines, measure_index_end, 1)
		var xPos_start = hairpin_start.xMin + notation_measure_start.position.x
		var xPos_end = hairpin_end.xMin + notation_measure_end.position.x
		
		var hairpin_bounds = [] #holds hairpin xMin and xMax for each staffline
		var x_total = 0
		for line_number in range(line_number_start, line_number_end+1):
			var xMin
			var xMax
			if line_number == line_number_start and line_number == line_number_end:
				xMin = xPos_start
				xMax = xPos_end
			elif line_number == line_number_start:
				xMin = xPos_start
				xMax = staffline_x_max
			elif line_number == line_number_end:
				xMin = clef_xMax+Global.STAFF_SPACE_HEIGHT*1.5
				xMax = xPos_end
			else:
				xMin = clef_xMax+Global.STAFF_SPACE_HEIGHT*1.5
				xMax = staffline_x_max
			
			var starting_measure = notation_measure_list[notation_lines[line_number][1]]
			var starting_measure_position_y = starting_measure.position.y	
			var yPos = default_center_staff_line_yPos + Global.STAFF_SPACE_HEIGHT*4 + starting_measure_position_y
			hairpin_bounds.append([xMin, xMax, yPos, line_number])
			x_total += xMax - xMin
		
		var current_percentage_start = 0
		for bound in hairpin_bounds:
			var percentage = (bound[1] - bound[0])/x_total
			var percentage_start = current_percentage_start
			var percentage_end = current_percentage_start + percentage
			bound.append(percentage_start)
			bound.append(percentage_end)
			current_percentage_start = percentage_end
		
		var type = hairpin_start.hairpin_type
		for bound in hairpin_bounds:
			var percentage = (bound[1] - bound[0])/x_total
			var percentage_start = bound[4]
			var percentage_end = bound[5]
			if type == "diminuendo" or type == "decrescendo":
				percentage_start = 1 - percentage_start
				percentage_end = 1 - percentage_end
			
			var distance_from_center_left = (Global.HAIRPIN_YSIZE*0.5)*percentage_start
			var distance_from_center_right = (Global.HAIRPIN_YSIZE*0.5)*percentage_end
			
			var yMin_left = bound[2] - distance_from_center_left
			var yMax_left = bound[2] + distance_from_center_left
			var yMin_right = bound[2] - distance_from_center_right
			var yMax_right = bound[2] + distance_from_center_right
			
			var line_number = bound[3]
			
			var line_top = Line2D.new()
			line_top.default_color = Color.BLACK
			line_top.width = 2
			line_top.add_point(Vector2(bound[0], yMin_left))
			line_top.add_point(Vector2(bound[1], yMin_right))
			line_top.antialiased = true
			notation_display.add_child(line_top)
			hairpin_line_nodes.append([line_top, line_number, measure_index_start, measure_index_end])
			
			var line_bottom = Line2D.new()
			line_bottom.default_color = Color.BLACK
			line_bottom.width = 2
			line_bottom.add_point(Vector2(bound[0], yMax_left))
			line_bottom.add_point(Vector2(bound[1], yMax_right))
			notation_display.add_child(line_bottom)
			hairpin_line_nodes.append([line_bottom, line_number])
			
	for line_number in range(notation_lines.size()):
		var notation_line = notation_lines[line_number]
		
		var dynamic_sprite_notations = []
		var static_notations = []
		var has_hairpins = false
		for line_data in hairpin_line_nodes:
			if line_data[1] == line_number:
				has_hairpins = true
				break
		
		var starting_measure_index = notation_line[1]
		var x_offsets = notation_line[2]
		for i in range(x_offsets.size()):
			var notation_measure = notation_measure_list[starting_measure_index+i]
			for notation in notation_measure.get_children():
				var category = notation.category
				if category == "dynamic_sprite":
					dynamic_sprite_notations.append(notation)
				if category == "notehead" or category == "gracenotehead" or category == "rest" or category == "stem" or category == "gracestem" or category == "tuplet_line" or category == "tuplet_number" or category == "articulation":
					static_notations.append(notation)
		
		var dynamic_yMin = default_center_staff_line_yPos + Global.STAFF_SPACE_HEIGHT*3
		var dynamic_yMax = dynamic_yMin + Global.STAFF_SPACE_HEIGHT*2

		if has_hairpins and !is_panorama:
			var rects_static = []
			for notation in static_notations:
				var rect = Utils.make_rect(notation.xMin, notation.yMin, notation.xMax, notation.yMax)
				rects_static.append(rect)
			
			var rect = [Utils.make_rect(-10000, dynamic_yMin, 10000, dynamic_yMax)]
			var collision_y_offset = get_collision_y_offset(rect, rects_static, false)
			for notation in dynamic_sprite_notations:
				notation.position.y = collision_y_offset
			for line_data in hairpin_line_nodes:
				var line = line_data[0]
				if line_data[1] == line_number:
					line.position.y = collision_y_offset
		else:
			#should be panorama only
			for line_id in range(0, hairpin_line_nodes.size(), 2):
				var node_top = hairpin_line_nodes[line_id][0]
				var node_bottom = hairpin_line_nodes[line_id+1][0]
				var measure_index_start = hairpin_line_nodes[line_id][2]
				var measure_index_end = hairpin_line_nodes[line_id][3]
				
				if hairpin_line_nodes[line_id][1] == line_number: #should always be the case
					var rects_static_within_measures = []
					for static_notation in static_notations:
						var static_notation_measure_index = static_notation.get_parent().measure_index
						if static_notation_measure_index >= measure_index_start and static_notation_measure_index <= measure_index_end:
							var rect = Utils.make_rect(static_notation.xMin, static_notation.yMin, static_notation.xMax, static_notation.yMax)
							rects_static_within_measures.append(rect)
						
					var rect = [Utils.make_rect(-10000, dynamic_yMin, 10000, dynamic_yMax)]
					var collision_y_offset = get_collision_y_offset(rect, rects_static_within_measures, false)
					node_top.position.y = collision_y_offset
					node_bottom.position.y = collision_y_offset
					
			for notation in dynamic_sprite_notations:
				var measure_index = notation.get_parent().measure_index
				var rects_static_within_measure = []
				for static_notation in static_notations:
					if static_notation.get_parent().measure_index == measure_index:
						var rect = Utils.make_rect(static_notation.xMin, static_notation.yMin, static_notation.xMax, static_notation.yMax)
						rects_static_within_measure.append(rect)
						
				var rect = [Utils.make_rect(notation.xMin, dynamic_yMin, notation.xMax, dynamic_yMax)]
				var collision_y_offset = get_collision_y_offset(rect, rects_static_within_measure, false)
				notation.position.y = collision_y_offset
				
func add_tie(xMin, xMax, y1, y2, notation_measure):
	var xSize = xMax - xMin
	var y_diff = y2 - y1
	
	var curve = Curve2D.new()
	curve.add_point(Vector2(xMin, y1), Vector2.ZERO, Vector2(xSize*Global.TIE_XPERCENTAGE, y_diff*Global.TIE_YPERCENTAGE))
	curve.add_point(Vector2(xMax, y1), Vector2(xSize*Global.TIE_XPERCENTAGE*-1, y_diff*Global.TIE_YPERCENTAGE), Vector2.ZERO)
	
	var total_length = curve.get_baked_length()
	var points = []
	var segments = 30

	for i in range(segments + 1):
		var t = float(i) / segments
		var distance = t * total_length
		points.append(curve.sample_baked(distance))
						
	#var polygon = Polygon2D.new()
	#polygon.polygon = PackedVector2Array(points)
	#polygon.color = Color.BLACK
	#notation_display.add_child(polygon)
	
	var line = Line2D.new()
	line.points = PackedVector2Array(points)
	line.default_color = Color.BLACK
	line.width = 2
	line.position.x -= notation_measure.position.x
	line.position.y -= notation_measure.position.y
	var notation = NOTATION_SCENE.instantiate()
	notation.category = "tie"
	notation.add_child(line)
	notation_measure.add_child(notation)
						
func add_ties_to_display():
	var noteheads_currently_awaiting_ties = []
	for notehead in noteheads:
		var midi_id = notehead.midi_id

		for notehead_awaiting_tie_end in noteheads_currently_awaiting_ties:
			if notehead_awaiting_tie_end.midi_id == midi_id:
				noteheads_currently_awaiting_ties.erase(notehead_awaiting_tie_end)
				var notehead_start = notehead_awaiting_tie_end
				var notehead_end = notehead
				
				var measure_start = notehead_start.get_parent()
				var measure_end = notehead_end.get_parent()
				var measure_index_start = measure_start.measure_index
				var measure_index_end = measure_end.measure_index
				var line_number_start = Utils.binary_search_closest_or_less(notation_lines, measure_index_start, 1)
				var line_number_end = Utils.binary_search_closest_or_less(notation_lines, measure_index_end, 1)
				var voice_index = notehead_start.voice_index

				if line_number_start == line_number_end:
					var xMin = notehead_start.xMax + measure_start.position.x + Global.TIE_XGAP
					var xMax = notehead_end.xMax + measure_end.position.x - Global.TIE_XGAP*2
					var y1
					var y2
					if voice_index == 1:
						y1 = notehead_start.yMin + measure_start.position.y - Global.TIE_YGAP
						y2 = y1 - Global.TIE_HEIGHT
					else:
						y1 = notehead_start.yMax + measure_start.position.y + Global.TIE_YGAP
						y2 = y1 + Global.TIE_HEIGHT
					add_tie(xMin, xMax, y1, y2, measure_start)
				else:
					var xMin_1 = notehead_start.xMax + measure_start.position.x + Global.TIE_XGAP
					var xMax_1 = staffline_x_max - Global.TIE_XGAP*2
					var y1_1
					var y2_1
					if voice_index == 1:
						y1_1 = notehead_start.yMin + measure_start.position.y - Global.TIE_YGAP
						y2_1 = y1_1 - Global.TIE_HEIGHT
					else:
						y1_1 = notehead_start.yMax + measure_start.position.y + Global.TIE_YGAP
						y2_1 = y1_1 + Global.TIE_HEIGHT
					add_tie(xMin_1, xMax_1, y1_1, y2_1, measure_start)

					var xMin_2 = clef_xMax+Global.STAFF_SPACE_HEIGHT*1.5 + Global.TIE_XGAP
					var xMax_2 = notehead_end.xMin + measure_end.position.x - Global.TIE_XGAP*2
					var y1_2
					var y2_2
					if voice_index == 1:
						y1_2 = notehead_end.yMin + measure_end.position.y - Global.TIE_YGAP
						y2_2 = y1_2 - Global.TIE_HEIGHT
					else:
						y1_2 = notehead_end.yMax + measure_end.position.y + Global.TIE_YGAP
						y2_2 = y1_2 + Global.TIE_HEIGHT
					add_tie(xMin_2, xMax_2, y1_2, y2_2, measure_end)
				break
		if notehead.has_tie:
			noteheads_currently_awaiting_ties.append(notehead)

func run_hiding_animation(child_node):
	var tween = get_tree().create_tween()
	tween.tween_property(child_node, "modulate:a", 0.08, 1.0)

	#TODO: tween entire viewport shader
	#tween.tween_method(set_shader_value, 0.0, 1.0, 2); # args are: (method to call / start value / end value / duration of animation)
	##tween value automatically gets passed into this function
	#func set_shader_value(value: float):
		## in my case i'm tweening a shader on a texture rect, but you can use anything with a material on it
		#$TextureRect.material.set_shader_parameter("your_shader_param", value);

func hide_notation_measure_items(notation_measure):
	for notation in notation_measure.get_children():
		var category = notation.category
		#TODO: beam over measures
		if category == "stem" or category == "beam" or category == "tie" or category == "gracestem" or category == "gracebeam" or category == "flag" or category == "graceflag" or category == "graceline" or category == "rest" or category == "articulation" or category == "ghost" or category == "dot" or category == "leger_line" or category == "tuplet_line" or category == "tuplet_number" or category == "roll" or category == "choke":
			var child_node = notation.get_child_node()
			run_hiding_animation(child_node)

func update_contents():
	#update page
	var current_line_number_and_percentage_to_next_line = get_line_number_and_percentage_to_next_line(song.current_song_time, true)
	var current_line_number = current_line_number_and_percentage_to_next_line[0]
	var percentage_to_next_line = current_line_number_and_percentage_to_next_line[1]
	
	var low_percentage_bound
	if is_panorama:
		low_percentage_bound = 0.95
	else:
		low_percentage_bound = 0
		
	var position_offset = notation_page_starting_time_pos_list[current_line_number][1]
	if percentage_to_next_line > low_percentage_bound:
		var next_position_offset = notation_page_starting_time_pos_list[current_line_number+1][1]
		var animated_offset = Utils.convert_range(percentage_to_next_line, low_percentage_bound, 1, position_offset, next_position_offset)
		position_offset = animated_offset
	if is_panorama:
		notation_display.position.x = position_offset
	else:
		notation_display.position.y = position_offset
		
	if current_line_number != prev_line_number:
		#animate hiding
		if !is_panorama and prev_line_number != null and prev_line_number > -1 and prev_line_number < notation_lines.size():
			var prev_notation_line = notation_lines[prev_line_number]
			var starting_measure_index = prev_notation_line[1]
			var x_offsets = prev_notation_line[2]
			for i in range(x_offsets.size()):
				var measure_index = starting_measure_index + i
				var notation_measure = notation_measure_list[measure_index]
				hide_notation_measure_items(notation_measure)
				
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
			var line_num = current_line_number
			if is_next_line:
				line_num += 1
				
			var seek_yCenter = get_center_staff_line_yPos(line_num)
			seek_yMin = seek_yCenter - Global.STAFF_SPACE_HEIGHT*9
			seek_yMax = seek_yCenter + Global.STAFF_SPACE_HEIGHT*6
		seek_line.add_point(Vector2(seek_x, seek_yMin))
		seek_line.add_point(Vector2(seek_x, seek_yMax))
	
	if is_panorama:
		seek_line.position.x = position_offset
	else:
		seek_line.position.y = position_offset
		
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
		
