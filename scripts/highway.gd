class_name Highway extends Node2D

var num_lanes: int
var is_playable: bool
var x_min: int
var y_min: int
var x_size: int
var y_size: int
var x_max: int
var y_max: int
var y_fade_start: float
var y_strikeline: float
var beatline_data: Array
var hihat_pedal_data: Array
var sustain_data: Array
var note_data: Array

var lane_position_list: Array = []
var horizon_x: float = 0.0
var horizon_y: float = 0.0

var visible_time_min
var visible_time_max

var hit_time_min
var hit_time_max
var last_hit_note

var hit_count = 0
var miss_count = 0
var overhit_count = 0

var next_pad_gems
var next_pad_velocities

const BeatLineScene = preload("res://scenes/beatline.tscn")
const HiHatOverlayScene = preload("res://scenes/hihat_overlay.tscn")
const SustainOverlayScene = preload("res://scenes/sustain_overlay.tscn")
const NoteScene = preload("res://scenes/note.tscn")

@onready var song_audio_player = get_node("/root/Game/AudioManager/SongAudioPlayer")
@onready var song = get_parent()

@onready var contents_sub_viewport = $ContentsSubViewport
@onready var contents_display = $ContentsDisplay

@onready var notes = %Notes
@onready var beatlines = %BeatLines
@onready var hihat_pedal_overlays = %HiHatPedalOverlays
@onready var sustain_overlays = %SustainOverlays

@onready var hitbox = %Hitbox
@onready var strikeline = %Strikeline

@onready var background = %Background
@onready var lane_lines = %LaneLines
@onready var border = %Border

@onready var debug_labels = %DebugLabels
@onready var hit_count_label = %HitCountLabel
@onready var miss_count_label = %MissCountLabel
@onready var overhit_count_label = %OverhitCountLabel

var interpolated_texture_shader := preload("res://shaders//interpolated_texture.gdshader")

const HIGHWAY_SCENE: PackedScene = preload("res://scenes/highway.tscn")

const hihat_foot_tex = preload("res://assets//other//hihatfoot.png")
const tremolo_tex = preload("res://assets//other//tremolo.png")
const buzz_tex = preload("res://assets//other//buzz.png")

static func create(num_lanes: int, is_playable: bool, 
	x_min: int, y_min: int, x_size: int, y_size: int, 
	beatline_data, hihat_pedal_data, sustain_data, note_data):
		
	var instance: Highway = HIGHWAY_SCENE.instantiate()
	
	instance.num_lanes = num_lanes
	instance.is_playable = is_playable
	
	instance.x_min = x_min
	instance.y_min = y_min
	instance.x_size = x_size
	instance.y_size = y_size
	instance.x_max = instance.x_min + instance.x_size
	instance.y_max = instance.y_min + instance.y_size
	
	instance.beatline_data = beatline_data
	instance.hihat_pedal_data = hihat_pedal_data
	instance.sustain_data = sustain_data
	instance.note_data = note_data
	
	instance.y_fade_start = instance.y_min + instance.y_size*0.2
	instance.y_strikeline = instance.y_max - instance.y_size*0.2
	
	return instance

func _ready():
	refresh_boundaries()
	
	populate_beatlines()
	populate_hihat_pedal_overlays()
	populate_sustain_overlays()
	populate_notes()
	
	next_pad_gems = []
	next_pad_velocities = []
	var pad_list = Global.drum_kit["Pads"]
	for pad_index in range(pad_list.size()):
		next_pad_gems.append(-1)
		next_pad_velocities.append(-1)
		update_next_pad(pad_index, -1)
		
	hit_count_label.text = "Hits: 0"
	miss_count_label.text = "Misses: 0"
	overhit_count_label.text = "Overhits: 0"
	
	debug_labels.visible = is_playable
	
	MidiInputManager.pad_send.connect(_on_pad_received)
	
	contents_display.texture = contents_sub_viewport.get_texture()
		
func update_contents(current_time):
	visible_time_min = current_time
	visible_time_max = visible_time_min + Global.VISIBLE_TIMERANGE
	
	if is_playable:
		var hit_window_seconds = Global.HIGHWAY_HITWINDOW_MS * 0.001
		hit_time_min = current_time - hit_window_seconds
		hit_time_max = current_time + hit_window_seconds
		
		draw_hitbox()
		draw_strikeline()
	
	for beatline in beatlines.get_children():
		beatline.update_position()
	for note in notes.get_children():
		note.update_position()

