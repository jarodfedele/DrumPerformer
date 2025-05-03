extends TextureButton

@onready var audio_player = $"../AudioStreamPlayer"
@onready var highway = $"../../Highway"

func _ready():
	position = Vector2(Global.PLAYBUTTON_XMIN, Global.PLAYBUTTON_YMIN)
	size = Vector2(Global.PLAYBUTTON_XSIZE, Global.PLAYBUTTON_YSIZE)
	
func _pressed():
	if audio_player.playing:
		modulate = Color(1, 1, 1)
		audio_player.stream_paused = true
	else:
		modulate = Color(0.3, 1, 0.1)
		audio_player.play(highway.current_song_time)
