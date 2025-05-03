extends Node2D

@onready var highway = get_parent()

const BeatLineScene = preload("res://scenes/beatline.tscn")

const Utils = preload("res://scripts/utils.gd")

func _ready():
	spawn_beatlines()

func spawn_beatlines():
	# Clean up old notes
	for child in get_children():
		child.queue_free()

	# Create new notes
	for data in highway.beatline_data:
		var beatline = BeatLineScene.instantiate()
		
		beatline.time = data[0]
		beatline.color_r = data[1]
		beatline.color_g = data[2]
		beatline.color_b = data[3]
		beatline.thickness = data[4]

		add_child(beatline)

func update_positions():
	for child in get_children():
		child.update_position()