func refresh_boundaries():
	reset_lane_position_list()

	draw_background()
	draw_lane_lines()
	draw_border()
	apply_note_fade_shader()

func apply_note_fade_shader():
	var viewport_size = get_viewport().get_visible_rect().size

	contents_display.material.set_shader_parameter("viewport_size", viewport_size)
	contents_display.material.set_shader_parameter("fade_start", y_fade_start)
	contents_display.material.set_shader_parameter("fade_end", y_min)
	
func overhit():
	overhit_count += 1
	overhit_count_label.text = "Overhits: " + str(overhit_count)
	
func add_beatline_to_highway(time, type):
	var beatline = Beatline.create(time, type, self)
	beatlines.add_child(beatline)
		
func populate_beatlines():
	for child in beatlines.get_children():
		child.queue_free()

	for data in beatline_data:
		var time = data[0]
		var type = data[1]
		add_beatline_to_highway(time, type)

func populate_hihat_pedal_overlays():
	for child in hihat_pedal_overlays.get_children():
		child.queue_free()

	for data in hihat_pedal_data:
		var hihat_overlay = HiHatOverlayScene.instantiate()
		
		var normalized_position = data[0]
		var lane_bounds = get_lane_bounds(normalized_position)
		var bottom_left_x = lane_bounds[0]
		var top_left_x = lane_bounds[1]
		var bottom_right_x = lane_bounds[2]
		var top_right_x = lane_bounds[3]
		
		var color_r = data[1]
		var color_g = data[2]
		var color_b = data[3]
		var cc_points = data[4]
		
		hihat_overlay.texture = hihat_foot_tex
		
		###############
		
		var mat = ShaderMaterial.new()
		mat.shader = interpolated_texture_shader
		hihat_overlay.material = mat
		hihat_overlay.material.set_shader_parameter("tint_color", Color(color_r/255.0, color_g/255.0, color_b/255.0))
		
		var quad_yMin = y_min
		var quad_yMax = y_max
		var quad_ySize = float(quad_yMax - quad_yMin)
		hihat_overlay.quad_yMin = quad_yMin
		hihat_overlay.quad_yMax = quad_yMax
		hihat_overlay.quad_ySize = quad_ySize
		
		var uv_left_bounds = []
		var uv_right_bounds = []
		
		var x_left_min = min(top_left_x, bottom_left_x)
		var x_left_max = max(top_left_x, bottom_left_x)
		var x_right_min = min(top_right_x, bottom_right_x)
		var x_right_max = max(top_right_x, bottom_right_x)
		var size_x = x_right_max - x_left_min
		var normalized_offset = x_left_min
		
		hihat_overlay.position = Vector2(x_left_min, quad_yMin)
		hihat_overlay.size = Vector2(size_x, quad_ySize)

		x_left_min = x_left_min - normalized_offset
		x_left_max = x_left_max - normalized_offset
		x_right_min = x_right_min - normalized_offset
		x_right_max = x_right_max - normalized_offset
		
		for row_index in range(quad_ySize):
			var uv_y = ((quad_ySize - 1) - row_index) / float(quad_ySize - 1)
			
			# Interpolate x positions in pixel space
			var xMin = lerp(top_left_x - normalized_offset, bottom_left_x - normalized_offset, uv_y)
			var xMax = lerp(top_right_x - normalized_offset, bottom_right_x - normalized_offset, uv_y)

			# Normalize to UV space (0–1)
			var uv_left = xMin / size_x
			var uv_right = xMax / size_x

			# Optional safety clamp
			uv_left = clamp(uv_left, 0.0, 1.0)
			uv_right = clamp(uv_right, 0.0, 1.0)

			uv_left_bounds.append(uv_left)
			uv_right_bounds.append(uv_right)
		
		hihat_overlay.material.set_shader_parameter("mode", 0)

		var uv_left_tex = Global.generate_alpha_texture(uv_left_bounds)
		hihat_overlay.material.set_shader_parameter("uv_left_bounds_map", uv_left_tex)
		hihat_overlay.material.set_shader_parameter("uv_left_bounds_map_height", uv_left_bounds.size())
		var uv_right_tex = Global.generate_alpha_texture(uv_right_bounds)
		hihat_overlay.material.set_shader_parameter("uv_right_bounds_map", uv_right_tex)
		hihat_overlay.material.set_shader_parameter("uv_right_bounds_map_height", uv_right_bounds.size())
		
		hihat_overlay.material.set_shader_parameter("top_left_x", top_left_x)
		hihat_overlay.material.set_shader_parameter("top_right_x", top_right_x)
		hihat_overlay.material.set_shader_parameter("bottom_right_x", bottom_right_x)
		hihat_overlay.material.set_shader_parameter("bottom_left_x", bottom_left_x)
		
		############
		
		var alpha_values := []
		var num_points = cc_points.size()
		
		for y in range(0, num_points):
			var point_data = cc_points[y]
			
			var time = point_data[0]
			var alpha = point_data[1]
			var next_time = 1000000.0 #TODO: endEvt?
			var next_alpha = alpha
			var is_gradient = false

			if y + 1 < num_points:
				var next_point_data = cc_points[y + 1]
				next_time = next_point_data[0]
				is_gradient = point_data[2]
				if is_gradient:
					next_alpha = next_point_data[1]

			alpha_values.append([time, alpha, next_time, next_alpha, is_gradient])

		hihat_overlay.points = alpha_values
		hihat_pedal_overlays.add_child(hihat_overlay)

