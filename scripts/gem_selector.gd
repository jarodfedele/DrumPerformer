extends OptionButton

const Utils = preload("res://scripts/utils.gd")
@onready var gem_positioner = $"../GemPositioner"
@onready var notes = $"../../Highway/Notes"

@onready var shift_x_slider = $"../GemPositioner/ShiftXSlider"
@onready var shift_y_slider = $"../GemPositioner/ShiftYSlider"
@onready var scale_slider = $"../GemPositioner/ScaleSlider"
@onready var tint_alpha_slider = $"../GemPositioner/TintAlphaSlider"
@onready var file_dialog = $"../FileDialog"

func _ready():
	anchor_top = 0
	anchor_bottom = 0
	anchor_left = 10
	anchor_right = 0
	
	position = Vector2(10, Global.hud_yPos)
	
	add_item("Select gem...")
	var text = Utils.read_text_file("res://note_list.txt")
	var lines = text.split("\n")
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
		Global.debug_selected_gem = get_item_text(index)
		for note in notes.get_children():
			if note.gem == Global.debug_selected_gem:
				Global.debug_update_notes = false
				
				gem_positioner.visible = true
				Global.debug_selected_test_note = note
				shift_x_slider.value = note.positioning_shift_x
				shift_y_slider.value = note.positioning_shift_y
				scale_slider.value = note.positioning_scale
				tint_alpha_slider.value = note.color_a
				
				notes.spawn_notes()
				
				Global.debug_update_notes = true
				return
		gem_positioner.visible = false
