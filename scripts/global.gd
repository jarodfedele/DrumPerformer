extends Node

var DEBUG_MODE = true

@onready var song = get_node("/root/Game/Song")

const HIGHWAY_XMIN = 30
const HIGHWAY_YMIN = 0
const HIGHWAY_XSIZE = 700
const HIGHWAY_YSIZE = 600
const HIGHWAY_XMAX = HIGHWAY_XMIN + HIGHWAY_XSIZE 
const HIGHWAY_YMAX = HIGHWAY_YMIN + HIGHWAY_YSIZE
const HIGHWAY_HITWINDOW_MS = 100.0
const STAFF_SPACE_HEIGHT = 14

const NOTATION_XSIZE = 1920
const NOTATION_YSIZE = STAFF_SPACE_HEIGHT * 24

const HUD_XMIN = 700
const HUD_YMIN = 100
const HUD_XMAX = 100
const HUD_YMAX = 700
const HUD_XSIZE = HUD_XMAX - HUD_XMIN
const HUD_YSIZE = HUD_YMAX- HUD_YMIN

const TRACK_SPEED = 0.75
const MAX_ANGLE_DEGREES = 25
const VISIBLE_TIMERANGE = TRACK_SPEED * 3
const MAX_HHPEDAL_ALPHA = 125
const MIN_VELOCITY_SIZE_PERCENTAGE = 0.4

const STAFF_BACKGROUND_COLOR = Color8(255, 255, 200)

const ORIGINAL_GEMS_PATH = "res://assets/gems/"
var GEMS_PATH = ORIGINAL_GEMS_PATH
var DEBUG_GEMS = false
const NOTATIONS_PATH = "res://assets/notations/"

var current_profile

var setting_tint_colored = true
var lighting_fps = 20
var lighting_alpha = 255
var debug_selected_gem = null
var debug_update_notes = true
var hud_yPos = 0
const HUD_SLIDER_LENGTH = 200
const HUD_LABEL_XPOS = HUD_SLIDER_LENGTH + 10
const NOTATION_DRAW_AREA_XOFFSET = 64
const NOTATION_BOUNDARYXMINOFFSET = -12
const MEASURE_START_SPACING = 12
var center_staff_line_index

var gem_texture_list

var current_song_path: String
var current_gamedata: String

var music_master_volume: float
var music_drumless_volume: float
var music_drum_volume: float
var drum_input_volume: float

var midi_input_count = 0

var drum_kit
var profiles_list

const NUM_VELOCITY_CURVE_TYPES = 2

const NOTE_ON = 9
const NOTE_OFF = 8
const CC = 11

const VALID_PAD_TYPES = ["kick", "snare", "racktom", "floortom", "hihat", "ride", "crash"]
const VALID_ZONE_KEYS = ["head", "rim", "sidestick", "bow", "edge", "bell", "splash", "stomp"]

var calibration_seconds = 100.0 * 0.001

var game : Game

func _ready():
	if not DirAccess.dir_exists_absolute(GEMS_PATH):
		GEMS_PATH = ORIGINAL_GEMS_PATH
		DEBUG_GEMS = false

func does_gem_exist(gem):
	var index = get_gem_index_in_list(gem)
	return (index != null)
	
func is_zone_enabled(pad, zone_name):
	for pad_and_zone in get_enabled_zones():
		if pad == pad_and_zone[0] and zone_name == pad_and_zone[2]:
			return true
	return false

func is_valid_midi_number(str):
	if str is String:
		return false
	if float(str) != int(str):
		return false
	var int_number = int(str)
	if int_number < 0 or int_number > 127:
		return false
	return true

func does_zone_require_multiple_values(pad, zone_name):
	return pad.has("PedalSendsMIDI") and pad["PedalSendsMIDI"] == false and zone_name != "stomp" and zone_name != "splash"

