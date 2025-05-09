extends CheckBox

@onready var song = get_node("/root/Game/Song")

func _ready():
	anchor_top = 0
	anchor_bottom = 0
	anchor_left = 10
	anchor_right = 0

	position = Vector2(0, Global.hud_yPos)
	custom_minimum_size = Vector2(50, 24)
	
	button_pressed = Global.setting_tint_colored
	connect("toggled", Callable(self, "_on_check_button_toggled"))
	
	Global.increment_hud_yPos()
	
func _on_check_button_toggled(_button_pressed: bool) -> void:
	Global.setting_tint_colored = not Global.setting_tint_colored
	song.load_song(Global.current_song_path)
