extends Node

static func convert_range(val, oldMin, oldMax, newMin, newMax):
	return ( (val - oldMin) / (oldMax - oldMin) ) * (newMax - newMin) + newMin
	
static func get_vertical_line_slope(angle):
	var radians = deg_to_rad(angle)
	var slope = 1.0 / tan(radians)
	return slope

static func get_x_at_y(x1, y1, x2, y2, y):
	if x1 == x2:
		return x1  # Vertical line, x is constant
	
	var m = (y2 - y1) / (x2 - x1)
	var x = ((y - y1) / m) + x1
	return x

static func get_intersection(x1_a, y1_a, x2_a, y2_a, x1_b, y1_b, x2_b, y2_b):
	var m1 = (y2_a - y1_a) / (x2_a - x1_a)
	var m2 = (y2_b - y1_b) / (x2_b - x1_b)

	if m1 == m2:
		return null  # Parallel lines

	var x = ((m1 * x1_a - y1_a) - (m2 * x1_b - y1_b)) / (m1 - m2)
	var y = m1 * (x - x1_a) + y1_a

	return Vector2(x, y)

static func rotate_line(x1: float, y1: float, x2: float, y2: float, angle: float) -> float:
	# Invert angle direction if needed
	angle *= -1

	# Convert angle to radians
	var radians = deg_to_rad(angle)

	# Calculate the horizontal displacement (Δx)
	var delta_x = (y2 - y1) * tan(radians)

	# Compute new x2 after rotation
	var new_x2 = x1 + delta_x

	return new_x2

static func read_text_file(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var contents = file.get_as_text()
		file.close()
		return contents
	else:
		push_error("Failed to open file: " + path)
		return ""

static func separate_string(str: String) -> Array:
	var list: Array = []

	while true:
		if str.is_empty():
			break

		var quotes := str[0] == '"'
		var i: int

		if quotes:
			i = str.find('" ', 1)
			if i != -1:
				i += 1
		else:
			i = str.find(" ")

		var value  # no type hint to allow string or float

		if i == -1:
			value = str
		else:
			value = str.substr(0, i)
		
		value = value.strip_edges()
		
		if quotes:
			value = value.substr(1, value.length() - 2)
		elif value.is_valid_float():
			value = float(value)

		list.append(value)

		if i == -1:
			break

		str = str.substr(i + 1, str.length())

	return list
	
static func color_to_rgb(color: int) -> Array:
	var r = (color >> 16) & 0xFF
	var g = (color >> 8) & 0xFF
	var b = color & 0xFF
	return [r, g, b]

static func get_velocity_size_percentage(velocity: float) -> float:
	return convert_range(velocity, 0, 127, Global.MIN_VELOCITY_SIZE_PERCENTAGE, 1)

static func get_sustain_size_percentage(cc_val: float) -> float:
	return convert_range(get_velocity_size_percentage(cc_val), Global.MIN_VELOCITY_SIZE_PERCENTAGE, 1, Global.MIN_VELOCITY_SIZE_PERCENTAGE*0.5, 1)

static func seconds_to_min_sec_string(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [mins, secs]

static func binary_search_closest_or_less(sorted_table: Array, target: float, sub_table_index) -> int:
	var low := 0
	var high := sorted_table.size() - 1
	var result := -1

	while low <= high:
		var mid := (low + high) / 2
		var mid_value

		if sub_table_index != -1:
			mid_value = sorted_table[mid][sub_table_index]
		else:
			mid_value = sorted_table[mid]
		
		if mid_value == target:
			return mid
		elif mid_value < target:
			result = mid
			low = mid + 1
		else:
			high = mid - 1

	return result

static func set_sprite_position(sprite, xMin, yMin, xMax, yMax):
	var desired_width = xMax - xMin
	var desired_height = yMax - yMin

	var tex_width = sprite.texture.get_width()
	var tex_height = sprite.texture.get_height()
	
	var xCenter = (xMin + xMax)/2
	var yCenter = (yMin + yMax)/2
	
	sprite.position = Vector2(xCenter, yCenter)
	sprite.scale = Vector2(desired_width / tex_width, desired_height / tex_height)
