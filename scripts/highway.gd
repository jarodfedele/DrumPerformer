extends Node2D

var audio_frame_count = 0
var audio_play_start_time = 0.0

var num_lanes = 6.0 #make sure this is a float!
var lane_position_list: Array = []
var chart_x_min_2: float = 0.0
var chart_x_max_2: float = 0.0
var horizon_x: float = 0.0
var horizon_y: float = 0.0

var current_song_time = 0.0
var previous_song_time = current_song_time
var visible_time_min
var visible_time_max

var note_data: Array = []
var beatline_data: Array = []
var hihatpedal_data: Array = []
var sustain_data: Array = []
var notation_data: Array = []
var staffline_data: Array = []
#other gameDataTables; don't forget to clear() the data

const Utils = preload("res://scripts/utils.gd")

@onready var audio_player = $"../AudioBar/AudioStreamPlayer"
@onready var notes = $Notes
@onready var beatlines = $BeatLines
@onready var notations = $"../Staff/Notations"
@onready var staff = $"../Staff"

func _physics_process(delta):
	if audio_player:
		if audio_frame_count == 60 or not audio_player.playing:
			sync_song_time(audio_player.get_playback_position())
			
		current_song_time = audio_play_start_time + (1.0/60.0)*audio_frame_count
		visible_time_min = current_song_time
		visible_time_max = visible_time_min + Global.VISIBLE_TIMERANGE
		
		notes.update_positions()
		beatlines.update_positions()
		
		previous_song_time = current_song_time
		audio_frame_count = audio_frame_count + 1

func sync_song_time(song_time):
	audio_frame_count = 0
	audio_play_start_time = song_time
	
func get_lane_position(lane: int) -> Array:
	if lane >= 0 and lane < lane_position_list.size():
		var data = lane_position_list[lane]
		return [data[0], data[1]]
	return []

func get_border_points() -> Array:
	var top_left = Vector2(get_lane_position(0)[1], Global.CHART_YMIN)
	var top_right = Vector2(get_lane_position(num_lanes)[1], Global.CHART_YMIN)
	var bottom_right = Vector2(get_lane_position(num_lanes)[0], Global.CHART_YMAX)
	var bottom_left = Vector2(get_lane_position(0)[0], Global.CHART_YMAX)
	
	return [bottom_left, bottom_right, top_right, top_left]

func get_fade_points() -> Array:
	var border_points = get_border_points()
	
	var bottom_left = border_points[0]
	var bottom_right = border_points[1]
	var top_right = border_points[2]
	var top_left = border_points[3]
	
	var fade_left_x = Utils.get_x_at_y(bottom_left.x, bottom_left.y, top_left.x, top_left.y, Global.CHART_YFADESTART)
	var fade_right_x = Utils.get_x_at_y(bottom_right.x, bottom_right.y, top_right.x, top_right.y, Global.CHART_YFADESTART)

	bottom_right = Vector2(fade_right_x, Global.CHART_YFADESTART)
	bottom_left = Vector2(fade_left_x, Global.CHART_YFADESTART)
	
	return [bottom_left, bottom_right, top_right, top_left]

func get_chart_x_min_2() -> float:
	return get_lane_position(0)[1]

func get_chart_x_max_2() -> float:
	return get_lane_position(num_lanes)[1]
		
func reset_lane_positions():
	lane_position_list.clear()

	for lane in range(num_lanes + 1):
		var angle = Utils.convert_range(lane, 0, num_lanes / 2, Global.MAX_ANGLE_DEGREES, 0)

		var x1 = Global.CHART_XMIN + Global.CHART_XSIZE*(lane/num_lanes)
		var y_max = Global.CHART_YMAX
		var y_min = Global.CHART_YMIN
		var x2 = Utils.rotate_line(x1, y_max, x1, y_min, angle)

		lane_position_list.append([x1, x2])
	
	#get horizon
	var x1_first = get_lane_position(0)[0]
	var y2_first = Global.CHART_YMIN
	var x2_first = get_lane_position(0)[1]
	var y1_first = Global.CHART_YMAX
	
	var x1_last = get_lane_position(num_lanes)[0]
	var y2_last = Global.CHART_YMIN
	var x2_last = get_lane_position(num_lanes)[1]
	var y1_last = Global.CHART_YMAX
	
	var result = Utils.get_intersection(x1_first, y1_first, x2_first, y2_first, x1_last, y1_last, x2_last, y2_last)

	horizon_x = result.x
	horizon_y = result.y

