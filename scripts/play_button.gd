extends TextureButton

@onready var song = get_node("/root/Game/Song")
@onready var song_audio_player = get_node("/root/Game/AudioManager/SongAudioPlayer")

func _ready():
	position = Vector2(Global.PLAYBUTTON_XMIN, Global.PLAYBUTTON_YMIN)
	size = Vector2(Global.PLAYBUTTON_XSIZE, Global.PLAYBUTTON_YSIZE)
	
func _pressed():
	if song_audio_player.playing:
		modulate = Color(1, 1, 1)
		song_audio_player.stream_paused = true
	else:
		modulate = Color(0.3, 1, 0.1)
		song_audio_player.play(song.current_song_time)
