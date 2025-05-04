extends Node2D

@onready var song_audio_player = get_node("/root/Game/AudioManager/SongAudioPlayer")
@onready var highway = get_node("/root/Game/Song/Highway") #TODO: programatically generate?
@onready var staff = get_node("/root/Game/Song/Staff")
@onready var timecode = get_node("/root/Game/Song/AudioBar/Timecode")

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

func sync_song_time(time):
	audio_play_start_time = time
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
			timecode.text = Utils.seconds_to_min_sec_string(current_song_time) + "/" + Utils.seconds_to_min_sec_string(length)
		
		#update visible game contents
		highway.update_contents()
		staff.update_contents()
		
		audio_frame_count += 1

func set_audio_players_to_song():
	var audio_file = load(Global.current_song_path + "backing.wav")
	song_audio_player.stream = audio_file
	
func load_song(song_path):
	loaded = false
	
	if song_path != Global.current_song_path:
		Global.current_song_path = song_path
		set_audio_players_to_song()
	
	Global.current_gamedata = Utils.read_text_file(song_path + "gamedata.txt")
	
	highway.reset_lane_position_list() #TODO: dependent on user profile
	
	highway.draw_background()
	highway.draw_border()
	highway.draw_cover()
	
	staff.draw_background()
	staff.draw_cover()
	
	reset_chart_data()
	
	highway.populate_beat_lines()
	highway.populate_hihat_pedal_overlays()
	highway.populate_sustain_overlays()
	highway.populate_notes()
	
	staff.draw_clef()
	staff.draw_staff_lines()
	staff.populate_notations()
	staff.take_screenshots()
	
	loaded = true
	
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
	var xMin = values[3] * Global.STAFF_SPACE_HEIGHT + Global.NOTATION_XMIN
	var yMin = values[4] * Global.STAFF_SPACE_HEIGHT + Global.NOTATION_YMIN
	var xMax = values[5] * Global.STAFF_SPACE_HEIGHT + Global.NOTATION_XMIN
	var yMax = values[6] * Global.STAFF_SPACE_HEIGHT + Global.NOTATION_YMIN
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
	
	Global.store_gem_textures_in_list() #TODO: move to global when done debugging
	
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
			if current_section == "NOTES":
				process_note_data(values)
			if current_section == "BEAT_LINES":
				process_beatline_data(values)
			if current_section == "HIHAT_PEDAL":
				process_hihatpedal_data(values)	
			if current_section == "SUSTAIN":
				process_sustain_data(values)
			if current_section == "NOTATIONS":
				process_notation_data(values)
	
	Global.generate_valid_note_list()
