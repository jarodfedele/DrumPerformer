extends HSlider

@onready var song = get_node("/root/Game/Song")

func _ready():
	anchor_top = 0
	anchor_bottom = 0
	anchor_left = 10
	anchor_right = 0

	position = Vector2(0, Global.hud_yPos)
	custom_minimum_size = Vector2(Global.HUD_SLIDER_LENGTH, 24)
	
	min_value = 0
	max_value = 255
	step = 1

	value = Global.lighting_alpha
	
	connect("value_changed", Callable(self, "_on_value_changed"))

func _on_value_changed(new_value: float) -> void:
	pass
