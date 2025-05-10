extends Area2D

@onready var note = get_parent()

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		self.on_click()

func on_click():
	print("Click")
	note.color_r = 1
	note.color_g = 1
	note.color_b = 1
	note.color_a = 1
	note.set_sprite()