func get_drumkit_error_messages():
	var list = []
	var kick_count = 0
	var snare_count = 0
	var racktom_count = 0
	var floortom_count = 0
	var hihat_count = 0
	var ride_count = 0
	var crash_count = 0
	
	var note_on_list = []
	var note_off_list = []
	var cc_num_list = []
	
	if Global.drum_kit["Input"] not in MidiInputManager.midi_inputs:
		list.append("Current MIDI Input not found!")
	if Global.drum_kit["Channels"].size() == 0:
		list.append("At least one channel must be enabled!")
			
	for pad in Global.drum_kit["Pads"]:
		if pad.has("PositionalSensingControlChange") and pad["PositionalSensing"]:
			var val = pad["PositionalSensingControlChange"]
			if is_valid_midi_number(val):
				cc_num_list.append(int(val))
			else:
				list.append("Invalid MIDI Positional Sensing Value: " + pad["Name"])
		if pad.has("PedalControlChange") and pad["PedalSendsMIDI"]:
			var val = pad["PedalControlChange"]
			if is_valid_midi_number(val):
				cc_num_list.append(int(val))
			else:
				list.append("Invalid MIDI Pedal Value: " + pad["Name"])
						
		var pad_type = pad["Type"]
		
		if pad_type == "kick":
			kick_count += 1
		if pad_type == "snare":
			snare_count += 1
		if pad_type == "racktom":
			racktom_count += 1
		if pad_type == "floortom":
			floortom_count += 1
		if pad_type == "hihat":
			hihat_count += 1
		if pad_type == "ride":
			ride_count += 1
		if pad_type == "crash":
			crash_count += 1
	
	for pad_and_zone in get_enabled_zones():
		var pad = pad_and_zone[0]
		var zone = pad_and_zone[1]
		var zone_name = pad_and_zone[2]
		
		if zone.has("Note"):
			var val = zone["Note"]
			if val is Array:
				for number in val:
					if is_valid_midi_number(number):
						note_on_list.append(int(number))
					else:
						list.append("Invalid MIDI Note: " + pad["Name"] + " (" + zone_name + ")")
						break
			else:
				if does_zone_require_multiple_values(pad, zone_name):
					list.append("Invalid MIDI Note List: " + pad["Name"] + " (" + zone_name + ")")
				elif is_valid_midi_number(val):
					note_on_list.append(int(val))
				else:
					list.append("Invalid MIDI Note: " + pad["Name"] + " (" + zone_name + ")")	
	
	if kick_count < 1:
		list.append("One kick required!")
	if snare_count < 1:
		list.append("One snare required!")
	if racktom_count < 1:
		list.append("Two rack toms required!")
	if floortom_count < 1:
		list.append("One floor tom required!")
	if hihat_count < 1:
		list.append("One hi-hat required!")
	if ride_count < 1:
		list.append("One ride required!")
	if crash_count < 1:
		list.append("One crash required!")
	
	var note_on_duplicates = Utils.get_duplicates(note_on_list)
	for duplicate in note_on_duplicates:
		list.append("Note #" + str(duplicate) + " is set multiple times!")
	var note_off_duplicates = Utils.get_duplicates(note_off_list)
	for duplicate in note_off_duplicates:
		list.append("Note-Off #" + str(duplicate) + " is set multiple times!")
	var cc_num_duplicates = Utils.get_duplicates(cc_num_list)
	for duplicate in cc_num_duplicates:
		list.append("Control Change #" + str(duplicate) + " is set multiple times!")
		
	return list

func get_zone(type, pitch):
	for pad_and_zone in get_enabled_zones():
		var pad = pad_and_zone[0]
		var zone = pad_and_zone[1]
		var zone_name = pad_and_zone[2]
		if type == "noteon":
			if zone.has("Note"):
				var val = zone["Note"]
				if val is Array:
					for number in val:
						if int(number) == pitch:
							return pad_and_zone
				else:
					if int(val) == pitch:
						return pad_and_zone
			
func get_enabled_zones():
	var list = []
	for pad in Global.drum_kit["Pads"]:
		var pad_type = pad["Type"]
		for key in pad.keys():
			if key in Global.VALID_ZONE_KEYS:
				var zone_name = key
				var zone = pad[key]
				if !zone.has("Enabled") or zone["Enabled"]:
					list.append([pad, zone, zone_name])
	return list

func increment_hud_yPos():
	hud_yPos += 45

func generate_alpha_texture(alpha_values: PackedFloat32Array) -> ImageTexture:
	if alpha_values.size() == 0:
		return
		
	var h = alpha_values.size()
	var image = Image.create(1, h, false, Image.FORMAT_RF)
	for y in range(h):
		image.set_pixel(0, y, Color(alpha_values[y], 0, 0))

	var tex = ImageTexture.create_from_image(image)
	return tex

func get_gem_index_in_list(gem):
	for i in range(gem_texture_list.size()):
		var gem_data = gem_texture_list[i]
		if gem_data[0] == gem:
			return i
			
