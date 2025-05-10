extends Node2D

@onready var drum_kit_vbox_container = $ScrollContainer/PanelContainer/VBoxContainer/DrumKitPanelContainer/DrumKitVBoxContainer
@onready var midi_device_vbox_container = $MIDIDevicePanelContainer/MIDIDeviceVBoxContainer

@onready var highway = $Highway

@onready var arrow_up_button = $LaneCountContainer/ArrowUpButton
@onready var lane_count_label = $LaneCountContainer/LaneCountLabel
@onready var arrow_down_button = $LaneCountContainer/ArrowDownButton

const DrumPadInstanceScene = preload("res://scenes/drum_pad_instance.tscn")
const PadPropertiesScene = preload("res://scenes/pad_properties.tscn")

const MIDIDeviceInstanceScene = preload("res://scenes/midi_device_instance.tscn")
const MIDIDeviceNameScene = preload("res://scenes/midi_device_name.tscn")
const MIDIChannelButtonScene = preload("res://scenes/midi_channel_button.tscn")
const OptionButtonScene = preload("res://scenes/option_button.tscn")
const MIDINumberTextFieldScene = preload("res://scenes/midi_number_text_field.tscn")
const PropertyCheckBoxScene = preload("res://scenes/property_check_box.tscn")
const VelocityCurveEditorScene = preload("res://scenes/velocity_curve_editor.tscn")

const AddButtonScene = preload("res://scenes/add_button.tscn")
const RemoveButtonScene = preload("res://scenes/remove_button.tscn")

const SELECT_PAD_TYPE_TEXT = "Select pad type..."
const SELECT_MIDI_INPUT_TEXT = "Select MIDI input..."

var clicked_note
var dragging
var original_mouse_position

var snap_enabled = false

var refresh = false

func _process(_delta):
	if refresh:
		update_contents()
			
func update_contents():
	refresh = false
	
	for child in drum_kit_vbox_container.get_children():
		child.queue_free()
	for child in midi_device_vbox_container.get_children():
		child.queue_free()
		
	add_drum_kit_editor_widget()
	
	if Global.drum_kit.has("Input") and Global.drum_kit.has("Channels"):
		add_midi_devices_widget()
	else:
		add_new_midi_device()
	
	draw_notes_on_highway()

