extends AudioStreamPlayer

@onready var highway = $"../../Highway"

func _on_finished() -> void:
	highway.current_song_time = stream.get_length()
	play(highway.current_song_time-0.05)
	stream_paused = true
