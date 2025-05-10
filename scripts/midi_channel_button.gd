extends Button

signal button_clicked(sender)

func _ready():
	pressed.connect(_on_button_pressed)

func _on_button_pressed():
	emit_signal("button_clicked", self)
