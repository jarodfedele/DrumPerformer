extends Line2D

@onready var song_audio_player = get_node("/root/Game/AudioManager/SongAudioPlayer")

func _physics_process(_delta):
	if not song_audio_player.stream:
		return
	
	var length = song_audio_player.stream.get_length()
	var seek_time = song_audio_player.get_playback_position()
	
	var seek_x = Utils.convert_range(seek_time, 0, length, 0, Global.AUDIOBAR_XSIZE) + Global.AUDIOBAR_XMIN
	
	# Update the line's points
	clear_points()
	add_point(Vector2(seek_x, Global.AUDIOBAR_YMIN))
	add_point(Vector2(seek_x, Global.AUDIOBAR_YMAX))
