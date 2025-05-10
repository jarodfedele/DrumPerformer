extends LineEdit

signal name_changed(sender)

var index

func _ready():
	text_changed.connect(_on_text_changed)

func _on_text_changed(new_text):
	emit_signal("name_changed", self)
