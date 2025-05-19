extends Node2D

@onready var drum_kit_vbox_container = $ScrollContainer/PanelContainer/VBoxContainer/DrumKitPanelContainer/DrumKitVBoxContainer
@onready var midi_device_vbox_container = $MIDIDevicePanelContainer/MIDIDeviceVBoxContainer
@onready var tom_order_vbox_container = %TomOrderVBoxContainer

@onready var highway = $Highway

@onready var arrow_up_button = $LaneCountContainer/ArrowUpButton
@onready var lane_count_label = $LaneCountContainer/LaneCountLabel
@onready var arrow_down_button = $LaneCountContainer/ArrowDownButton

@onready var note_on_off = %NoteOnOff
@onready var note_pitch = %NotePitch
@onready var note_velocity = %NoteVelocity
@onready var note_channel = %NoteChannel
@onready var note_drum_name = %NoteDrumName
@onready var cc_number = %CCNumber
@onready var cc_value = %CCValue
@onready var cc_channel = %CCChannel
@onready var cc_drum_name = %CCDrumName

@onready var current_note_label = %CurrentNoteLabel
@onready var invalid_zones_label = %InvalidZonesLabel
@onready var save_button = %SaveButton

const DrumPadInstanceScene = preload("res://scenes/drum_pad_instance.tscn")
const PadPropertiesScene = preload("res://scenes/pad_properties.tscn")

const MIDIDeviceInstanceScene = preload("res://scenes/midi_device_instance.tscn")
const MIDIDeviceNameScene = preload("res://scenes/midi_device_name.tscn")
const MIDIChannelButtonScene = preload("res://scenes/midi_channel_button.tscn")
const OptionButtonScene = preload("res://scenes/option_button.tscn")
const MIDINumberTextFieldScene = preload("res://scenes/midi_number_text_field.tscn")
const PropertyCheckBoxScene = preload("res://scenes/property_check_box.tscn")
const VelocityCurveEditorScene = preload("res://scenes/velocity_curve_editor.tscn")

const ArrowUpButtonScene = preload("res://scenes/arrow_up_button.tscn")
const ArrowDownButtonScene = preload("res://scenes/arrow_down_button.tscn")
const RemoveButtonScene = preload("res://scenes/remove_button.tscn")

const DrumKitConfirmationDialogScene = preload("res://scenes/drum_kit_confirmation_dialog.tscn")

const SELECT_PAD_TYPE_TEXT = "Select pad type..."
const SELECT_MIDI_INPUT_TEXT = "Select MIDI input..."

var clicked_note
var dragging
var original_mouse_position

var snap_enabled = false

var note_pad_indeces

var refresh = false

func _process(_delta):
	if refresh:
		update_contents()

func _ready():
	MidiInputManager.midi_send.connect(_on_midi_received)
	highway.set_playable(false)
			
func _on_midi_received(channel, type, pitch, velocity, controller_number, controller_value, pressure):
	var channel_text
	if MidiInputManager.is_valid_channel(channel):
		channel_text = ""
	else:
		channel_text = "[Ch. " + str(channel+1) + "]"
		
	if type == "cc":
		cc_number.text = "CC #" + str(controller_number)
		cc_value.text = "(Value: " + str(controller_value) + ")"
		cc_channel.text = channel_text
	else:
		if type == "noteon":
			note_on_off.text = "Note On"
			note_velocity.text = "(Vel: " + str(velocity) + ")"
		if type == "noteoff":
			note_on_off.text = "Note Off"
			note_velocity.text = ""
		note_pitch.text = "#" + str(pitch)
		note_channel.text = channel_text

		var pad_and_zone = Global.get_zone(type, pitch)
		if MidiInputManager.is_valid_note(channel, type, pitch, velocity):
			note_drum_name.text = pad_and_zone[0]["Name"] + " (" + pad_and_zone[2] + ")"
		else:
			note_drum_name.text = ""
				
func update_contents():
	refresh = false
	
	for child in drum_kit_vbox_container.get_children():
		child.queue_free()
	for child in midi_device_vbox_container.get_children():
		child.queue_free()
		
	if Global.drum_kit.has("Input") and Global.drum_kit.has("Channels"):
		add_midi_devices_widget()
	else:
		add_new_midi_device()
	
	draw_notes_on_highway()
	
	add_drum_kit_editor_widget() #after draw_notes_on_highway()
	
	update_save_button()