func draw_notes_on_highway():
	var num_lanes
	if Global.drum_kit.has("Lanes"):
		num_lanes = Global.drum_kit["Lanes"]
	else:
		num_lanes = 6
		Global.drum_kit["Lanes"] = num_lanes
		Utils.save_json_file(Global.drum_kit_path, Global.drum_kit)
	num_lanes = float(num_lanes)
	lane_count_label.text = str(int(num_lanes))
	arrow_up_button.visible = num_lanes < 10
	arrow_down_button.visible = num_lanes > 4
	
	var pad_default_position_map = {
		"snare": { "lane": 0, "row": 0 },
		"racktom": { "lane": 1, "row": 0 },
		"floortom": { "lane": num_lanes-1, "row": 0 },
		"hihat": { "lane": 0, "row": 1 },
		"ride": { "lane": num_lanes-1, "row": 1 },
		"crash": { "lane": 2, "row": 1 }
		}

	const NUM_ROWS = 4
	var row_times = []
	for row in range(NUM_ROWS):
		var row_time = row*0.4 + 0.1
		row_times.append(row_time)
	
	var beatline_data = []
	var color_r = 120
	var color_g = 120
	var color_b = 120
	var thickness = 4
	for row in range (row_times.size()):
		beatline_data.append([row_times[row], color_r, color_g, color_b, thickness])
	highway.populate_beat_lines(beatline_data)
	
	var note_data = []
	const DEFAULT_VELOCITY = 100
	
	var pad_list = Global.drum_kit["Pads"]
	for pad_index in range(pad_list.size()):
		var pad = pad_list[pad_index]
		var pad_type = pad["Type"]
		var pad_position
		var pad_layer
		if pad.has("Position") and pad.has("Layer"):
			pad_position = pad["Position"]
			pad_layer = pad["Layer"]
		elif pad_default_position_map.has(pad_type):
			var lane = pad_default_position_map[pad_type]["lane"]
			var center_x = (highway.get_lane_position(lane)[0] + highway.get_lane_position(lane+1)[0]) * 0.5
			pad_position = Utils.convert_range(center_x, Global.HIGHWAY_XMIN, Global.HIGHWAY_XMAX, 0.0, 1.0)
			pad_layer = pad_default_position_map[pad_type]["row"]
			pad["Position"] = pad_position
			pad["Layer"] = pad_layer
			Utils.save_json_file(Global.drum_kit_path, Global.drum_kit)
		if pad_position != null and pad_layer != null:
			note_data.append([row_times[pad_layer], pad_type, pad_position, pad_layer, pad_index, DEFAULT_VELOCITY])
	
	highway.set_lane_lines_visibility(snap_enabled)
	
	highway.populate_notes(note_data)

	highway.update_contents(0)
	
	await get_tree().process_frame
	for child in get_children():
		if child is ColorRect:
			child.queue_free()
		
	clicked_note = null
	for note in highway.get_notes():
		var rect = ColorRect.new()
		rect.color = Color(1, 1, 1, 0.5)
		set_collision_rect_position(rect, note)
		add_child(rect)
		
		# Connect the built-in "gui_input" signal dynamically
		rect.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				dragging = event.pressed
				original_mouse_position = get_global_mouse_position()
				set_clicked_note(note)
			elif event is InputEventMouseMotion:
				if dragging and clicked_note:
					var mouse_x = get_global_mouse_position().x
					var mouse_y = get_global_mouse_position().y
					
					var bottom_left = highway.get_lane_position(0)[0]
					var bottom_right = highway.get_lane_position(num_lanes)[0]
					var top_right = highway.get_lane_position(num_lanes)[1]
					var top_left = highway.get_lane_position(0)[1]
	
					var xMin = Utils.get_x_at_y(bottom_left, Global.HIGHWAY_YMAX, top_left, Global.HIGHWAY_YMIN, mouse_y)
					var xMax = Utils.get_x_at_y(bottom_right, Global.HIGHWAY_YMAX, top_right, Global.HIGHWAY_YMIN, mouse_y)
					var pad_position = Utils.convert_range(mouse_x, xMin, xMax, 0.0, 1.0)
					
					if snap_enabled:
						var snapped_position_values = []
						for lane in range(num_lanes):
							snapped_position_values.append(lane/num_lanes + 1/(num_lanes*2))
						pad_position = Utils.get_closest_value(pad_position, snapped_position_values)
					pad_position = clamp(pad_position, 0.0, 1.0)
					clicked_note.normalized_position = pad_position
					
					var snapped_layer_values = []
					for row_time in row_times:
						snapped_layer_values.append(highway.get_y_pos_from_time(row_time, false))
					var pad_layer = Utils.get_closest_index(mouse_y, snapped_layer_values)
					clicked_note.layer = pad_layer
					clicked_note.time = row_times[pad_layer]
					
					clicked_note.update_position()
					set_collision_rect_position(rect, clicked_note)
					
					var pad = pad_list[note.pad_index]
					pad["Position"] = pad_position
					pad["Layer"] = pad_layer
					Utils.save_json_file(Global.drum_kit_path, Global.drum_kit)
			)

func set_clicked_note(note):
	for test_note in highway.get_notes():
		test_note.set_grayscale(test_note != note and note != null)
	clicked_note = note
	
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		set_clicked_note(null)

func set_collision_rect_position(rect, note):
	var collision_bounds = note.get_collision_bounds()
	var note_xMin = collision_bounds[0]
	var note_yMin = collision_bounds[1]
	var note_xMax = collision_bounds[2]
	var note_yMax = collision_bounds[3]
	rect.position = Vector2(note_xMin, note_yMin)
	rect.size = Vector2(note_xMax-note_xMin, note_yMax-note_yMin)

