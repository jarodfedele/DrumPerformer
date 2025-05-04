extends HSlider

func _ready():
	anchor_top = 0
	anchor_bottom = 0
	anchor_left = 10
	anchor_right = 0

	position = Vector2(0, Global.hud_yPos)
	custom_minimum_size = Vector2(Global.HUD_SLIDER_LENGTH, 24)
	
	min_value = -0.25
	max_value = 0.25
	step = 0.01
	
	connect("value_changed", Callable(self, "_on_value_changed"))
	
func _on_value_changed(new_value: float) -> void:
	Global.debug_set_gem_property(Global.debug_selected_gem, "shiftx", new_value)
