class_name AudioBar extends Node2D

@onready var waveform_button = %WaveformButton
@onready var play_button = %PlayButton
@onready var seek_line = %SeekLine
@onready var timecode = %Timecode

@onready var song = get_parent()

var audio_stream_player

var x_min : int
var y_min : int
var x_size : int
var y_size : int
var x_max : int
var y_max : int

const AUDIOBAR_SCENE: PackedScene = preload("res://scenes/audio_bar.tscn")

static func create(audio_stream_player: AudioStreamPlayer, x_min: int, y_min: int, x_size: int, y_size: int):
	var instance: AudioBar = AUDIOBAR_SCENE.instantiate()
	
	instance.audio_stream_player = audio_stream_player
	
	instance.x_min = x_min
	instance.y_min = y_min
	instance.x_size = x_size
	instance.y_size = y_size
	instance.x_max = instance.x_min + instance.x_size
	instance.y_max = instance.y_min + instance.y_size
	
	return instance

func layout_children():
	waveform_button.position = Vector2(x_min, y_min)
	waveform_button.size = Vector2(x_size, y_size)
	
	var play_button_x_min = x_max+10
	
	play_button.position = Vector2(play_button_x_min, y_min)
	play_button.size = Vector2(y_size, y_size)
	
	timecode.position = Vector2(play_button_x_min, y_max+20)
	
func _ready():
	layout_children()

func _physics_process(_delta):
	if not audio_stream_player.stream: #TODO: should always exist now?
		return
	
	var length = audio_stream_player.stream.get_length()
	var seek_time = audio_stream_player.get_playback_position()
	
	var seek_x = Utils.convert_range(seek_time, 0, length, 0, x_size) + x_min
	
	# Update the line's points
	seek_line.clear_points()
	seek_line.add_point(Vector2(seek_x, y_min))
	seek_line.add_point(Vector2(seek_x, y_max))

func _on_play_button_pressed() -> void:
	if audio_stream_player.playing:
		play_button.modulate = Color(1, 1, 1)
		audio_stream_player.stream_paused = true
	else:
		play_button.modulate = Color(0.3, 1, 0.1)
		audio_stream_player.play(song.current_song_time + Global.calibration_seconds)
		song.sync_song_time(audio_stream_player.get_playback_position())
