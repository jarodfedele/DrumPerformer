extends Node2D

@onready var highway = get_parent().get_parent()

const LightingFrameScene = preload("res://scenes/lighting_frame.tscn")

var time : float
var gem : String
var gem_path : String
var original_gem_path : String
var color_r : int
var color_g : int
var color_b : int
var color_a = 255
var lane_start : int
var lane_end : int
var velocity : int
var positioning_shift_x : float
var positioning_shift_y : float
var positioning_scale : float
var blend_tint : int
var blend_lighting : int

var frames

var aspect_ratio : float

var lighting_frame_file_name = "lighting_frames.txt"

@onready var tint = $Tint
@onready var tint_colored = $TintColored
@onready var base = $Base
@onready var ring = $Ring
@onready var lighting = $Lighting

func set_texture(scene, list_index):
	var tex = Global.get_gem_texture(gem, list_index)
	if tex:
		scene.texture = tex

func set_sprite():
	set_texture(tint, 1)
	set_texture(tint_colored, 2)
	set_texture(base, 3)
	set_texture(ring, 4)

	if not base.texture:
		print("Missing base texture at:", gem_path + "base.png")

	aspect_ratio = base.texture.get_width()/base.texture.get_height()
	
	if tint_colored.texture and Global.setting_tint_colored:
		tint.visible = false
		tint_colored.visible = true
		tint_colored.material = tint_colored.material.duplicate()
		tint_colored.material.set_shader_parameter("tint_color", Color(color_r/255.0, color_g/255.0, color_b/255.0, color_a/255.0))
		tint_colored.material.set_shader_parameter("blending_mode", blend_tint)
	else:
		tint.visible = true
		tint_colored.visible = false
		tint.material = tint.material.duplicate()
		tint.material.set_shader_parameter("tint_color", Color(color_r/255.0, color_g/255.0, color_b/255.0, color_a/255.0))
		tint.material.set_shader_parameter("blending_mode", blend_tint)
	
	ring.modulate = Color8(color_r, color_g, color_b)
	
	frames = SpriteFrames.new()
	var text = Utils.read_text_file(original_gem_path + lighting_frame_file_name)
	var lines = text.split("\n")
	var current_section = null
	for file_path in lines:
		file_path = file_path.strip_edges()
		if ResourceLoader.exists(file_path):
			var tex = load(file_path)
			frames.add_frame("default", tex)
	lighting.frames = frames
	lighting.play("default")
	
	frames.set_animation_speed("default", Global.lighting_fps)
	
	lighting.modulate = Color(1, 1, 1, Global.lighting_alpha/255.0)
		
func update_position():
	var is_visible = (time >= highway.visible_time_min and time <= highway.visible_time_max)
	
	visible = is_visible
	set_process(is_visible)
	
	if is_visible:
		var lane_start_x1 = highway.get_lane_position(lane_start)[0]
		var lane_start_x2 = highway.get_lane_position(lane_start)[1]
		var lane_end_x1 = highway.get_lane_position(lane_end+1)[0]
		var lane_end_x2 = highway.get_lane_position(lane_end+1)[1]
		
		var note_yMax = highway.get_y_pos_from_time(time, false)

		var note_xMin = Utils.get_x_at_y(lane_start_x2, Global.CHART_YMIN, lane_start_x1, Global.CHART_YMAX, note_yMax)
		var note_xMax = Utils.get_x_at_y(lane_end_x2, Global.CHART_YMIN, lane_end_x1, Global.CHART_YMAX, note_yMax)
		
		var note_xSize = note_xMax - note_xMin

		var percentage_scalar = Utils.get_velocity_size_percentage(velocity)
		
		var scaled_note_xSize = note_xSize * percentage_scalar
		var xSize_diff = (scaled_note_xSize - note_xSize)/2
		note_xMin = note_xMin - xSize_diff
		note_xMax = note_xMax + xSize_diff

		var note_ySize = scaled_note_xSize/aspect_ratio
		var note_yMin = note_yMax - note_ySize
		
		var xLen = note_xMax - note_xMin
		note_xMin = note_xMin + xLen * positioning_shift_x
		note_xMax = note_xMax + xLen * positioning_shift_x

		var yLen = note_yMax - note_yMin
		note_yMin = note_yMin + yLen * positioning_shift_y
		note_yMax = note_yMax + yLen * positioning_shift_y
		
		if not is_zero_approx(positioning_scale):
			var x_increase = (note_xMax-note_xMin)*(positioning_scale-1)
			var y_increase = (note_yMax-note_yMin)*(positioning_scale-1)
			note_xMin = note_xMin - x_increase/2
			note_xMax = note_xMax + x_increase/2
			note_yMin = note_yMin - y_increase/2
			note_yMax = note_yMax + y_increase/2

		var desired_width = note_xMax - note_xMin
		var desired_height = note_yMax - note_yMin

		var tex_width = base.texture.get_width()
		var tex_height = base.texture.get_height()
		
		var note_xCenter = (note_xMin + note_xMax)/2
		var note_yCenter = (note_yMin + note_yMax)/2
		
		position = Vector2(note_xCenter, note_yCenter)
		scale = Vector2(desired_width / tex_width, desired_height / tex_height)
