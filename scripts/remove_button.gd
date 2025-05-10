extends Button

func _ready():
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color8(100, 0, 0)
	add_theme_stylebox_override("normal", stylebox)
