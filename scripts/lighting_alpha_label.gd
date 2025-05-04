extends Label

func _ready():
	anchor_top = 0
	anchor_bottom = 0
	anchor_left = 10
	anchor_right = 0

	position = Vector2(Global.HUD_LABEL_XPOS, Global.hud_yPos)
	
	Global.increment_hud_yPos()
	
func _physics_process(_delta):
	text = "Lighting Alpha: " + str(int(Global.lighting_alpha))
