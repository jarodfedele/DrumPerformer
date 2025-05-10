extends Node

func _ready():
	OS.open_midi_inputs()
	for midi_input in OS.get_connected_midi_inputs():
		print(midi_input)

func _input(event):
	if event is InputEventMIDI:
		if event.channel == 0 and event.message == 9 and event.velocity > 0:
			print(event.device)