func draw_notes_on_highway():
	var num_lanes = Global.drum_kit["Lanes"]
	num_lanes = float(num_lanes)
	lane_count_label.text = str(int(num_lanes))
	arrow_up_button.visible = num_lanes < 10
	arrow_down_button.visible = num_lanes > 4

	const NUM_ROWS = 4
	var row_times = []
	for row in range(NUM_ROWS):
		var row_time = row*0.4 + 0.0
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
	
	note_pad_indeces = []
	
	var pad_list = Global.drum_kit["Pads"]
	for pad_index in range(pad_list.size()):
		var pad = pad_list[pad_index]
		var pad_type = pad["Type"]
		var pad_position
		var pad_layer
		if pad.has("Position") and pad.has("Layer"):
			pad_position = pad["Position"]
			pad_layer = pad["Layer"]
			note_data.append([row_times[pad_layer], pad_type, pad_position, pad_index, DEFAULT_VELOCITY, -1])
			note_pad_indeces.append(pad_index)
			
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
		if Global.DEBUG_MODE:
			rect.color = Color(1, 1, 1, 0.5)
		else:
			rect.color = Color(1, 1, 1, 0)
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
					clicked_note.time = row_times[pad_layer]
					
					clicked_note.update_position()
					set_collision_rect_position(rect, clicked_note)
					
					var pad = pad_list[note.pad_index]
					pad["Position"] = pad_position
					pad["Layer"] = pad_layer
			)
	
	update_save_button()
	
	return note_pad_indeces

func update_save_button():
	var text = ""
	for message in Global.get_drumkit_error_messages():
		text = text + message + "\n"
	invalid_zones_label.text = text
	save_button.visible = (text == "")
	
func set_clicked_note(note):
	for test_note in highway.get_notes():
		test_note.set_grayscale(test_note != note and note != null)
	
	var note_text
	if note != null:
		var note_label = Label.new()
		var pad_index = note.pad_index
		var pad = Global.drum_kit["Pads"][pad_index]
		note_text = "Current note: " + pad["Name"]
	else:
		note_text = ""
	current_note_label.text = note_text
	
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

func cleanup_tom_order(tom_pad_list):
	var new_orders = 0
	var pads_in_order = []
	var pad_type
	for i in range(tom_pad_list.size()):
		var pad = tom_pad_list[i]
		pad_type = pad["Type"]
		if !pad.has("Order"):
			pad["Order"] = tom_pad_list.size() + new_orders
			new_orders += 1
		var pad_order = pad["Order"]
		pads_in_order.append([pad, pad_order])
		
	pads_in_order.sort_custom(func(a, b):
		return a[1] < b[1]
	)
	
	for i in range(pads_in_order.size()):
		var pad = pads_in_order[i][0]
		pad["Order"] = i
	
	tom_pad_list.sort_custom(func(a, b):
		return a["Order"] < b["Order"]
	)

func add_tom_order_hbox_containers(tom_pad_list):
	for i in range(tom_pad_list.size()):
		var pad = tom_pad_list[i]
		var pad_type = pad["Type"]
		var pad_order = pad["Order"]
		
		var tom_pad_order_hbox_container = HBoxContainer.new()
		var tom_pad_label = Label.new()
		tom_pad_label.text = pad["Name"]
		tom_pad_order_hbox_container.add_child(tom_pad_label)
		
		if i > 0:
			var pad_to_swap = tom_pad_list[i-1]
			var arrow_up_button = ArrowUpButtonScene.instantiate()
			arrow_up_button.connect("pressed", Callable(self, "_move_tom_in_order").bind(pad, pad_to_swap))
			tom_pad_order_hbox_container.add_child(arrow_up_button)
		if i < tom_pad_list.size()-1:
			var pad_to_swap = tom_pad_list[i+1]
			var arrow_down_button = ArrowDownButtonScene.instantiate()
			arrow_down_button.connect("pressed", Callable(self, "_move_tom_in_order").bind(pad, pad_to_swap))
			tom_pad_order_hbox_container.add_child(arrow_down_button)

		tom_pad_order_hbox_container.add_child(tom_pad_label)
		tom_order_vbox_container.add_child(tom_pad_order_hbox_container)
				