func add_drum_kit_editor_widget():
	var pad_list = Global.drum_kit["Pads"]
	for pad_index in range(pad_list.size()):
		var pad = pad_list[pad_index]
		var pad_type = pad["Type"]
		var pad_instance = DrumPadInstanceScene.instantiate()
		
		var pad_properties = PadPropertiesScene.instantiate()
		add_pad_name_text_field(pad_properties, pad, pad_index)
		add_pad_type_selector(pad_properties, pad, pad_index)
		remove_button(pad_properties, pad)
		
		if pad_type == "kick":
			if property_check_box(pad_properties, pad, "", "DoublePedal"):
				property_check_box(pad_properties, pad, "", "HeelToe")
		if pad_type == "snare":
			positional_sensing_widget(pad_properties, pad, "")
		if pad_type == "racktom":
			positional_sensing_widget(pad_properties, pad, "")
		if pad_type == "floortom":
			positional_sensing_widget(pad_properties, pad, "")
		if pad_type == "hihat":
			positional_sensing_widget(pad_properties, pad, "")
			if property_check_box(pad_properties, pad, "", "ContinuousPedal"):
				hi_hat_pedal_cc_text_field(pad_properties, pad, "")
		if pad_type == "ride":
			positional_sensing_widget(pad_properties, pad, "")
		if pad_type == "crash":
			positional_sensing_widget(pad_properties, pad, "")
									
		pad_instance.add_child(pad_properties)
		
		var zones_vbox_container = VBoxContainer.new()
		pad_instance.add_child(zones_vbox_container)
		
		var container
		if pad_type == "kick":
			container = add_persistent_zone_data(zones_vbox_container, pad, "Head", true)
		if pad_type == "snare":
			container = add_persistent_zone_data(zones_vbox_container, pad, "Head", true)
			container = add_persistent_zone_data(zones_vbox_container, pad, "Side Stick", false)
			container = add_persistent_zone_data(zones_vbox_container, pad, "Rim", false)
		if pad_type == "racktom":
			container = add_persistent_zone_data(zones_vbox_container, pad, "Head", true)
			container = add_persistent_zone_data(zones_vbox_container, pad, "Rim", false)
		if pad_type == "floortom":
			container = add_persistent_zone_data(zones_vbox_container, pad, "Head", true)
			container = add_persistent_zone_data(zones_vbox_container, pad, "Rim", false)
		if pad_type == "hihat":
			if get_pad_property(pad, "", "ContinuousPedal"):
				container = add_persistent_zone_data(zones_vbox_container, pad, "Bow", true)
				container = add_persistent_zone_data(zones_vbox_container, pad, "Edge", false)
				container = add_persistent_zone_data(zones_vbox_container, pad, "Bell", false)
			else:
				container = add_persistent_zone_data(zones_vbox_container, pad, "Closed", true)
				container = add_persistent_zone_data(zones_vbox_container, pad, "Open", true)
				container = add_persistent_zone_data(zones_vbox_container, pad, "Half-Open", false)
			container = add_persistent_zone_data(zones_vbox_container, pad, "Stomp", true)
			container = add_persistent_zone_data(zones_vbox_container, pad, "Splash", false)
		if pad_type == "ride":
			container = add_persistent_zone_data(zones_vbox_container, pad, "Bow", true)
			container = add_persistent_zone_data(zones_vbox_container, pad, "Edge", false)
			container = add_persistent_zone_data(zones_vbox_container, pad, "Bell", false)
		if pad_type == "crash":
			container = add_persistent_zone_data(zones_vbox_container, pad, "Bow", true)
			container = add_persistent_zone_data(zones_vbox_container, pad, "Edge", false)
			container = add_persistent_zone_data(zones_vbox_container, pad, "Bell", false)
												
		drum_kit_vbox_container.add_child(pad_instance)
	
	var add_button = AddButtonScene.instantiate()
	add_button.connect("pressed", Callable(self, "_on_add_button_clicked").bind(add_button))
	drum_kit_vbox_container.add_child(add_button)

func _on_add_button_clicked(sender):
	add_new_pad()
	
func add_midi_devices_widget():
	var midi_device_instance = MIDIDeviceInstanceScene.instantiate()
	
	add_midi_input_selector(midi_device_instance)

	for channel in range(16):
		add_midi_channel_button(midi_device_instance, channel)

	midi_device_vbox_container.add_child(midi_device_instance)

func add_persistent_zone_data(parent_container, pad, zone_name, always_enabled):
	var zone_hbox_container = HBoxContainer.new()
	parent_container.add_child(zone_hbox_container)
	if zone_check_box(zone_hbox_container, pad, zone_name, always_enabled):
		midi_number_text_field(zone_hbox_container, pad, zone_name)
		velocity_curve_widget(zone_hbox_container, pad, zone_name)
	return zone_hbox_container
	
