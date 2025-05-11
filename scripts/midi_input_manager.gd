extends Node

signal midi_send(channel, type, pitch, velocity, controller_number, controller_value, pressure)

var midi_inputs = []

func _ready():
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
					#print_midi_message(event.channel, type, event.pitch, event.velocity, event.controller_number, event.controller_value, event.pressure)
