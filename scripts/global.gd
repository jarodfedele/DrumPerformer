extends Node

@onready var song = get_node("/root/Game/Song")

const HIGHWAY_XMIN = 30
const HIGHWAY_YMIN = 0
const HIGHWAY_XSIZE = 700
const HIGHWAY_YSIZE = 600
const HIGHWAY_XMAX = HIGHWAY_XMIN + HIGHWAY_XSIZE 
const HIGHWAY_YMAX = HIGHWAY_YMIN + HIGHWAY_YSIZE
const HIGHWAY_YFADESTART = HIGHWAY_YMIN + HIGHWAY_YSIZE*0.2

const STAFF_SPACE_HEIGHT = 10

const NOTATION_XMIN = 100
const NOTATION_YMIN = HIGHWAY_YMAX + 6
const NOTATION_XSIZE = 1166
const NOTATION_YSIZE = STAFF_SPACE_HEIGHT * 24
const NOTATION_XMAX = NOTATION_XMIN + NOTATION_XSIZE
const NOTATION_YMAX = NOTATION_YMIN + NOTATION_YSIZE

const AUDIOBAR_XMIN = HIGHWAY_XMIN + HIGHWAY_XSIZE*0.7
const AUDIOBAR_YMIN = HIGHWAY_YMIN + 20
const AUDIOBAR_XSIZE = 740
const AUDIOBAR_YSIZE = 60
const AUDIOBAR_XMAX = AUDIOBAR_XMIN + AUDIOBAR_XSIZE 
const AUDIOBAR_YMAX = AUDIOBAR_YMIN + AUDIOBAR_YSIZE

const PLAYBUTTON_XMIN = AUDIOBAR_XMAX + 10
const PLAYBUTTON_YMIN = AUDIOBAR_YMIN
const PLAYBUTTON_XSIZE = AUDIOBAR_YSIZE
const PLAYBUTTON_YSIZE = PLAYBUTTON_XSIZE
const PLAYBUTTON_XMAX = PLAYBUTTON_XMIN + PLAYBUTTON_XSIZE
const PLAYBUTTON_YMAX = PLAYBUTTON_YMIN + PLAYBUTTON_YSIZE

const HUD_XMIN = (AUDIOBAR_XMIN + PLAYBUTTON_XMIN) * 0.5
const HUD_YMIN = PLAYBUTTON_YMAX + 50
const HUD_XMAX = PLAYBUTTON_XMAX
const HUD_YMAX = NOTATION_YMIN - 30
const HUD_XSIZE = HUD_XMAX - HUD_XMIN
const HUD_YSIZE = HUD_YMAX- HUD_YMIN

const TRACK_SPEED = 0.75
const MAX_ANGLE_DEGREES = 25
const VISIBLE_TIMERANGE = TRACK_SPEED * 3
const MAX_HHPEDAL_ALPHA = 125
const MIN_VELOCITY_SIZE_PERCENTAGE = 0.4

const STAFF_BACKGROUND_COLOR = Color8(255, 255, 200)

var USER_PATH = "C:/Users/jarod/Desktop/DrumPerformer/"
const ORIGINAL_GEMS_PATH = "res://assets/gems/"
var GEMS_PATH = ORIGINAL_GEMS_PATH
var DEBUG_GEMS = false
const NOTATIONS_PATH = "res://assets/notations/"
const DEBUG_NOTE_LIST_PATH = "res://note_list.txt"

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
var center_staff_line

var gem_texture_list

var current_song_path: String
var current_gamedata: String

var music_master_volume: float
var music_drumless_volume: float
var music_drum_volume: float
var drum_input_volume: float

var midi_input_count = 0

var config_path = USER_PATH + "config/"
var drum_kit_path = config_path + "drum_kit.json"
var profiles_path = config_path + "profiles.json"
var drum_kit
var profiles_list

const ZONE_DEFAULTS_PATH = "res://zone_defaults.json"
var zone_defaults = []

const NUM_VELOCITY_CURVE_TYPES = 2
var VALID_PAD_TYPES

const NOTE_ON = 9
const NOTE_OFF = 8
const CC = 11

var valid_zone_keys = ["Head", "Rim", "Side Stick", "Bow", "Edge", "Bell", "Closed", "Open", "Half-Open", "Splash", "Stomp"]

func _ready():
	zone_defaults = Utils.load_json_file(ZONE_DEFAULTS_PATH)
	VALID_PAD_TYPES = zone_defaults.keys()
	
	if not DirAccess.dir_exists_absolute(GEMS_PATH):
		GEMS_PATH = ORIGINAL_GEMS_PATH
		DEBUG_GEMS = false

func get_invalid_enabled_zones():
	var list = []
	for pad_and_zone in get_enabled_zones():
		var pad = pad_and_zone[0]
		var zone = pad_and_zone[1]
		var zone_name = pad_and_zone[2]
		var val = zone["Note"]
		if !(str(val).is_valid_float()) or val == -1:
			list.append(pad_and_zone)
	return list

func get_zone(type, pitch):
	for pad_and_zone in get_enabled_zones():
		var pad = pad_and_zone[0]
		var zone = pad_and_zone[1]
		var zone_name = pad_and_zone[2]
		if type == "noteon" and zone.get("Note") == pitch:
			return pad_and_zone
			
func get_enabled_zones():
	var list = []
	for pad in Global.drum_kit["Pads"]:
		var pad_type = pad["Type"]
		for key in pad.keys():
			if key in Global.valid_zone_keys:
				var zone_name = key
				var zone = pad[key]
				if !zone.has("Enabled") or zone["Enabled"]:
					var valid = true
					if pad_type == "hihat":
						if pad["ContinuousPedal"]:
							if zone_name == "Closed" or zone_name == "Open" or zone_name == "Half-Open":
								valid = false
						elif zone_name == "Bow" or zone_name == "Edge" or zone_name == "Bell":
							valid = false
					if valid:
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
	
	var original_gem_path = Global.ORIGINAL_GEMS_PATH + gem + "/"
	var dir = DirAccess.open(original_gem_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if "lighting" in file_name and file_name.ends_with(".png"):
				output += original_gem_path + file_name + "\n"
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

static func get_gem_config_setting(gem, header):
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
	
	return gem_data[index]

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
