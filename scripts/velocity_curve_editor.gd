extends TextureRect

signal curve_type_changed()
signal curve_strength_changed()

var pad
var zone_name

var dragging := false
var drag_offset := Vector2.ZERO
var original_position
var curve_type
var curve_strength
var original_curve_strength

const NUM_PIXELS = 50

func _ready():
	custom_minimum_size = Vector2(NUM_PIXELS, NUM_PIXELS)
	queue_redraw()
	
func _draw():
	var last_point = Vector2.ZERO
	for i in range(NUM_PIXELS + 1):
		var t = i / float(NUM_PIXELS)  # normalized x from 0 to 1
		var y = evaluate_curve(t)
		
		var x_pos = t * size.x
		var y_pos = (1.0 - y) * size.y  # flip y because screen y increases downward
		
		var point = Vector2(x_pos, y_pos)
		if i > 0:
			draw_line(last_point, point, Color(1, 0, 0), 2.0)
		last_point = point

func set_and_send_curve_strength(val: float):
	curve_strength = clamp(val, -1.0, 1.0)
	emit_signal("curve_strength_changed", self)
	queue_redraw()
	
func evaluate_curve(x: float) -> float:
	match float(curve_type):
		0.0:
			var exponent = pow(4, curve_strength)
			return pow(x, exponent)
		1.0:
			x = Utils.convert_range(x, 0, 1, -1, 1)
			var b = 0.4
			var a = Utils.convert_range(curve_strength, -1.0, 1.0, 0.0, 4.0)
			
			var w = pow(2.0, a)
			var numerator = sign(x) * pow(abs(x), w) - log(b) / log(2) * x
			var denominator = 1.0 - log(b) / log(2)
			return numerator / denominator * 0.5 + 0.5
		_:
			return x  # fallback to linear
						
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				set_and_send_curve_strength(0)
			else:
				dragging = event.pressed
				original_position = get_global_mouse_position()
				original_curve_strength = curve_strength
				drag_offset = Vector2.ZERO
				var cursor_shape
				if dragging:
					cursor_shape = Input.CURSOR_HSIZE
				else:
					cursor_shape = Input.CURSOR_ARROW
				mouse_default_cursor_shape = cursor_shape
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			curve_type = Utils.increment_value(curve_type, 1, 0, Global.NUM_VELOCITY_CURVE_TYPES-1)
			emit_signal("curve_type_changed", self)
			
	elif event is InputEventMouseMotion and dragging:
		drag_offset = get_global_mouse_position() - original_position
		curve_strength = original_curve_strength + Utils.convert_range(drag_offset.x, 0, 50, 0, 1)
		set_and_send_curve_strength(curve_strength)
