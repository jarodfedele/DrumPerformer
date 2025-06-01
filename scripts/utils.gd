extends Node

static func convert_range(val, oldMin, oldMax, newMin, newMax):
	return ( (val - oldMin) / float(oldMax - oldMin) ) * (newMax - newMin) + newMin
	
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

static func binary_search_exact(sorted_table: Array, target: float, sub_table_index) -> int:
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

	return -1

static func load_json_file(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + path)
		return null
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var result = json.parse(json_text)
	
	if result != OK:
		push_error("JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return null
	
	return json.get_data()

static func convert_floats_to_ints(value):
	if typeof(value) == TYPE_FLOAT:
		if is_equal_approx(value, floor(value)):
			return int(value)
		return value
	elif typeof(value) == TYPE_ARRAY:
		var new_array := []
		for item in value:
			new_array.append(convert_floats_to_ints(item))
		return new_array
	elif typeof(value) == TYPE_DICTIONARY:
		var new_dict := {}
		for key in value.keys():
			new_dict[key] = convert_floats_to_ints(value[key])
		return new_dict
	else:
		return value
		
static func save_json_file(path: String, data: Variant) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + path)
		return
	
	var cleaned_data = convert_floats_to_ints(data)
	var json_string = JSON.stringify(cleaned_data, "\t")  # Pretty format
	file.store_string(json_string)
	file.close()

static func generate_guid() -> String:
	var hex = "0123456789abcdef"
	var guid = ""
	
	for i in range(36):
		match i:
			8, 13, 18, 23:
				guid += "-"
			14:
				guid += "4"  # UUID version 4
			19:
				var r = randi() % 16
				guid += ["8", "9", "a", "b"][r % 4]  # UUID variant
			_:
				guid += hex[randi() % 16]
	
	return guid

static func count_all_nodes(node: Node) -> int:
	var count = 1  # Count the current node
	for child in node.get_children():
		count += count_all_nodes(child)
	return count

func increment_value(val: int, ticks: int, min_val: int, max_val: int) -> int:
	var direction = ticks / abs(ticks)
	for i in range(abs(ticks)):
		val += direction
		if val > max_val:
			val = min_val
		elif val < min_val:
			val = max_val
	return val

func get_closest_index(x: float, values: Array) -> int:
	var closest_index = 0
	var min_dist = abs(x - values[0])
	for i in range(1, values.size()):
		var dist = abs(x - values[i])
		if dist < min_dist:
			closest_index = i
			min_dist = dist
	return closest_index
	
func get_closest_value(x: float, values: Array) -> float:
	return values[get_closest_index(x, values)]

func parse_numbers(input: String) -> Array:
	var result = []
	var regex = RegEx.new()
	regex.compile(r"\d+")
	for match in regex.search_all(input):
		result.append(int(match.get_string()))
	return result

func get_duplicates(arr: Array) -> Array:
	var seen = {}
	var duplicates = []
	for value in arr:
		if seen.has(value):
			if not duplicates.has(value):
				duplicates.append(value)
		else:
			seen[value] = true
	return duplicates

func load_text_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	return text

static func set_sprite_position_and_scale(sprite: Sprite2D, xMin, yMin, xMax, yMax):
	var desired_width = xMax - xMin
	var desired_height = yMax - yMin

	var tex_width = float(sprite.texture.get_width())
	var tex_height = float(sprite.texture.get_height())
	
	if sprite.centered:
		sprite.position = Vector2((xMax-xMin)*0.5, (yMax-yMin)*0.5)
	else:
		sprite.position = Vector2(xMin, yMin)
		
	sprite.scale = Vector2(desired_width/tex_width, desired_height/tex_height)

func make_rect(xMin, yMin, xMax, yMax) -> Rect2:
	return Rect2(Vector2(xMin, yMin), Vector2(xMax - xMin, yMax - yMin))
