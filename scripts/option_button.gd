extends OptionButton

signal option_changed(sender)

var current_index

func _ready():
	item_selected.connect(_on_option_selected)

func _on_option_selected(index):
	emit_signal("option_changed", self, index)
