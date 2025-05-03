extends Node2D

@onready var highway = get_parent()
@onready var shader := preload("res://shaders//interpolated_texture.gdshader")

const SustainOverlayScene = preload("res://scenes/sustain_overlay.tscn")

const Utils = preload("res://scripts/utils.gd")
const tremolo = preload("res://assets//other//tremolo.png")
const buzz = preload("res://assets//other//buzz.png")

func _ready():
	spawn_sustain_overlay()
	
func spawn_sustain_overlay():
	# Clean up old notes
	for child in get_children():
		child.queue_free()

	# Create new notes
	for data in highway.sustain_data:
		var sustain_overlay = SustainOverlayScene.instantiate()
		
		var bottom_left_x = data[0]
		var top_left_x = data[1]
		var bottom_right_x = data[2]
		var top_right_x = data[3]
		var color_r = data[4]
		var color_g = data[5]
		var color_b = data[6]
		var sustain_type = data[7]
		var cc_points = data[8]
		
		if sustain_type == "tremolo":
			sustain_overlay.texture = tremolo
		if sustain_type == "buzz":
			sustain_overlay.texture = buzz
		
		###############
		
		var mat = ShaderMaterial.new()
		mat.shader = shader
		sustain_overlay.material = mat
		sustain_overlay.material.set_shader_parameter("mode", 1)
		sustain_overlay.material.set_shader_parameter("tint_color", Color(color_r/255.0, color_g/255.0, color_b/255.0))
		
		var quad_yMin = Global.CHART_YMIN
		var quad_yMax = Global.CHART_YMAX
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
		add_child(sustain_overlay)
