extends LineEdit

signal number_changed(sender)

var pad
var zone_name

func _ready():
	text_changed.connect(_on_text_changed)

func _on_text_changed(new_text):
	emit_signal("number_changed", self)