func get_gem_texture(gem, list_index):
	var gem_data = gem_texture_list[get_gem_index_in_list(gem)]
	return gem_data[list_index]

func get_gem_config_file_path(gem):
	return Global.GEMS_PATH + gem + "/config.txt"
		
static func get_blending_mode(blending_mode: String):
	if blending_mode == "color_burn":
		return 1
	if blending_mode == "linear_burn":
		return 2	
	if blending_mode == "hard_light":
		return 3
	if blending_mode == "soft_light":
		return 4
	if blending_mode == "color_dodge":
		return 5
	if blending_mode == "linear_dodge":
		return 6
	
	return 0

static func set_process_recursive(node, is_enabled):
	if node.has_method("_process") or node.has_method("_physics_process"):
		node.set_process(is_enabled)
		node.set_physics_process(is_enabled)
	
	for child in node.get_children():
		if child is Node:
			set_process_recursive(child, is_enabled)

static func generate_lighting_frame_list(gem):
	var path = Global.GEMS_PATH + gem + "/lighting_frames.txt"
	if FileAccess.file_exists(path):
		return
		
	var output = ""
	
	var gem_path = Global.GEMS_PATH + gem + "/"
	var dir = DirAccess.open(gem_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if "lighting" in file_name and file_name.ends_with(".png"):
				output += gem_path + file_name + "\n"
			file_name = dir.get_next()
		dir.list_dir_end()

	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(output)
	file.close()
	
static func store_gem_textures_in_list():
	Global.gem_texture_list = []
	
	var dir = DirAccess.open(Global.GEMS_PATH)
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if name != "." and name != ".." and dir.current_is_dir():
			var gem = name
			
			generate_lighting_frame_list(gem)
			
			var tex_tint = Global.load_gem_texture(gem, "tint")
			var tex_tint_colored = Global.load_gem_texture(gem, "tint_colored")
			var tex_base = Global.load_gem_texture(gem, "base")
			var tex_ring = Global.load_gem_texture(gem, "ring")
			
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
					if header == "color_r":
						color_r = float(val)
					if header == "color_g":
						color_g = float(val)
					if header == "color_b":
						color_b = float(val)
					if header == "color_a":
						color_a = float(val)
						
			Global.gem_texture_list.append([
				gem, tex_tint, tex_tint_colored, tex_base, tex_ring,
				positioning_shift_x, positioning_shift_y, positioning_scale,
				blend_tint, blend_lighting,
				z_order,
				color_r, color_g, color_b, color_a
				])

		name = dir.get_next()
	dir.list_dir_end()

static func load_gem_texture(gem, png_name):
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
		if ResourceLoader.exists(path):
			tex = load(path)
		
	return tex

static func get_gem_config_setting(gem, header, default_val):
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
	if header == "color_a":
		index = 14
	
	var result = gem_data[index]
	if result == null:
		result = default_val
	return result

func debug_set_gem_property(gem, header, val):
	if not Global.debug_update_notes:
		return
		
	var file_path = Global.get_gem_config_file_path(gem)
	var config_text = Utils.read_text_file(file_path)
	var lines = config_text.split("\n")
	var found_header = false
	var line_to_add = header + " " + str(val)
	for i in range(lines.size()):
		var line = lines[i]
		if line.substr(0, header.length()+1) == header + " ":
			found_header = true
			lines[i] = line_to_add
			break
	if not found_header:
		lines.append(line_to_add)
		
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		for line in lines:
			if line.strip_edges() != "":
				file.store_line(line)
		file.close()
	
	song.load_song(Global.current_song_path)

func get_value_from_key(line: String, key: String) -> Variant:
	line = line.strip_edges(true, false)  # Remove trailing spaces only
	var values = line.split(" ")
	for val in values:
		var parsed = get_key_and_value(val)
		if parsed and parsed[0] == key:
			var result = parsed[1]
			var num = result.to_float()
			if str(num) == result or str(int(num)) == result:
				return num
			return result
	return null

func get_key_and_value(str: String) -> Array:
	var equals_index = str.find("=")
	var space_index = str.find(" ")

	if space_index != -1 or equals_index == -1:
		push_error("Bad line in get_key_and_value(): " + str)
		return []
	
	var key = str.substr(0, equals_index)
	var value = str.substr(equals_index + 1)
	return [key, value]
