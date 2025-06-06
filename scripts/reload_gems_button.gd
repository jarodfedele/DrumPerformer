extends Button

@onready var song = get_node("/root/Game/Song")

func _ready():
	anchor_top = 0
	anchor_bottom = 0
	anchor_left = 10
	anchor_right = 0

	position = Vector2(Global.HUD_LABEL_XPOS, Global.hud_yPos)
	
	Global.increment_hud_yPos()
	
	pressed.connect(_on_button_pressed)
		
func _on_button_pressed():
	song.load_song(Global.current_song_path)
