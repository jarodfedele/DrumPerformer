extends TextureButton

@onready var song_audio_player = get_node("/root/Game/AudioManager/SongAudioPlayer")
@onready var song = get_node("/root/Game/Song")

var dragging = false

func _ready():
	position = Vector2(Global.AUDIOBAR_XMIN, Global.AUDIOBAR_YMIN)
	size = Vector2(Global.AUDIOBAR_XSIZE, Global.AUDIOBAR_YSIZE)

func update_seek(click_pos):
	var global_click_pos = get_global_mouse_position()  # Global screen coords
	var button_pos = global_position        # Global position of the button
	var button_size = size                  # Size from Control node
	var button_rect = Rect2(position, size) # Local-space rect
	var button_rect_global = Rect2(global_position, size)  # Global-space rect
	
	var percentage = Utils.convert_range(global_click_pos.x, button_pos.x, button_pos.x+button_size.x, 0, 1)
	
	var length = song_audio_player.stream.get_length()
	var seek_time = percentage * length
	seek_time = clamp(seek_time, 0.0, length)
	
	var progress = clamp(seek_time / length, 0.0, 1.0)
	
	var paused_state = (song_audio_player.stream_paused or not song_audio_player.playing)
	song_audio_player.stream_paused = false
	song_audio_player.play()
	song_audio_player.seek(seek_time)
	song_audio_player.stream_paused = paused_state

	song.sync_song_time(seek_time)
		
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT: #event.pressed is click
		if event.pressed:
			dragging = true
			update_seek(event.position)
		else:
			dragging = false
		
	if event is InputEventMouseMotion and dragging:
		update_seek(event.position)