func populate_sustain_overlays():
	for child in sustain_overlays.get_children():
		child.queue_free()

	for data in sustain_data:
		var sustain_overlay = SustainOverlayScene.instantiate()
		
		var normalized_position = data[0]
		var lane_bounds = get_lane_bounds(normalized_position)
		var bottom_left_x = lane_bounds[0]
		var top_left_x = lane_bounds[1]
		var bottom_right_x = lane_bounds[2]
		var top_right_x = lane_bounds[3]
		
		var color_r = data[1]
		var color_g = data[2]
		var color_b = data[3]
		var sustain_type = data[4]
		var cc_points = data[5]
		
		if sustain_type == "tremolo":
			sustain_overlay.texture = tremolo_tex
		if sustain_type == "buzz":
			sustain_overlay.texture = buzz_tex
		
		###############
		
		var mat = ShaderMaterial.new()
		mat.shader = interpolated_texture_shader
		sustain_overlay.material = mat
		sustain_overlay.material.set_shader_parameter("mode", 1)
		sustain_overlay.material.set_shader_parameter("tint_color", Color(color_r/255.0, color_g/255.0, color_b/255.0))
		
		var quad_yMin = y_min
		var quad_yMax = y_max
		var quad_ySize = float(quad_yMax - quad_yMin)
		sustain_overlay.quad_yMin = quad_yMin
		sustain_overlay.quad_yMax = quad_yMax
		sustain_overlay.quad_ySize = quad_ySize
		
		var uv_left_bounds = []
		var uv_right_bounds = []
		
		var x_left_min = min(top_left_x, bottom_left_x)
		var x_left_max = max(top_left_x, bottom_left_x)
		var x_right_min = min(top_right_x, bottom_right_x)
		var x_right_max = max(top_right_x, bottom_right_x)
		var size_x = x_right_max - x_left_min
		var normalized_offset = x_left_min
		
		sustain_overlay.position = Vector2(x_left_min, quad_yMin)
		sustain_overlay.size = Vector2(size_x, quad_ySize)

		x_left_min = x_left_min - normalized_offset
		x_left_max = x_left_max - normalized_offset
		x_right_min = x_right_min - normalized_offset
		x_right_max = x_right_max - normalized_offset
		
		for row_index in range(quad_ySize):
			var uv_y = ((quad_ySize - 1) - row_index) / float(quad_ySize - 1)
			
			# Interpolate x positions in pixel space
			var xMin = lerp(top_left_x - normalized_offset, bottom_left_x - normalized_offset, uv_y)
			var xMax = lerp(top_right_x - normalized_offset, bottom_right_x - normalized_offset, uv_y)

			# Normalize to UV space (0–1)
			var uv_left = xMin / size_x
			var uv_right = xMax / size_x

			# Optional safety clamp
			uv_left = clamp(uv_left, 0.0, 1.0)
			uv_right = clamp(uv_right, 0.0, 1.0)

			uv_left_bounds.append(uv_left)
			uv_right_bounds.append(uv_right)
		
		sustain_overlay.material.set_shader_parameter("mode", 1)

		var uv_left_tex = Global.generate_alpha_texture(uv_left_bounds)
		sustain_overlay.material.set_shader_parameter("uv_left_bounds_map", uv_left_tex)
		sustain_overlay.material.set_shader_parameter("uv_left_bounds_map_height", uv_left_bounds.size())
		var uv_right_tex = Global.generate_alpha_texture(uv_right_bounds)
		sustain_overlay.material.set_shader_parameter("uv_right_bounds_map", uv_right_tex)
		sustain_overlay.material.set_shader_parameter("uv_right_bounds_map_height", uv_right_bounds.size())
		
		sustain_overlay.material.set_shader_parameter("top_left_x", top_left_x)
		sustain_overlay.material.set_shader_parameter("top_right_x", top_right_x)
		sustain_overlay.material.set_shader_parameter("bottom_right_x", bottom_right_x)
		sustain_overlay.material.set_shader_parameter("bottom_left_x", bottom_left_x)
		
		############
		
		var percentage_values := []
		var num_points = cc_points.size()
		
		for y in range(0, num_points-1):
			var point_data = cc_points[y]
			
			var time = point_data[0]
			var percentage = point_data[1]
			var next_percentage = percentage

			var next_point_data = cc_points[y + 1]
			var next_time = next_point_data[0]
			var is_gradient = point_data[2]
			if is_gradient:
				next_percentage = next_point_data[1]
			
			percentage_values.append([time, percentage, next_time, next_percentage, is_gradient])
			
		sustain_overlay.points = percentage_values
		sustain_overlays.add_child(sustain_overlay)