func get_y_pos_from_time(time: float, is_highway_skin: bool) -> float:
	var y_strikeline = Global.CHART_YMAX
	var time_at_half_horizon = Global.TRACK_SPEED

	if is_highway_skin:
		time_at_half_horizon *= 0.44  #TODO: find correct math

	var time_at_strikeline = current_song_time
	var future = time -  time_at_strikeline
	var halves = future / time_at_half_horizon
	return horizon_y + (y_strikeline - horizon_y) * pow(0.5, halves)

func process_general_data(values):
	var header = values[0]
	var val = values[1]
	
	if header == "center_staff_line":
		Global.center_staff_line = val*Global.STAFF_SPACE_HEIGHT + Global.NOTATION_YMIN
		for i in range(5):
			var yPos = Global.center_staff_line + (i-2)*Global.STAFF_SPACE_HEIGHT
			staffline_data.append(yPos)
	
func process_note_data(values):
	var time = values[0]
	var gem = values[1]
	var color = values[2]
	var lane_start = values[3]
	var lane_end = values[4]
	var velocity = values[5]
	var rgb = Utils.color_to_rgb(color)
	var color_r = rgb[0]
	var color_g = rgb[1]
	var color_b = rgb[2]
	
	if gem != "none":
		note_data.insert(0, [time, gem, color_r, color_g, color_b, lane_start, lane_end, velocity])

func process_beatline_data(values):
	var time = values[0]
	var color_r = values[1]
	var color_g = values[2]
	var color_b = values[3]
	var thickness = values[4]

	beatline_data.append([time, color_r, color_g, color_b, thickness])

func process_hihatpedal_data(values):
	var lane_start = values[0]
	var lane_end = values[1]
	var color = values[2]
	var rgb = Utils.color_to_rgb(color)
	var color_r = rgb[0]
	var color_g = rgb[1]
	var color_b = rgb[2]
	
	var bottom_left_x = get_lane_position(lane_start)[0]
	var top_left_x = get_lane_position(lane_start)[1]
	var bottom_right_x = get_lane_position(lane_end+1)[0]
	var top_right_x = get_lane_position(lane_end+1)[1]
	var lane_data = [bottom_left_x, top_left_x, bottom_right_x, top_right_x, color_r, color_g, color_b, []]
	
	for i in range(3, values.size(), 3):
		var time = values[i]
		var cc_val = values[i+1]
		var gradient_int = values[i+2]
		
		var alpha = Utils.convert_range(cc_val, 0, 127, 0, Global.MAX_HHPEDAL_ALPHA)/255.0
		var is_gradient = (gradient_int == 1)
		
		var point_data = [time, alpha, is_gradient]
		lane_data[7].append(point_data)
	
	hihatpedal_data.append(lane_data)
	
func process_sustain_data(values):
	var lane_start = values[0]
	var lane_end = values[1]
	var color = values[2]
	var sustain_type = values[3]
	var rgb = Utils.color_to_rgb(color)
	var color_r = rgb[0]
	var color_g = rgb[1]
	var color_b = rgb[2]
	
	var bottom_left_x = get_lane_position(lane_start)[0]
	var top_left_x = get_lane_position(lane_start)[1]
	var bottom_right_x = get_lane_position(lane_end+1)[0]
	var top_right_x = get_lane_position(lane_end+1)[1]
	var lane_data = [bottom_left_x, top_left_x, bottom_right_x, top_right_x, color_r, color_g, color_b, sustain_type, []]
	
	for i in range(4, values.size(), 3):
		var time = values[i]
		var cc_val = values[i+1]
		var gradient_int = values[i+2]
		
		var percentage = Utils.get_sustain_size_percentage(cc_val)
		var is_gradient = (gradient_int == 1)
		
		var point_data = [time, percentage, is_gradient]
		lane_data[8].append(point_data)
	
	sustain_data.append(lane_data)

func process_notation_data(values):
	var category = values[0]
	var time = values[1]
	if time == -1:
		time = null
	var file_name = values[2]
	var xMin = values[3] * Global.STAFF_SPACE_HEIGHT + Global.NOTATION_XMIN
	var yMin = values[4] * Global.STAFF_SPACE_HEIGHT + Global.NOTATION_YMIN
	var xMax = values[5] * Global.STAFF_SPACE_HEIGHT + Global.NOTATION_XMIN
	var yMax = values[6] * Global.STAFF_SPACE_HEIGHT + Global.NOTATION_YMIN
	var misc
	if values.size() > 7:
		misc = values[7]
	
	notation_data.append([category, time, file_name, xMin, yMin, xMax, yMax, misc])

