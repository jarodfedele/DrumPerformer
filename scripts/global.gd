extends Node

const CHART_XMIN = 30
const CHART_YMIN = 0
const CHART_XSIZE = 700
const CHART_YSIZE = 600
const CHART_XMAX = CHART_XMIN + CHART_XSIZE 
const CHART_YMAX = CHART_YMIN + CHART_YSIZE
const CHART_YFADESTART = CHART_YMIN + CHART_YSIZE*0.2

const STAFF_SPACE_HEIGHT = 10

const NOTATION_XMIN = 100
const NOTATION_YMIN = CHART_YMAX + 6
const NOTATION_XSIZE = 1166
const NOTATION_YSIZE = STAFF_SPACE_HEIGHT * 24
const NOTATION_XMAX = NOTATION_XMIN + NOTATION_XSIZE
const NOTATION_YMAX = NOTATION_YMIN + NOTATION_YSIZE

const AUDIOBAR_XMIN = CHART_XMIN + CHART_XSIZE*0.7
const AUDIOBAR_YMIN = CHART_YMIN + 20
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
const ORIGINAL_GEMS_PATH = "res://assets/gems/"
var GEMS_PATH = ORIGINAL_GEMS_PATH
var DEBUG_GEMS = false
const NOTATIONS_PATH = "res://assets/notations/"
const DEBUG_NOTE_LIST_PATH = "res://note_list.txt"

var setting_tint_colored = true
var lighting_fps = 20
var lighting_alpha = 255
var debug_selected_gem = null
var debug_selected_test_note = null
var debug_update_notes = true
var hud_yPos = 0
const HUD_SLIDER_LENGTH = 200
const HUD_LABEL_XPOS = HUD_SLIDER_LENGTH + 10
const NOTATION_DRAW_AREA_XOFFSET = 64
const NOTATION_BOUNDARYXMINOFFSET = -12
const MEASURE_START_SPACING = 12
var center_staff_line
var notation_page_list
var notation_time_list

var gem_texture_list

func _ready():
	if not DirAccess.dir_exists_absolute(GEMS_PATH):
		GEMS_PATH = ORIGINAL_GEMS_PATH
		DEBUG_GEMS = false
		
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
	for child in node.get_children():
		if child is Node:
			child.set_process(is_enabled)
			child.set_physics_process(is_enabled)
			set_process_recursive(child, is_enabled)
