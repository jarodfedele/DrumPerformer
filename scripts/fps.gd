extends Label

func _physics_process(_delta):
	text = "FPS: " + str(Engine.get_frames_per_second())
