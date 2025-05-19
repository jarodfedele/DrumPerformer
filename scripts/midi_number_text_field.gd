extends LineEdit

signal number_changed(sender)

var pad
var zone_name
var property

func _ready():
	text_changed.connect(_on_text_changed)

func _on_text_changed(new_text):
	emit_signal("number_changed", self)
	
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		# Prevent default popup menu
		get_viewport().set_input_as_handled()
