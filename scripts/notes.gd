extends Node2D

@onready var highway = get_parent()

func update_positions():
	for note in get_children():
		note.update_position()

func set_sprites():
	for note in get_children():
		note.set_sprite()