func get_pad_property(pad, zone_name, property):
	var val
	var pad_type = pad["Type"]
	if zone_name == "":
		if property in pad:
			val = pad[property]
		else:
			val = Global.zone_defaults[pad_type][property]
			set_pad_property(pad, zone_name, property, val, true)
	else:
		if not pad.has(zone_name):
			pad[zone_name] = {}
			
		if property in pad[zone_name]:
			val = pad[zone_name][property]
		else:
			val = Global.zone_defaults[pad_type][zone_name][property]
			set_pad_property(pad, zone_name, property, val, true)
			
	return val

func set_pad_property(pad, zone_name, property, val, to_update_contents):
	if zone_name == "":
		pad[property] = val
	else:
		pad[zone_name][property] = val
		
	Utils.save_json_file(Global.drum_kit_path, Global.drum_kit)
	if to_update_contents:
		refresh = true
				
func get_unused_connected_inputs(inputs):
	var list = []
	var connected_inputs = OS.get_connected_midi_inputs()
	for input in connected_inputs:
		if input not in inputs:
			list.append(input)
			
	return list

func positional_sensing_widget(pad_properties, pad, zone_name):
	if property_check_box(pad_properties, pad, zone_name, "PositionalSensingEnabled"):
		positional_sensing_cc_text_field(pad_properties, pad, zone_name)
				
func velocity_curve_widget(node, pad, zone_name):
	var velocity_curve_editor = VelocityCurveEditorScene.instantiate()
	
	velocity_curve_editor.pad = pad
	velocity_curve_editor.zone_name = zone_name
	velocity_curve_editor.curve_type = get_pad_property(pad, zone_name, "CurveType")
	velocity_curve_editor.curve_strength = get_pad_property(pad, zone_name, "CurveStrength")
	
	velocity_curve_editor.curve_type_changed.connect(_on_curve_type_changed)
	velocity_curve_editor.curve_strength_changed.connect(_on_curve_strength_changed)
	
	node.add_child(velocity_curve_editor)

func _on_curve_strength_changed(sender):
	var pad = sender.pad
	var zone_name = sender.zone_name
	var curve_strength = sender.curve_strength
	set_pad_property(pad, zone_name, "CurveStrength", curve_strength, false)
	
func _on_curve_type_changed(sender):
	var pad = sender.pad
	var zone_name = sender.zone_name
	var curve_type = sender.curve_type
	set_pad_property(pad, zone_name, "CurveType", curve_type, true)
	
func midi_number_text_field(node, pad, zone_name):
	var midi_number_text_field = MIDINumberTextFieldScene.instantiate()
	
	midi_number_text_field.pad = pad
	midi_number_text_field.zone_name = zone_name
	var midi_note = int(get_pad_property(pad, zone_name, "Note"))
	midi_number_text_field.text = str(midi_note)
	midi_number_text_field.number_changed.connect(_on_midi_number_changed)
	
	node.add_child(midi_number_text_field)
	
func _on_midi_number_changed(sender):
	var pad = sender.pad
	var zone_name = sender.zone_name
	
	var midi_note_str = sender.text
	if not midi_note_str.is_valid_float():
		return
	
	var midi_note = clamp(int(midi_note_str.to_float()), 0, 127)
	set_pad_property(pad, zone_name, "Note", midi_note, false)

func positional_sensing_cc_text_field(node, pad, zone_name):
	var midi_number_text_field = MIDINumberTextFieldScene.instantiate()
	
	midi_number_text_field.pad = pad
	midi_number_text_field.zone_name = zone_name
	var midi_note = int(get_pad_property(pad, zone_name, "PositionalSensingControlChange"))
	midi_number_text_field.text = str(midi_note)
	midi_number_text_field.number_changed.connect(_on_positional_sensing_cc_changed)
	
	node.add_child(midi_number_text_field)
	
	var cc_label = Label.new()
	cc_label.text = "CC"
	node.add_child(cc_label)

func _on_positional_sensing_cc_changed(sender):
	var pad = sender.pad
	var zone_name = sender.zone_name
	
	var cc_str = sender.text
	if not cc_str.is_valid_float():
		return
	
	var cc = clamp(int(cc_str.to_float()), 0, 127)
	set_pad_property(pad, zone_name, "PositionalSensingControlChange", cc, false)

