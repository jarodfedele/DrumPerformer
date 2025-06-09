extends OptionButton

@onready var song = get_node("/root/Game/Song")

@onready var gem_positioner = $"../GemPositioner"

@onready var shift_x_slider = $"../GemPositioner/ShiftXSlider"
@onready var shift_y_slider = $"../GemPositioner/ShiftYSlider"
@onready var scale_slider = $"../GemPositioner/ScaleSlider"
@onready var tint_alpha_slider = $"../GemPositioner/TintAlphaSlider"
@onready var blend_mode_selector = $"../GemPositioner/BlendModeSelector"

func _ready():
	anchor_top = 0
	anchor_bottom = 0
	anchor_left = 10
	anchor_right = 0
	
	position = Vector2(10, Global.hud_yPos)
	
	add_item("Select gem...")
	var note_list_text = Utils.read_text_file("res://note_list.txt")
	var lines = note_list_text.split("\n")
	for line in lines:
		line = line.strip_edges()
		if line.length() > 0:
			add_item(line)

	connect("item_selected", Callable(self, "_on_item_selected"))
	
	Global.increment_hud_yPos()
	
func _on_item_selected(index: int):
	if index == 0:
		Global.debug_selected_gem = null
		gem_positioner.visible = false
	else:
		var gem = get_item_text(index)
		Global.debug_selected_gem = gem
		
		Global.debug_update_notes = false
		
		shift_x_slider.value = Global.get_gem_config_setting(gem, "shiftx", 0)
		shift_y_slider.value = Global.get_gem_config_setting(gem, "shifty", 0)
		scale_slider.value = Global.get_gem_config_setting(gem, "scale", 1)
		tint_alpha_slider.value = Global.get_gem_config_setting(gem, "color_a", 1)
		var blend_tint_index = Global.get_gem_config_setting(gem, "blend_tint", 0)
		if blend_tint_index:
			blend_tint_index += 1
		else:
			blend_tint_index = 0
		blend_mode_selector.selected = blend_tint_index
		
		Global.debug_update_notes = true

		gem_positioner.visible = true
