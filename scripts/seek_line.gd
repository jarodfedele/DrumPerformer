extends Line2D

@onready var audio_player = $"../AudioStreamPlayer"

const Utils = preload("res://scripts/utils.gd")

func _physics_process(delta):
	if not audio_player.stream:
		return
	
	var length = audio_player.stream.get_length()
	var seek_time = audio_player.get_playback_position()
	
	var seek_x = Utils.convert_range(seek_time, 0, length, 0, Global.AUDIOBAR_XSIZE) + Global.AUDIOBAR_XMIN
	
	# Update the line's points
	clear_points()
	add_point(Vector2(seek_x, Global.AUDIOBAR_YMIN))
	add_point(Vector2(seek_x, Global.AUDIOBAR_YMAX))