func hi_hat_pedal_cc_text_field(node, pad, zone_name):
	var midi_number_text_field = MIDINumberTextFieldScene.instantiate()
	
	midi_number_text_field.pad = pad
	midi_number_text_field.zone_name = zone_name
	var midi_note = int(get_pad_property(pad, zone_name, "PedalControlChange"))
	midi_number_text_field.text = str(midi_note)
	midi_number_text_field.number_changed.connect(_on_hi_hat_pedal_cc_changed)
	
	node.add_child(midi_number_text_field)
	
	var cc_label = Label.new()
	cc_label.text = "CC"
	node.add_child(cc_label)

func _on_hi_hat_pedal_cc_changed(sender):
	var pad = sender.pad
	var zone_name = sender.zone_name
	
	var cc_str = sender.text
	if not cc_str.is_valid_float():
		return
	
	var cc = clamp(int(cc_str.to_float()), 0, 127)
	set_pad_property(pad, zone_name, "PedalControlChange", cc, false)

func zone_check_box(node, pad, zone_name, alawys_enabled):
	var zone_check_box = PropertyCheckBoxScene.instantiate()
	var property = "Enabled"
	
	zone_check_box.pad = pad
	zone_check_box.zone_name = zone_name
	zone_check_box.property = property
	var enabled
	if alawys_enabled:
		enabled = true
	else:
		enabled = get_pad_property(pad, zone_name, property)
	zone_check_box.button_pressed = enabled
	zone_check_box.connect("toggled", Callable(self, "_on_check_button_toggled").bind(zone_check_box))

	node.add_child(zone_check_box)
	
	var zone_label = Label.new()
	zone_label.text = zone_name
	node.add_child(zone_label)
	
	return zone_check_box.button_pressed
		
func property_check_box(node, pad, zone_name, property):
	var property_check_box = PropertyCheckBoxScene.instantiate()
	
	property_check_box.pad = pad
	property_check_box.zone_name = zone_name
	property_check_box.property = property
	property_check_box.button_pressed = get_pad_property(pad, zone_name, property)
	property_check_box.connect("toggled", Callable(self, "_on_check_button_toggled").bind(property_check_box))

	node.add_child(property_check_box)
	
	var property_label = Label.new()
	property_label.add_theme_color_override("font_color", Color(0, 0, 0))
	var text = property
	if text == "DoublePedal":
		text = "Double Pedal?"
	if text == "HeelToe":
		text = "Heel Toe?"
	if text == "PositionalSensingEnabled":
		text = "Positional Sensing?"
	property_label.text = text
	node.add_child(property_label)
	
	return property_check_box.button_pressed

func _on_check_button_toggled(pressed, sender):
	var pad = sender.pad
	var zone_name = sender.zone_name
	var property = sender.property
	set_pad_property(pad, zone_name, property, pressed, true)
		
func add_pad_name_text_field(pad_properties, pad, pad_index):
	var name = pad["Name"]
	
	var text_field = MIDIDeviceNameScene.instantiate()
	text_field.index = pad_index
	text_field.text = name
	text_field.name_changed.connect(_on_pad_name_changed)
	pad_properties.add_child(text_field)

func add_midi_channel_button(midi_device_instance, channel):
	var channels = Global.drum_kit["Channels"]
	
	var midi_channel_button = MIDIChannelButtonScene.instantiate()
	midi_channel_button.text = str(channel+1)
	midi_channel_button.button_clicked.connect(_on_midi_channel_button_clicked)
	
	if float(channel) in channels:
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = Color(0.2, 0.6, 0.8)
		midi_channel_button.add_theme_stylebox_override("normal", stylebox)
			
	midi_device_instance.add_child(midi_channel_button)

func add_pad_type_selector(pad_properties, pad, pad_index):
	var current_type = pad["Type"]
	
	var pad_type_selector = OptionButtonScene.instantiate()
	pad_type_selector.current_index = pad_index
	pad_type_selector.option_changed.connect(_on_pad_type_changed)
	
	var found_type = false
	for i in range(Global.VALID_PAD_TYPES.size()):
		var type = Global.VALID_PAD_TYPES[i]
		pad_type_selector.add_item(type)
		if type == current_type:
			pad_type_selector.select(i)
			found_type = true
		
	if not found_type:
		pad_type_selector.add_item(SELECT_PAD_TYPE_TEXT)
		pad_type_selector.select(Global.VALID_PAD_TYPES.size())
		
	pad_properties.add_child(pad_type_selector)
	
