extends Node2D

@onready var song = get_node("/root/Game/Song")
	
func _ready():
	#test song
	song.load_song("res://test_song/")