func add_drum_kit_editor_widget():
	var octoban_pad_list = []
	var racktom_pad_list = []
	var floortom_pad_list = []
	
	var pad_list = Global.drum_kit["Pads"]
	for pad_index in range(pad_list.size()):
		var pad = pad_list[pad_index]
		var pad_type = pad["Type"]
		
		if pad_type == "octoban":
			octoban_pad_list.append(pad)
		if pad_type == "racktom":
			racktom_pad_list.append(pad)
		if pad_type == "floortom":
			floortom_pad_list.append(pad)
		
		var pad_instance = DrumPadInstanceScene.instantiate()
		var pad_properties = PadPropertiesScene.instantiate()
		add_pad_name_text_field(pad_properties, pad, pad_index)
		add_pad_type_label(pad_properties, pad)
		remove_button(pad_properties, pad)
		
		if pad_type == "kick":
			property_check_box(pad_properties, pad, "", "DoublePedal")
		if pad_type == "snare":
			positional_sensing_widget(pad_properties, pad, "")
		if pad_type == "racktom":
			positional_sensing_widget(pad_properties, pad, "")
		if pad_type == "floortom":
			positional_sensing_widget(pad_properties, pad, "")
		if pad_type == "hihat":
			positional_sensing_widget(pad_properties, pad, "")
			if property_check_box(pad_properties, pad, "", "PedalSendsMIDI"):
				midi_number_text_field(pad_properties, pad, "", "PedalControlChange")
		if pad_type == "ride":
			positional_sensing_widget(pad_properties, pad, "")
		if pad_type == "crash":
			positional_sensing_widget(pad_properties, pad, "")
									
		pad_instance.add_child(pad_properties)
		
		var zones_vbox_container = VBoxContainer.new()
		pad_instance.add_child(zones_vbox_container)
		
		var container
		if pad_type == "kick":
			container = add_persistent_zone_data(zones_vbox_container, pad, "head")
		if pad_type == "snare":
			container = add_persistent_zone_data(zones_vbox_container, pad, "head")
			container = add_persistent_zone_data(zones_vbox_container, pad, "sidestick")
			if get_pad_property(pad, "sidestick", "Enabled"):
				container = add_persistent_zone_data(zones_vbox_container, pad, "rim")
		if pad_type == "racktom":
			container = add_persistent_zone_data(zones_vbox_container, pad, "head")
			container = add_persistent_zone_data(zones_vbox_container, pad, "rim")
		if pad_type == "floortom":
			container = add_persistent_zone_data(zones_vbox_container, pad, "head")
			container = add_persistent_zone_data(zones_vbox_container, pad, "rim")
		if pad_type == "hihat":
			container = add_persistent_zone_data(zones_vbox_container, pad, "bow")
			container = add_persistent_zone_data(zones_vbox_container, pad, "edge")
			container = add_persistent_zone_data(zones_vbox_container, pad, "bell")
			container = add_persistent_zone_data(zones_vbox_container, pad, "stomp")
			container = add_persistent_zone_data(zones_vbox_container, pad, "splash")
		if pad_type == "ride":
			container = add_persistent_zone_data(zones_vbox_container, pad, "bow")
			container = add_persistent_zone_data(zones_vbox_container, pad, "edge")
			container = add_persistent_zone_data(zones_vbox_container, pad, "bell")
		if pad_type == "crash":
			container = add_persistent_zone_data(zones_vbox_container, pad, "bow")
			container = add_persistent_zone_data(zones_vbox_container, pad, "edge")
			container = add_persistent_zone_data(zones_vbox_container, pad, "bell")
												
		drum_kit_vbox_container.add_child(pad_instance)
	
	var pad_type_selector = OptionButtonScene.instantiate()
	pad_type_selector.option_changed.connect(_on_pad_type_selected)
	
	pad_type_selector.add_item("Select pad type...")
	for type in Global.VALID_PAD_TYPES:
		pad_type_selector.add_item(type)
		
	drum_kit_vbox_container.add_child(pad_type_selector)
	
	if racktom_pad_list.size() >= 2 and floortom_pad_list.size() >= 1:
		for child in tom_order_vbox_container.get_children():
			child.queue_free()
			
		cleanup_tom_order(octoban_pad_list)
		cleanup_tom_order(racktom_pad_list)
		cleanup_tom_order(floortom_pad_list)
		add_tom_order_hbox_containers(octoban_pad_list)
		add_tom_order_hbox_containers(racktom_pad_list)
		add_tom_order_hbox_containers(floortom_pad_list)

func _move_tom_in_order(pad, pad_to_swap):
	var original_pad_order = pad["Order"]
	pad["Order"] = pad_to_swap["Order"]
	pad_to_swap["Order"] = original_pad_order
	
	refresh = true

func add_midi_devices_widget():
	var midi_device_instance = MIDIDeviceInstanceScene.instantiate()
	
	add_midi_input_selector(midi_device_instance)

	for channel in range(16):
		add_midi_channel_button(midi_device_instance, channel)

	midi_device_vbox_container.add_child(midi_device_instance)