func get_notes():
	var list = []
	for note in notes.get_children():
		list.append(note)
	list.reverse()
	return list
	
func update_next_pad(pad_index, recent_note_index):
	var note_list = get_notes()
	for i in range(recent_note_index+1, note_list.size()):
		var note = note_list[i]
		if note.pad_index == pad_index:
			next_pad_gems[pad_index] = note.gem
			next_pad_velocities[pad_index] = note.velocity
			#print("NEXT GEM: " + note.gem + " " + str(pad_index))
			return
	next_pad_gems[pad_index] = -1
	next_pad_velocities[pad_index] = -1
	print("NO NEW NEXT PAD: " + str(pad_index) + " " + str(recent_note_index))

func get_output_gem(desired_gem, zone_name):
	desired_gem = str(desired_gem)

	if "_" in desired_gem:
		desired_gem = desired_gem.split("_")[0]
	
	if zone_name == "sidestick":
		var gem = desired_gem + "_" + zone_name
		if Global.does_gem_exist(gem):
			return gem
		zone_name = "rim"
	
	if zone_name == "rim":
		var gem = desired_gem + "_" + zone_name
		if Global.does_gem_exist(gem):
			return gem
		zone_name = "head"
	
	if zone_name == "bell":
		var gem = desired_gem + "_" + zone_name
		if Global.does_gem_exist(gem):
			return gem
		zone_name = "bow"
		
	if zone_name == "head" or zone_name == "bow" or zone_name == "edge":
		var gem = desired_gem
		return gem
		
	if zone_name == "stomp" or zone_name == "splash":
		return desired_gem + "_pedal"
	
func _on_pad_received(pad_index, zone_name, pitch):
	try_to_hit_note(pad_index, zone_name, pitch)
	
func try_to_hit_note(pad_index, zone_name, pitch):
	if not is_playable:
		return
		
	#this is where we get the correct gem, based on next gem
	var next_gem = next_pad_gems[pad_index]
	var next_velocity = next_pad_velocities[pad_index]
	
	var output_gem = get_output_gem(next_gem, zone_name)
	if !Global.does_gem_exist(output_gem):
		print("GEM DOES NOT EXIST! " + output_gem)
	print("GEM TO HIT: " + output_gem + " " + zone_name)
	
	var note_list = get_notes()
	for note in note_list:
		#TODO: binary search
		if note.is_hittable() and note.pad_index == pad_index and note.gem == output_gem:
			var is_valid_pedal = true
			if note.pedal_val != -1:
				var pad = Global.drum_kit["Pads"][pad_index]
				var current_pedal_val
				if pad["PedalSendsMIDI"]:
					var ccNum = pad["PedalControlChange"]
					current_pedal_val = 127 - MidiInputManager.recent_cc_values[ccNum]
					if pad["PedalFlipPolarity"]:
						current_pedal_val = 127 - current_pedal_val
				else:
					var numbers = pad[zone_name]["Note"]
					var index = int(numbers.find(float(pitch)))
					current_pedal_val = round(lerp(0, 127, float(index) / float(numbers.size() - 1)))

				is_valid_pedal = (abs(note.pedal_val - current_pedal_val) <= 64)
				
			if is_valid_pedal:
				note.hit()
				return
			
	overhit()
			