func generate_valid_note_list():
	var path = Global.DEBUG_NOTE_LIST_PATH
	if FileAccess.file_exists(path):
		return
	
	var output = ""
	
	var dir = DirAccess.open(Global.GEMS_PATH)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			output += file_name + "\n"
		file_name = dir.get_next()

	# Write to a file inside res://
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(output)
	file.close()

func load_gem_texture(gem, png_name):
	var path = Global.GEMS_PATH + gem + "/" + png_name + ".png"
	var tex
	if Global.DEBUG_GEMS:
		var image = Image.new()
		tex = ImageTexture.new()
		if image.load(path) == OK:
			tex.set_image(image)
		else:
			tex = null
	else:
		tex = load(path)
	return tex

func get_gem_config_setting(gem, header):
	var gem_data = Global.gem_texture_list[Global.get_gem_index_in_list(gem)]
	var index
	
	if header == "shiftx":
		index = 5
	if header == "shifty":
		index = 6
	if header == "scale":
		index = 7
	if header == "blend_tint":
		index = 8
	if header == "blend_lighting":
		index = 9
	if header == "zorder":
		index = 10
	if header == "color_r":
		index = 11
	if header == "color_g":
		index = 12
	if header == "color_b":
		index = 13
	if header == "alpha":
		index = 14
	
	return gem_data[index]
			
func store_gem_textures_in_list():
	Global.gem_texture_list = []
	
	var dir = DirAccess.open(Global.GEMS_PATH)
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if name != "." and name != ".." and dir.current_is_dir():
			var gem = name
			
			var tex_tint = load_gem_texture(gem, "tint")
			var tex_tint_colored = load_gem_texture(gem, "tint_colored")
			var tex_base = load_gem_texture(gem, "base")
			var tex_ring = load_gem_texture(gem, "ring")
			
			var config_file_path = Global.get_gem_config_file_path(gem)
			var config_text = Utils.read_text_file(config_file_path)
			var positioning_shift_x
			var positioning_shift_y
			var positioning_scale
			var blend_tint
			var blend_lighting
			var z_order
			var color_r
			var color_g
			var color_b
			var color_a
			
			var lines = config_text.split("\n")
			for line in lines:
				var values = Utils.separate_string(line)
				if values.size() >= 2:
					var header = values[0].to_lower()
					var val = (values[1])
					if header == "shiftx":
						positioning_shift_x = float(val)
					if header == "shifty":
						positioning_shift_y = float(val)
					if header == "scale":
						positioning_scale = float(val)
					if header == "zorder":
						z_order = int(val)
					if header == "blend_tint":
						blend_tint = Global.get_blending_mode(val)
					if header == "blend_lighting":
						blend_lighting = Global.get_blending_mode(val)
					if header == "alpha":
						color_a = float(val)
					if header == "color_r":
						color_r = float(val)
					if header == "color_g":
						color_g = float(val)
					if header == "color_b":
						color_b = float(val)
						
			Global.gem_texture_list.append([
				gem, tex_tint, tex_tint_colored, tex_base, tex_ring,
				positioning_shift_x, positioning_shift_y, positioning_scale,
				blend_tint, blend_lighting,
				z_order,
				color_r, color_g, color_b, color_a
				])

		name = dir.get_next()
	dir.list_dir_end()
			
func reset_chart_data():
	note_data.clear()
	beatline_data.clear()
	hihatpedal_data.clear()
	sustain_data.clear()
	notation_data.clear()
	#other gameDataTables
	
	var text = Utils.read_text_file("res://gamedata.txt")
	var lines = text.split("\n")
	var current_section = null
	for line in lines:
		line = line.strip_edges()
		var values = Utils.separate_string(line)
		
		if values.size() == 1:
			current_section = line
		elif values.size() != 0:
			if current_section == "GENERAL":
				process_general_data(values)
			if current_section == "NOTES":
				process_note_data(values)
			if current_section == "BEAT_LINES":
				process_beatline_data(values)
			if current_section == "HIHAT_PEDAL":
				process_hihatpedal_data(values)	
			if current_section == "SUSTAIN":
				process_sustain_data(values)
			#if current_section == "NOTATIONS":
				#process_notation_data(values)
	
	generate_valid_note_list()
	store_gem_textures_in_list()