func add_persistent_zone_data(parent_container, pad, zone_name):
	var zone_hbox_container = HBoxContainer.new()
	parent_container.add_child(zone_hbox_container)
	if zone_check_box(zone_hbox_container, pad, zone_name):
		midi_number_text_field(zone_hbox_container, pad, zone_name, "Note")
		velocity_curve_widget(zone_hbox_container, pad, zone_name)
	return zone_hbox_container
	
func get_pad_property(pad, zone_name, property):
	if zone_name == "":
		return pad[property]
	else:
		return pad[zone_name][property]

func set_pad_property(pad, zone_name, property, val, to_update_contents):
	if zone_name == "":
		pad[property] = val
	else:
		pad[zone_name][property] = val
		
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
	if property_check_box(pad_properties, pad, zone_name, "PositionalSensing"):
		midi_number_text_field(pad_properties, pad, zone_name, "PositionalSensingControlChange")
				
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
	
func midi_number_text_field(node, pad, zone_name, property):
	var midi_number_text_field = MIDINumberTextFieldScene.instantiate()
	
	midi_number_text_field.pad = pad
	midi_number_text_field.zone_name = zone_name
	midi_number_text_field.property = property
	
	var val = get_pad_property(pad, zone_name, property)
	var text
	if val is float or val is int:
		text = str(int(val))
	elif val is Array and property == "Note":
		text = ""
		for i in range(val.size()):
			text += str(int(val[i]))
			if i != val.size()-1:
				text += ","
	else:
		text = val
				
	midi_number_text_field.text = text
	midi_number_text_field.number_changed.connect(_on_midi_number_changed)
	
	node.add_child(midi_number_text_field)

	if property != "Note":
		var label = Label.new()
		label.text = "CC"
		node.add_child(label)
	if Global.does_zone_require_multiple_values(pad, zone_name):
		var label = Label.new()
		label.text = "(most closed to most open)"
		node.add_child(label)
	
func _on_midi_number_changed(sender):
	var pad = sender.pad
	var zone_name = sender.zone_name
	var property = sender.property
	
	var val = sender.text
	
	var valid_string = true

	var numbers = Utils.parse_numbers(val)
	if (numbers.size() > 1 and property != "Note") or numbers.size() == 0 or "." in val:
		valid_string = false
	for number in numbers:
		if not Global.is_valid_midi_number(number):
			valid_string = false
	
	var final_val
	if valid_string:
		if numbers.size() == 1:
			final_val = numbers[0]
		else:
			final_val = numbers
	else:
		final_val = val
		
	set_pad_property(pad, zone_name, property, final_val, false)

	update_save_button()

func _on_positional_sensing_cc_changed(sender):
	var pad = sender.pad
	var zone_name = sender.zone_name
	
	var cc = sender.text
	if cc.is_valid_float():
		cc = clamp(int(cc.to_float()), 0, 127)
	set_pad_property(pad, zone_name, "PositionalSensingControlChange", cc, false)
	
	update_save_button()

func _on_hi_hat_pedal_cc_changed(sender):
	var pad = sender.pad
	var zone_name = sender.zone_name
	
	var cc = sender.text
	if cc.is_valid_float():
		cc = clamp(int(cc.to_float()), 0, 127)
	set_pad_property(pad, zone_name, "PedalControlChange", cc, false)
	
	update_save_button()

func zone_check_box(node, pad, zone_name):
	var zone_check_box = PropertyCheckBoxScene.instantiate()
	var property = "Enabled"
	
	zone_check_box.pad = pad
	zone_check_box.zone_name = zone_name
	zone_check_box.property = property
	var enabled
	if pad[zone_name].has(property):
		enabled = get_pad_property(pad, zone_name, property)
	else:
		enabled = true
		zone_check_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.3, 0.3)
		zone_check_box.add_theme_stylebox_override("pressed", style)
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
	if text == "PositionalSensing":
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

func add_pad_type_label(pad_properties, pad):
	var pad_type_label = Label.new()
	pad_type_label.text = pad["Type"]
	pad_properties.add_child(pad_type_label)
	
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

func remove_button(container, pad):
	var remove_button = RemoveButtonScene.instantiate()
	remove_button.pressed.connect(_on_remove_button_clicked.bind(pad))
	container.add_child(remove_button)

func _on_pad_name_changed(sender):
	var pad = Global.drum_kit["Pads"][sender.index]
	pad["Name"] = sender.text
	update_save_button()
		
func _on_midi_channel_button_clicked(sender):
	var channels = Global.drum_kit["Channels"]
		
	var channel = float(sender.text) - 1
	if channel in channels:
		channels.erase(channel)
	else:
		channels.append(channel)
		
	refresh = true