func add_note_to_highway(time, gem, normalized_position, pad_index, velocity, pedal_val, midi_id, note_index):
	var positioning_shift_x = Global.get_gem_config_setting(gem, "shiftx", 0)
	var positioning_shift_y = Global.get_gem_config_setting(gem, "shifty", 0)
	var positioning_scale = Global.get_gem_config_setting(gem, "scale", 1)
	var blend_tint = Global.get_gem_config_setting(gem, "blend_tint", 0)
	var blend_lighting = Global.get_gem_config_setting(gem, "blend_lighting", 0)
	var z_order = Global.get_gem_config_setting(gem, "zorder", null)
	var color_r = Global.get_gem_config_setting(gem, "color_r", null)
	var color_g = Global.get_gem_config_setting(gem, "color_g", null)
	var color_b = Global.get_gem_config_setting(gem, "color_b", null)
	var color_a = Global.get_gem_config_setting(gem, "color_a", null)
	
	var note = Note.create(time, gem, normalized_position, velocity, pedal_val,
	color_r, color_g, color_b, color_a,
	midi_id, note_index, pad_index,
	positioning_shift_x, positioning_shift_y, positioning_scale, blend_tint, blend_lighting, z_order,
	self)
	
	notes.add_child(note)

func populate_notes():
	for child in notes.get_children():
		child.queue_free()
	
	# Create new notes
	note_data.sort_custom(func(a, b): return a[0] > b[0])

	for i in range(note_data.size()):
		var data = note_data[i]
		
		var time = data[0]
		var gem = data[1]
		var normalized_position = data[2]
		var pad_index = data[3]
		var velocity = data[4]
		var pedal_val = data[5]
		var midi_id = data[6]
		
		var note_index = note_data.size() - 1 - i
		add_note_to_highway(time, gem, normalized_position, pad_index, velocity, pedal_val, midi_id, note_index)
		
#for cover
func generate_uvs(points: PackedVector2Array) -> PackedVector2Array:
	var min_y = points[0].y
	var max_y = points[0].y
	for p in points:
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var height = max_y - min_y
	var uvs = PackedVector2Array()
	for p in points:
		var u = 0.5  # Optional: center of gradient
		var v = (p.y - min_y) / height if height != 0 else 0.0
		uvs.append(Vector2(u, v))
	return uvs

func draw_hitbox():
	var hit_window_seconds = Global.HIGHWAY_HITWINDOW_MS * 0.001
	var yMin = get_y_pos_from_time(hit_time_max)
	var yMax = get_y_pos_from_time(hit_time_min)
	
	var border_points = get_border_points()
	var bottom_left = border_points[0]
	var bottom_right = border_points[1]
	var top_right = border_points[2]
	var top_left = border_points[3]
	
	var xMin1 = Utils.get_x_at_y(bottom_left.x, bottom_left.y, top_left.x, top_left.y, yMax)
	var xMin2 = Utils.get_x_at_y(bottom_left.x, bottom_left.y, top_left.x, top_left.y, yMin)
	var xMax1 = Utils.get_x_at_y(bottom_right.x, bottom_right.y, top_right.x, top_right.y, yMax)
	var xMax2 = Utils.get_x_at_y(bottom_right.x, bottom_right.y, top_right.x, top_right.y, yMin)
	
	var points = [
		Vector2(xMin1, yMax),
		Vector2(xMin2, yMin),
		Vector2(xMax2, yMin),
		Vector2(xMax1, yMax)
	]

	hitbox.polygon = points
	
func draw_strikeline():
	var border_points = get_border_points()
	var bottom_left = border_points[0]
	var bottom_right = border_points[1]
	var top_right = border_points[2]
	var top_left = border_points[3]
	
	var xMin = Utils.get_x_at_y(bottom_left.x, bottom_left.y, top_left.x, top_left.y, y_strikeline)
	var xMax = Utils.get_x_at_y(bottom_right.x, bottom_right.y, top_right.x, top_right.y, y_strikeline)
	
	strikeline.points = [Vector2(xMin, y_strikeline), Vector2(xMax, y_strikeline)]
	
func draw_background():
	var border_points = get_border_points()
	background.polygon = border_points

