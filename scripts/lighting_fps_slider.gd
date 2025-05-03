extends HSlider

@onready var notes = $"../../Highway/Notes"

func _ready():
	anchor_top = 0
	anchor_bottom = 0
	anchor_left = 10
	anchor_right = 0

	position = Vector2(0, Global.hud_yPos)
	custom_minimum_size = Vector2(Global.HUD_SLIDER_LENGTH, 24)
	
	min_value = 5
	max_value = 30
	step = 1

	value = Global.lighting_fps
	
	connect("value_changed", Callable(self, "_on_value_changed"))

func _on_value_changed(new_value: float) -> void:
	Global.lighting_fps = new_value
	notes.update_sprites()