func add_midi_input_selector(midi_device_instance):
	var current_input = Global.drum_kit["Input"]
	
	var midi_input_selector = OptionButtonScene.instantiate()
	midi_input_selector.option_changed.connect(_on_midi_input_changed)
	
	var connected_inputs = OS.get_connected_midi_inputs()
	var found_input = false
	for i in range(connected_inputs.size()):
		var midi_input = connected_inputs[i]
		midi_input_selector.add_item(midi_input)
		if midi_input == current_input:
			midi_input_selector.select(i)
			found_input = true
		
	if not found_input:
		midi_input_selector.add_item(SELECT_MIDI_INPUT_TEXT)
		midi_input_selector.select(connected_inputs.size())
		
	midi_device_instance.add_child(midi_input_selector)

func add_button():
	var add_button = AddButtonScene.instantiate()
	add_button.button_clicked.connect(_on_add_button_clicked)
	midi_device_vbox_container.add_child(add_button)

func remove_button(container, pad):
	var remove_button = RemoveButtonScene.instantiate()
	remove_button.pressed.connect(_on_remove_button_clicked.bind(pad))
	container.add_child(remove_button)

func _on_pad_name_changed(sender):
	var pad = Global.drum_kit["Pads"][sender.index]
	pad["Name"] = sender.text
	Utils.save_json_file(Global.drum_kit_path, Global.drum_kit)
		
func _on_midi_channel_button_clicked(sender):
	var channels = Global.drum_kit["Channels"]
		
	var channel = float(sender.text) - 1
	if channel in channels:
		channels.erase(channel)
	else:
		channels.append(channel)
		
	Utils.save_json_file(Global.drum_kit_path, Global.drum_kit)
	refresh = true

func add_new_pad():
	var new_pad = {
		"Name": "New Pad",
		"Type": SELECT_PAD_TYPE_TEXT
	}
	
	Global.drum_kit["Pads"].append(new_pad)
	
	Utils.save_json_file(Global.drum_kit_path, Global.drum_kit)
	refresh = true

func remove_pad(pad):
	Global.drum_kit["Pads"].erase(pad)
	Utils.save_json_file(Global.drum_kit_path, Global.drum_kit)
	refresh = true
	
func set_pad_type(pad, pad_type):
	if pad_type != SELECT_PAD_TYPE_TEXT:
		for key in pad.keys():
			if key != "Name" and key != "Position" and key != "Layer":
				pad.erase(key)
		pad["Type"] = pad_type

	Utils.save_json_file(Global.drum_kit_path, Global.drum_kit)
	refresh = true
	
func _on_pad_type_changed(sender, index):
	var pad = Global.drum_kit["Pads"][sender.current_index]
	var new_type = sender.get_item_text(index)
	set_pad_type(pad, new_type)
	
func _on_midi_input_changed(sender, index):
	var new_input = sender.get_item_text(index)
	if new_input != SELECT_MIDI_INPUT_TEXT:
		Global.drum_kit["Input"] = new_input

	Utils.save_json_file(Global.drum_kit_path, Global.drum_kit)
	refresh = true

func _on_remove_button_clicked(pad):
	remove_pad(pad)

func add_new_midi_device():
	Global.drum_kit["Input"] = SELECT_MIDI_INPUT_TEXT
	Global.drum_kit["Channels"] = [0]

	Utils.save_json_file(Global.drum_kit_path, Global.drum_kit)
	refresh = true

func _on_snap_checkbox_pressed() -> void:
	snap_enabled = !snap_enabled
	highway.set_lane_lines_visibility(snap_enabled)

func set_num_lanes(val):
	Global.drum_kit["Lanes"] = val
	highway.num_lanes = val
	lane_count_label.text = str(int(val))
	Utils.save_json_file(Global.drum_kit_path, Global.drum_kit)
	highway.refresh_boundaries()
	draw_notes_on_highway()
	
func _on_arrow_up_button_pressed() -> void:
	set_num_lanes(Global.drum_kit["Lanes"] + 1)

func _on_arrow_down_button_pressed() -> void:
	set_num_lanes(Global.drum_kit["Lanes"] - 1)