func set_lane_lines_visibility(is_visible):
	lane_lines.visible = is_visible
	
func draw_lane_lines():
	for child in lane_lines.get_children():
		child.queue_free()
	
	for i in range(num_lanes-1):
		var lane = i + 1
		var bottom_left = Vector2(get_lane_position(lane)[0], y_max)
		var top_left = Vector2(get_lane_position(lane)[1], y_min)
	
		var line = Line2D.new()
		line.add_point(bottom_left)
		line.add_point(top_left)

		line.width = 4
		line.default_color = Color(0.15, 0.5, 0.15)

		lane_lines.add_child(line)
	
	lane_lines.visible = false
		
func draw_border():
	border.clear_points()
	
	var border_points = get_border_points()
	border.add_point(border_points[3])
	border.add_point(border_points[0])
	border.add_point(border_points[1])
	border.add_point(border_points[2])
	#border.add_point(border_points[3])
	
func get_lane_position(lane: int) -> Array:
	if lane >= 0 and lane < lane_position_list.size():
		var data = lane_position_list[lane]
		return [data[0], data[1]]
	return []

func get_border_points() -> Array:
	var top_left = Vector2(get_lane_position(0)[1], y_min)
	var top_right = Vector2(get_lane_position(num_lanes)[1], y_min)
	var bottom_right = Vector2(get_lane_position(num_lanes)[0], y_max)
	var bottom_left = Vector2(get_lane_position(0)[0], y_max)
	
	return [bottom_left, bottom_right, top_right, top_left]

func get_fade_points() -> Array:
	var border_points = get_border_points()
	
	var bottom_left = border_points[0]
	var bottom_right = border_points[1]
	var top_right = border_points[2]
	var top_left = border_points[3]
	
	var fade_left_x = Utils.get_x_at_y(bottom_left.x, bottom_left.y, top_left.x, top_left.y, y_fade_start)
	var fade_right_x = Utils.get_x_at_y(bottom_right.x, bottom_right.y, top_right.x, top_right.y, y_fade_start)

	bottom_right = Vector2(fade_right_x, y_fade_start)
	bottom_left = Vector2(fade_left_x, y_fade_start)
	
	return [bottom_left, bottom_right, top_right, top_left]

func get_lane_bound(percentage):
	var angle = Utils.convert_range(percentage, 0, 0.5, Global.MAX_ANGLE_DEGREES, 0)
	var x1 = x_min + x_size*percentage
	var x2 = Utils.rotate_line(x1, y_max, x1, y_min, angle)
	return [x1, x2]

func get_lane_bounds(percentage):
	var percentage_min
	var percentage_max
	if percentage == -1:
		percentage_min = 0.0
		percentage_max = 1.0
	else:
		percentage_min = percentage - (1/float(num_lanes)) * 0.5
		percentage_max = percentage + (1/float(num_lanes)) * 0.5
	var lane_bound_min = get_lane_bound(percentage_min)
	var lane_bound_max = get_lane_bound(percentage_max)
	return [lane_bound_min[0], lane_bound_min[1], lane_bound_max[0], lane_bound_max[1]]
	
func reset_lane_position_list():
	lane_position_list.clear()

	for lane in range(num_lanes + 1):
		var angle = Utils.convert_range(lane, 0, float(num_lanes) * 0.5, Global.MAX_ANGLE_DEGREES, 0)
		var x1 = x_min + x_size*(lane/float(num_lanes))
		var x2 = Utils.rotate_line(x1, y_max, x1, y_min, angle)
		lane_position_list.append([x1, x2])

	#get horizon
	var x1_first = get_lane_position(0)[0]
	var y2_first = y_min
	var x2_first = get_lane_position(0)[1]
	var y1_first = y_max
	
	var x1_last = get_lane_position(num_lanes)[0]
	var y2_last = y_min
	var x2_last = get_lane_position(num_lanes)[1]
	var y1_last = y_max
	
	var result = Utils.get_intersection(x1_first, y1_first, x2_first, y2_first, x1_last, y1_last, x2_last, y2_last)

	horizon_x = result.x
	horizon_y = result.y

func get_y_pos_from_time(time: float) -> float:
	var time_at_half_horizon = Global.TRACK_SPEED
	var time_at_strikeline = visible_time_min
	var future = time -  time_at_strikeline
	var halves = future / time_at_half_horizon
	return horizon_y + (y_strikeline - horizon_y) * pow(0.5, halves)
