extends Label

func _ready():
	position = Vector2(10, 10)
	
func _physics_process(_delta):
	text = "FPS: " + str(Engine.get_frames_per_second())
