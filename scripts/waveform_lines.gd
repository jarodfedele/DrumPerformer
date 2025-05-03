extends Line2D

const Utils = preload("res://scripts/utils.gd")

#func _ready():
	#var audio_player = $"../AudioStreamPlayer"
	#var stream = audio_player.stream
	#if stream is AudioStreamWAV:
		#var samples = extract_samples(stream.data)
		#var num_pixels = samples.size()
		#var height = Global.AUDIOBAR_YSIZE
		#var waveform_points = []
		#for i in range(num_pixels):
			#var x = Utils.convert_range(float(i), 0, num_pixels-1, Global.AUDIOBAR_XMIN, Global.AUDIOBAR_XMAX)
			#var y = height / 2 - samples[i] * (height / 2)
			#waveform_points.append(Vector2(x, y))
#
		#points = waveform_points  # Set the waveform to be drawn
		
func extract_samples(data: PackedByteArray, stereo := false) -> Array:
	var samples = []
	var sample_count = data.size() / 2  # 2 bytes per sample

	var byte_offset = 0
	while byte_offset < data.size():
		var low = data[byte_offset]
		var high = data[byte_offset + 1]
		var sample = int((high << 8) | low)
		if sample >= 32768:
			sample -= 65536  # convert unsigned to signed
		samples.append(sample / 32768.0)  # normalize to -1.0 to 1.0
		byte_offset += 2 if not stereo else 4  # stereo: skip R channel for mono draw
	return samples
