class_name Note extends Node2D

const LightingFrameScene = preload("res://scenes/lighting_frame.tscn")

var time : float
var gem : String
var normalized_position : float
var velocity : int
var pedal_val : int
var color_r : float
var color_g : float
var color_b : float
var color_a : float
var midi_id : int
var note_index : int
var pad_index : int
var positioning_shift_x : float
var positioning_shift_y : float
var positioning_scale : float
var blend_tint : int
var blend_lighting : int
var highway

var gem_path : String
var grayscale : bool = false
var linked_notations : Array

var hit_state

var frames

var aspect_ratio : float

const lighting_frame_file_name = "lighting_frames.txt"

@onready var notes = get_parent()
@onready var tint = $Tint
@onready var tint_colored = $TintColored
@onready var base = $Base
@onready var ring = $Ring
@onready var lighting = $Lighting

const NOTE_SCENE: PackedScene = preload("res://scenes/note.tscn")

static func create(time: float, gem: String, normalized_position: float, velocity: int, pedal_val: int,
	color_r: float, color_g: float, color_b: float, color_a: float,
	midi_id: int, note_index: int, pad_index: int,
	positioning_shift_x: float, positioning_shift_y: float, positioning_scale: float, blend_tint: int, blend_lighting: int,
	z_order,
	highway):
		
	var instance: Note = NOTE_SCENE.instantiate()
	
	instance.time = time
	instance.gem = gem
	instance.normalized_position = normalized_position
	instance.velocity = velocity
	instance.pedal_val = pedal_val
	
	instance.color_r = color_r
	instance.color_g = color_g
	instance.color_b = color_b
	instance.color_a = color_a
	
	instance.midi_id = midi_id
	instance.note_index = note_index
	instance.pad_index = pad_index
	
	instance.positioning_shift_x = positioning_shift_x
	instance.positioning_shift_y = positioning_shift_y
	instance.positioning_scale = positioning_scale
	instance.blend_tint = blend_tint
	instance.blend_lighting = blend_lighting
	
	instance.z_index = z_order
	
	instance.highway = highway
	
	instance.gem_path = Global.GEMS_PATH + instance.gem + "/"
	instance.linked_notations = []
	
	return instance

func _ready():
	set_sprite()
			
func set_texture(scene, list_index):
	var tex = Global.get_gem_texture(gem, list_index)
	if tex:
		scene.texture = tex

func get_texture_size():
	return base.texture.get_size()

func set_grayscale(is_grayscale):
	if grayscale != is_grayscale:
		grayscale = is_grayscale
		set_sprite()

func to_grayscale(color: Color) -> Color:
	var luminance = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
	return Color(luminance, luminance, luminance, color.a)
			
func set_sprite():
	set_texture(tint, 1)
	set_texture(tint_colored, 2)
	set_texture(base, 3)
	set_texture(ring, 4)

	if not base.texture:
		print("Missing base texture at:", gem_path + "base.png")

	aspect_ratio = base.texture.get_width()/base.texture.get_height()
	
	var fade_factor
	
	var tint_color = Color(color_r, color_g, color_b, color_a)
	if grayscale:
		tint_color = to_grayscale(tint_color)
	
	if tint_colored.texture and Global.setting_tint_colored:
		tint.visible = false
		tint_colored.visible = true
		tint_colored.material = tint_colored.material.duplicate()
		tint_colored.material.set_shader_parameter("tint_color", tint_color)
		tint_colored.material.set_shader_parameter("blending_mode", blend_tint)
	else:
		tint.visible = true
		tint_colored.visible = false
		tint.material = tint.material.duplicate()
		tint.material.set_shader_parameter("tint_color", tint_color)
		tint.material.set_shader_parameter("blending_mode", blend_tint)
	
	var ring_color = Color(color_r, color_g, color_b)
	if grayscale:
		ring_color = to_grayscale(ring_color)
	ring.modulate = ring_color

	frames = SpriteFrames.new()
	var text = Utils.read_text_file(gem_path + lighting_frame_file_name)
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
	
	lighting.visible = !grayscale

func get_collision_bounds():
	var note_size = get_texture_size() * scale
	note_size.x *= 0.7
	note_size.y *= 0.9
	var xMin = position.x-note_size.x*0.5
	var yMin = position.y-note_size.y*0.5
	var xMax = position.x+note_size.x*0.5
	var yMax = position.y+note_size.y*0.5
	return [xMin, yMin, xMax, yMax]
	
func hit():
	hit_state = true
	highway.last_hit_note = self
	
	var note_tween = get_tree().create_tween()
	note_tween.tween_property(self, "scale", Vector2(0.0, 0.0), 0.1)
	note_tween.tween_callback(Callable(self, "_on_tween_complete"))
	
	for notation in linked_notations:
		var notation_tween = get_tree().create_tween()
		var notation_sprite = notation.get_children()[0]
		notation_tween.tween_property(notation_sprite, "scale", Vector2(0.0, 0.0), 0.1)
	
	highway.hit_count += 1
	highway.hit_count_label.text = "Hits: " + str(highway.hit_count)
	
	highway.update_next_pad(pad_index, note_index)

func _on_tween_complete():
	visible = false
	set_process(false)
		
func miss():
	hit_state = false
	
	highway.miss_count += 1
	highway.miss_count_label.text = "Misses: " + str(highway.miss_count)
	
	highway.update_next_pad(pad_index, note_index)
	
	set_grayscale(true) #causes lag when scrolling
	
func is_hittable():
	if hit_state != null:
		return false
		
	var past_min_time
	if highway.last_hit_note:
		past_min_time = time >= highway.last_hit_note.time
	else:
		past_min_time = true
	return (past_min_time and time >= highway.hit_time_min and time <= highway.hit_time_max)
	
func update_position():
	if hit_state == true:
		return
	
	if highway.is_playable and hit_state != false and highway.hit_time_min > time:
		miss()
		
	var is_visible = (time >= highway.visible_time_min - 0.4 and time <= highway.visible_time_max)
	
	visible = is_visible
	set_process(is_visible)
	
	if !is_visible:
		return
		
	var lane_bounds = highway.get_lane_bounds(normalized_position)
	var lane_start_x1 = lane_bounds[0]
	var lane_start_x2 = lane_bounds[1]
	var lane_end_x1 = lane_bounds[2]
	var lane_end_x2 = lane_bounds[3]
		
	var note_yMax = highway.get_y_pos_from_time(time)

	var note_xMin = Utils.get_x_at_y(lane_start_x2, highway.y_min, lane_start_x1, highway.y_max, note_yMax)
	var note_xMax = Utils.get_x_at_y(lane_end_x2, highway.y_min, lane_end_x1, highway.y_max, note_yMax)
	
	var note_xSize = note_xMax - note_xMin

	var percentage_scalar
	if normalized_position == -1:
		percentage_scalar = Utils.get_velocity_size_percentage(100)
	else:
		percentage_scalar = Utils.get_velocity_size_percentage(velocity)
	
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
