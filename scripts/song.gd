extends Node

const VENUE_CANVAS_LAYER_SCENE = preload("res://scenes/venue_canvas_layer.tscn")

const BackButtonScene = preload("res://scenes/back_button.tscn")

@onready var notation_pages = $NotationPages

@onready var song_audio_player = get_node("/root/Game/AudioManager/SongAudioPlayer")
@onready var timecode = get_node("/root/Game/Song/AudioBar/Timecode")

var color_replace_shader = preload("res://shaders/color_replace.gdshader")

var highway
var staff
var audio_bar

var note_data: Array = []
var beatline_data: Array = []
var hihatpedal_data: Array = []
var sustain_data: Array = []
var notation_data: Array = []
#other gameDataTables; don't forget to clear() the data

var current_song_time = 0.0
var audio_play_start_time = 0.0
var audio_frame_count = 0

var loaded = false

func sync_song_time(time):
	audio_play_start_time = time - Global.calibration_seconds
	audio_frame_count = 0
	
func _physics_process(delta):
	if loaded:
		#sync song to visuals
		if audio_frame_count == 60 or not song_audio_player.playing:
			sync_song_time(song_audio_player.get_playback_position())
			
		current_song_time = audio_play_start_time + (1.0/60.0)*audio_frame_count
		
		#update timecode
		var length = song_audio_player.stream.get_length()
		if length and timecode:
			print("HERE: " + Utils.seconds_to_min_sec_string(current_song_time) + "/" + Utils.seconds_to_min_sec_string(length))
			timecode.text = Utils.seconds_to_min_sec_string(current_song_time) + "/" + Utils.seconds_to_min_sec_string(length)
		
		#update visible game contents
		highway.update_contents(current_song_time)
		staff.update_contents()
		
		audio_frame_count += 1

func set_audio_players_to_song():
	var audio_file = load(Global.current_song_path + "backing.wav")
	song_audio_player.stream = audio_file

func get_layout_coordinates(is_panorama):
	var highway_x_min
	var highway_y_min
	var highway_x_size
	var highway_y_size

	var staff_x_min
	var staff_y_min
	var staff_x_size
	var staff_y_size
	
	var viewport_size = get_viewport().get_visible_rect().size
	var base_width = viewport_size.x
	var base_height = viewport_size.y
	var x_center = base_width*0.5
	
	if is_panorama:
		staff_x_min = 15
		staff_x_size = base_width - staff_x_min
		staff_y_size = Global.NOTATION_YSIZE + Global.STAFF_SPACE_HEIGHT * 3
		staff_y_min = base_height - staff_y_size
		
		highway_x_size = Global.HIGHWAY_XSIZE
		highway_x_min = x_center - (highway_x_size*0.5)
		highway_y_size = Global.HIGHWAY_YSIZE
		highway_y_min = staff_y_min - highway_y_size
	
	else:
		staff_x_min = base_width * 0.4
		staff_x_size = base_width - staff_x_min
		staff_y_size = Global.NOTATION_YSIZE*Global.NUM_NOTATION_ROWS
		staff_y_min = base_height - staff_y_size
		
		highway_x_size = Global.HIGHWAY_XSIZE
		highway_x_min = (base_width-staff_x_size)*0.5 - (highway_x_size*0.5)
		highway_y_size = Global.HIGHWAY_YSIZE + 100
		highway_y_min = base_height - highway_y_size
		
	return [highway_x_min, highway_y_min, highway_x_size, highway_y_size,
		staff_x_min, staff_y_min, staff_x_size, staff_y_size]
		
