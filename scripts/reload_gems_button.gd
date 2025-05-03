extends Button

@onready var notes = $"../../Highway/Notes"

func _ready():
	anchor_top = 0
	anchor_bottom = 0
	anchor_left = 10
	anchor_right = 0

	position = Vector2(Global.HUD_LABEL_XPOS, Global.hud_yPos)
	
	Global.increment_hud_yPos()
	
	pressed.connect(_on_Button_pressed)
		
func _on_Button_pressed():
	notes.update_textures()
	notes.spawn_notes()
