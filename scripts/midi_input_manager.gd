extends Node

signal midi_send(channel, type, pitch, velocity, controller_number, controller_value, pressure)
signal pad_send(pad_index, zone_name, pitch)

var midi_inputs = []
var recent_cc_values = []

func _ready():
	for i in range(128):
		recent_cc_values.append(0)
		
	OS.open_midi_inputs()
	for midi_input in OS.get_connected_midi_inputs():
		midi_inputs.append(midi_input)
		
func print_midi_message(channel, type, pitch, velocity, controller_number, controller_value, pressure):
	print("---------")
	print("Channel: " + str(channel))
	print("Type: " + str(type))
	print("Pitch: " + str(pitch))
	print("Velocity: " + str(velocity))
	print("CC Number: " + str(controller_number))
	print("CC Value: " + str(controller_value))
	print("Pressure: ", str(pressure))

func get_pad_index(type, pitch):
	var pad_and_zone = Global.get_zone(type, pitch)
	var pad = pad_and_zone[0]
	var zone = pad_and_zone[1]
	var zone_name = pad_and_zone[2]		
	
	var pad_list = Global.drum_kit["Pads"]
	for pad_index in range(pad_list.size()):
		var test_pad = pad_list[pad_index]
		if pad == test_pad:
			return pad_index
	
func is_valid_note(channel, type, pitch, velocity):
	if !is_valid_channel(channel):
		return false
		
	if type != "noteon":
		return false #TODO

	var pad_and_zone = Global.get_zone(type, pitch)
	if pad_and_zone:
		return true
			
	return false

func is_valid_cc(channel, type):
	if !is_valid_channel(channel):
		return false
	
	if type != "cc":
		return false
	
	return true
	
func is_valid_channel(channel):
	return (float(channel) in Global.drum_kit["Channels"])
			
func _input(event):
	if event is InputEventMIDI:
		if event.message == Global.NOTE_ON or event.message == Global.NOTE_OFF or event.message == Global.CC:
			if midi_inputs[event.device] == Global.drum_kit["Input"]:
				var type
				if event.message == 8 or (event.message == 9 and event.velocity == 0):
					type = "noteoff"
				elif event.message == 9:
					type = "noteon"
				elif event.message == 11:
					type = "cc"
				if type:
					midi_send.emit(event.channel, type, event.pitch, event.velocity, event.controller_number, event.controller_value, event.pressure)
					
					if is_valid_note(event.channel, type, event.pitch, event.velocity):
						var pad_index = get_pad_index(type, event.pitch)
						var pad_and_zone = Global.get_zone(type, event.pitch)
						var zone_name = pad_and_zone[2]
						
						pad_send.emit(pad_index, zone_name, event.pitch)
					
					if is_valid_cc(event.channel, type):
						recent_cc_values[event.controller_number] = event.controller_value

					#print_midi_message(event.channel, type, event.pitch, event.velocity, event.controller_number, event.controller_value, event.pressure)