func load_song(chart_type, song_folder_name, is_panorama):
	for child in get_children():
		child.queue_free()
	
	var dir
	if chart_type == Global.CHART_TYPE_SONG:
		dir = Directory.SONGS_DIR
	if chart_type == Global.CHART_TYPE_JAM_TRACK:
		dir = Directory.JAM_TRACKS_DIR
	if chart_type == Global.CHART_TYPE_LESSON:
		dir = Directory.LESSONS_DIR
	Global.current_song_path = dir + song_folder_name + "/"
	
	var venue_canvas_layer = VENUE_CANVAS_LAYER_SCENE.instantiate()
	venue_canvas_layer.layer = -2
	add_child(venue_canvas_layer)
	
	loaded = false
	
	var data_arrays = NoteCompiler.run(chart_type)
	reset_chart_data()
	var note_data = data_arrays[0]
	var sustain_data = data_arrays[1]
	var hihat_pedal_data = data_arrays[2]
	
	var viewport_size = get_viewport().get_visible_rect().size
	var base_width = viewport_size.x
	var base_height = viewport_size.y
	var x_center = base_width*0.5

	var layout_coordinates = get_layout_coordinates(is_panorama)
	
	var highway_x_min = layout_coordinates[0]
	var highway_y_min = layout_coordinates[1]
	var highway_x_size = layout_coordinates[2]
	var highway_y_size = layout_coordinates[3]
	
	var staff_x_min = layout_coordinates[4]
	var staff_y_min = layout_coordinates[5]
	var staff_x_size = layout_coordinates[6]
	var staff_y_size = layout_coordinates[7]
		
	highway = Highway.create(Global.drum_kit["Lanes"], true, 
		highway_x_min, highway_y_min, highway_x_size, highway_y_size, 
		beatline_data, hihat_pedal_data, sustain_data, note_data)
	add_child(highway)
	highway.update_contents(0)
	
	staff = Staff.create(true, is_panorama, staff_x_min, staff_y_min, staff_x_size, staff_y_size)
	add_child(staff)
	
	set_audio_players_to_song()
		
	var audio_bar_x_size = 1300
	var audio_bar_x_min = x_center - (audio_bar_x_size*0.5)

	audio_bar = AudioBar.create(song_audio_player, audio_bar_x_min, 30, audio_bar_x_size, 60)
	add_child(audio_bar)
	
	link_notes_between_highway_and_staff()
	
	var back_button = BackButtonScene.instantiate()
	add_child(back_button)
	
	loaded = true

func link_notes_between_highway_and_staff():
	var notes = highway.get_notes()
	notes.sort_custom(func(a, b):
		return a.midi_id < b.midi_id
	)
	
	var midi_ids = []
	for note in notes:
		midi_ids.append(note.midi_id)
		
	for notation in staff.noteheads:
		var index = Utils.binary_search_exact(midi_ids, notation.midi_id, -1)
		var note = notes[index]
		note.linked_notations.append(notation)
		notation.color_r = note.notation_color_r
		notation.color_g = note.notation_color_g
		notation.color_b = note.notation_color_b
		var notation_sprite = notation.get_child_node()
		var shader_material = ShaderMaterial.new()
		shader_material.shader = color_replace_shader
		notation_sprite.material = shader_material
		notation_sprite.material.set_shader_parameter("tint_color", Color(notation.color_r, notation.color_g, notation.color_b))
			
func process_general_data(values):
	var header = values[0]
	var val = values[1]
	
	if header == "center_staff_line":
		Global.center_staff_line_index = val

func process_beatline_data(values):
	var time = values[0]
	var type = values[1]
	beatline_data.append([time, type])

func process_hihatpedal_data(values):
	var lane_start = values[0]
	var lane_end = values[1]
	var color = values[2]
	var rgb = Utils.color_to_rgb(color)
	var color_r = rgb[0]
	var color_g = rgb[1]
	var color_b = rgb[2]
	
	var bottom_left_x = highway.get_lane_position(lane_start)[0]
	var top_left_x = highway.get_lane_position(lane_start)[1]
	var bottom_right_x = highway.get_lane_position(lane_end+1)[0]
	var top_right_x = highway.get_lane_position(lane_end+1)[1]
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
	
	var bottom_left_x = highway.get_lane_position(lane_start)[0]
	var top_left_x = highway.get_lane_position(lane_start)[1]
	var bottom_right_x = highway.get_lane_position(lane_end+1)[0]
	var top_right_x = highway.get_lane_position(lane_end+1)[1]
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
	notation_data[notation_data.size()-1].append(values)
	
func reset_chart_data():
	note_data.clear()
	beatline_data.clear()
	hihatpedal_data.clear()
	sustain_data.clear()
	notation_data.clear()
	#other gameDataTables
	
	var text = Global.current_gamedata
	var lines = text.split("\n")
	var current_section = null
	for line in lines:
		line = line.strip_edges()
		var values = Utils.separate_string(line)
		
		if values.size() == 1 and values[0] == values[0].to_upper():
			current_section = line
		elif values.size() != 0:
			if current_section == "GENERAL":
				process_general_data(values)
			if current_section == "BEAT_LINES":
				process_beatline_data(values)
			if current_section == "NOTATIONS":
				if values[0] == "measure":
					notation_data.append([])
				else:
					process_notation_data(values)
