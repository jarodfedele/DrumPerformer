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

var volume_per_pixel_l
var volume_per_pixel_r

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
	
	#var rms_data = get_rms_data(instance.audio_stream_player, instance.x_size)
	#instance.volume_per_pixel_l = rms_data[0]
	#instance.volume_per_pixel_r = rms_data[1]
	
	return instance

static func get_rms_data(audio_stream_player, x_size):
	var stream = audio_stream_player.stream
	
	var sample_data = stream.data
	var sample_rate = stream.mix_rate
	if !stream.stereo:
		assert(false, "Audio file not stereo!")
	if stream.format != 1:
		assert(false, "Audio file not imported with correct format! (format = " + str(stream.format) + ")")
	
	const NUM_CHANNELS = 2
	var left = []
	var right = []
	
	var max_sample_l = 0
	var max_sample_r = 0
	var sample_resolution = 255.0

	#####
	
	var samples_per_pixel = sample_rate * NUM_CHANNELS
	var volume_per_pixel_l = []
	var volume_per_pixel_r = []
	var num_pixels = x_size
	
	var max_l = 0
	var max_r = 0
	
	for pixel in range(num_pixels):
		var start = int(pixel * samples_per_pixel)
		var end = int((pixel + 1) * samples_per_pixel)
		if end > sample_data.size():
			end = sample_data.size()

		var sum_l := 0.0
		var sum_r := 0.0
			
		for i in range(start, end, NUM_CHANNELS):
			var l = sample_data[i] / sample_resolution
			var r = sample_data[i + 1] / sample_resolution
			left.append(l)
			right.append(r)
			sum_l += l * l
			sum_r += r * r
			
			#max_l = max(max_l, l)
			#max_r = max(max_r, r)
			
		var rms_l = sqrt(sum_l / max(1, (end - start)))
		var rms_r = sqrt(sum_r / max(1, (end - start)))
		volume_per_pixel_l.append(rms_l)
		volume_per_pixel_r.append(rms_r)
	
	return [volume_per_pixel_l, volume_per_pixel_r]
	
func layout_children():
	waveform_button.position = Vector2(x_min, y_min)
	waveform_button.size = Vector2(x_size, y_size)
	
	var play_button_x_min = x_max+10
	
	play_button.position = Vector2(play_button_x_min, y_min)
	play_button.size = Vector2(y_size, y_size)
	
	timecode.position = Vector2(play_button_x_min, y_max+20)
	
func _ready():
	layout_children()
	var tex = load(Global.current_song_path + "waveform.png")
	waveform_button.texture_normal = tex
	
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
