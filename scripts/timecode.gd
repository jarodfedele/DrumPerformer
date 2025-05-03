extends Label

@onready var highway = $"../../Highway"
@onready var audio_player = get_node("../AudioStreamPlayer")

const Utils = preload("res://scripts/utils.gd")

func _ready():
	position = Vector2(Global.PLAYBUTTON_XMIN, Global.PLAYBUTTON_YMAX+20)
	
func _physics_process(delta):
	var length = audio_player.stream.get_length()
	if length:
		text = Utils.seconds_to_min_sec_string(highway.current_song_time) + "/" + Utils.seconds_to_min_sec_string(length)