func get_default_position(lane):
	var center_x = (highway.get_lane_position(lane)[0] + highway.get_lane_position(lane+1)[0]) * 0.5
	return Utils.convert_range(center_x, Global.HIGHWAY_XMIN, Global.HIGHWAY_XMAX, 0.0, 1.0)

func create_default_zone(pad, zone_name):
	var zone = {
		"Note": "",
		"CurveType": 0,
		"CurveStrength": 0
	}
	if zone_name == "sidestick" or zone_name == "rim" or zone_name == "edge" or zone_name == "bell" or zone_name == "splash":
		zone["Enabled"] = false
	
	pad[zone_name] = zone
			
func add_new_pad(pad_type):
	var pad = {
		"Name": "New Pad",
		"Type": pad_type
	}
	
	if pad_type == "snare":
		pad["Position"] = get_default_position(0)
		pad["Layer"] = 0
		create_default_zone(pad, "head")
		create_default_zone(pad, "sidestick")
		create_default_zone(pad, "rim")
	if pad_type == "racktom":
		pad["Position"] = get_default_position(1)
		pad["Layer"] = 0
		create_default_zone(pad, "head")
		create_default_zone(pad, "rim")
	if pad_type == "floortom":
		pad["Position"] = get_default_position(highway.num_lanes-1)
		pad["Layer"] = 0
		create_default_zone(pad, "head")
		create_default_zone(pad, "rim")
	if pad_type == "hihat":
		pad["Position"] = get_default_position(0)
		pad["Layer"] = 1
		pad["PedalSendsMIDI"] = false
		pad["PedalControlChange"] = ""
		pad["PedalFlipPolarity"] = false
		create_default_zone(pad, "bow")
		create_default_zone(pad, "edge")
		create_default_zone(pad, "bell")
		create_default_zone(pad, "stomp")
		create_default_zone(pad, "splash")
	if pad_type == "ride":
		pad["Position"] = get_default_position(highway.num_lanes-1)
		pad["Layer"] = 1
		create_default_zone(pad, "bow")
		create_default_zone(pad, "edge")
		create_default_zone(pad, "bell")
	if pad_type == "crash":
		pad["Position"] = get_default_position(highway.num_lanes-2)
		pad["Layer"] = 1
		create_default_zone(pad, "bow")
		create_default_zone(pad, "edge")
		create_default_zone(pad, "bell")
	if pad_type == "kick":
		pad["DoublePedal"] = false
		create_default_zone(pad, "head")
	
	if pad_type != "kick":
		pad["PositionalSensing"] = false
		pad["PositionalSensingControlChange"] = ""
		
	Global.drum_kit["Pads"].append(pad)

	refresh = true

func remove_pad(pad):
	Global.drum_kit["Pads"].erase(pad)

	refresh = true

func _on_pad_type_selected(sender, index):
	if index > 0:
		var pad_type = sender.get_item_text(index)
		add_new_pad(pad_type)
	
func _on_midi_input_changed(sender, index):
	var new_input = sender.get_item_text(index)
	if new_input != SELECT_MIDI_INPUT_TEXT:
		Global.drum_kit["Input"] = new_input

	refresh = true

func _on_remove_button_clicked(pad):
	remove_pad(pad)

func add_new_midi_device():
	Global.drum_kit["Input"] = SELECT_MIDI_INPUT_TEXT
	Global.drum_kit["Channels"] = [0]

	refresh = true

func _on_snap_checkbox_pressed() -> void:
	snap_enabled = !snap_enabled
	highway.set_lane_lines_visibility(snap_enabled)

func set_num_lanes(val):
	Global.drum_kit["Lanes"] = val
	lane_count_label.text = str(int(val))
	highway.num_lanes = val
	highway.refresh_boundaries(false)
	draw_notes_on_highway()
	
func _on_arrow_up_button_pressed() -> void:
	set_num_lanes(Global.drum_kit["Lanes"] + 1)

func _on_arrow_down_button_pressed() -> void:
	set_num_lanes(Global.drum_kit["Lanes"] - 1)

func _on_save_button_pressed() -> void:
	Global.drum_kit["Valid"] = true
	Utils.save_json_file(Directory.DRUM_KIT_PATH, Global.drum_kit)

func _on_back_button_pressed() -> void:
	var drum_kit_confirmation_dialog = DrumKitConfirmationDialogScene.instantiate()
	add_child(drum_kit_confirmation_dialog)
	#SceneManager.set_scene("MainMenu")
