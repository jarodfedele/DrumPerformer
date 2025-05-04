extends OptionButton

func _ready():
	anchor_top = 0
	anchor_bottom = 0
	anchor_left = 10
	anchor_right = 0
	
	position = Vector2(10, Global.hud_yPos)
	
	add_item("Select blend mode...")
	add_item("multiply")
	add_item("color_burn")
	add_item("linear_burn")
	add_item("hard_light")
	add_item("soft_light")
	add_item("color_dodge")
	add_item("linear_dodge")
	
	connect("item_selected", Callable(self, "_on_item_selected"))
	
	Global.increment_hud_yPos()
	
func _on_item_selected(index: int):
	if index > 0:
		var blend_tint = get_item_text(index)
		Global.debug_set_gem_property(Global.debug_selected_gem, "blend_tint", blend_tint)
