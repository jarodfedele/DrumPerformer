extends Node

const VenueCanvasLayerScene = preload("res://scenes/venue_canvas_layer.tscn")
const ViewportHighway3DScene = preload("res://scenes/viewport_highway_3d.tscn")
const Highway3DScene = preload("res://scenes/highway_3d.tscn")

const StaffScene = preload("res://scenes/staff.tscn")

const BackButtonScene = preload("res://scenes/back_button.tscn")


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
var staffline_data: Array = []
#other gameDataTables; don't forget to clear() the data

var current_song_time = 0.0
var audio_play_start_time = 0.0
var audio_frame_count = 0

var loaded = false

func update_contents():
	load_song("res://test_song/")

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
	
func load_song(song_path):
	for child in get_children():
		child.queue_free()
	
	var venue_canvas_layer = VenueCanvasLayerScene.instantiate()
	venue_canvas_layer.layer = -2
	add_child(venue_canvas_layer)
	
	#var canvas_layer = CanvasLayer.new()
	#var viewport_container = SubViewportContainer.new()
	#var viewport_highway_3d = ViewportHighway3DScene.instantiate()
	#viewport_container.add_child(viewport_highway_3d)
	#canvas_layer.add_child(viewport_container)
	#canvas_layer.layer = -1
	#add_child(canvas_layer)
	
	#var highway_3d = Highway3DScene.instantiate()
	#add_child(highway_3d)
		
	loaded = false
	
	Global.current_gamedata = Utils.read_text_file(song_path + "gamedata.txt")
	reset_chart_data()
	
	var data_arrays = NoteCompiler.run(highway)
	var note_data = data_arrays[0]
	var sustain_data = data_arrays[1]
	var hihat_pedal_data = data_arrays[2]
	
	var viewport_size = get_viewport().get_visible_rect().size
	var base_width = viewport_size.x
	var base_height = viewport_size.y
	var x_center = base_width*0.5
	
	var highway_x_min = x_center - (Global.HIGHWAY_XSIZE*0.5)
	var highway_y_max = base_height-Global.NOTATION_YSIZE
	var highway_y_min = highway_y_max-Global.HIGHWAY_YSIZE
	highway = Highway.create(Global.drum_kit["Lanes"], true, 
		highway_x_min, highway_y_min, Global.HIGHWAY_XSIZE, Global.HIGHWAY_YSIZE, 
		beatline_data, hihat_pedal_data, sustain_data, note_data)
	add_child(highway)
	highway.update_contents(0)
	
	staff = Staff.create(true, 0, 0, highway_y_max, base_width, base_height)
	add_child(staff)
	
	var audio_bar_x_size = 1300
	var audio_bar_x_min = x_center - (audio_bar_x_size*0.5)

	audio_bar = AudioBar.create(song_audio_player, audio_bar_x_min, 30, audio_bar_x_size, 60)
	add_child(audio_bar)

	if song_path != Global.current_song_path:
		Global.current_song_path = song_path
		set_audio_players_to_song()
	
	staff.populate_notations()
	#staff.take_screenshots()
	
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
		notation.color_r = note.color_r
		notation.color_g = note.color_g
		notation.color_b = note.color_b
		var notation_sprite = notation.get_children()[0]
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
	var category = values[0]
	var time = values[1]
	if time == -1:
		time = null
	var file_name = values[2]
	var xMin = values[3] * Global.STAFF_SPACE_HEIGHT
	var yMin = values[4] * Global.STAFF_SPACE_HEIGHT
	var xMax = values[5] * Global.STAFF_SPACE_HEIGHT
	var yMax = values[6] * Global.STAFF_SPACE_HEIGHT
	var misc
	if values.size() > 7:
		misc = values[7]
	
	notation_data.append([category, time, file_name, xMin, yMin, xMax, yMax, misc])

func reset_chart_data():
	staffline_data.clear()

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
		
		if values.size() == 1:
			current_section = line
		elif values.size() != 0:
			if current_section == "GENERAL":
				process_general_data(values)
			if current_section == "BEAT_LINES":
				process_beatline_data(values)
			if current_section == "NOTATIONS":
				process_notation_data(values)
