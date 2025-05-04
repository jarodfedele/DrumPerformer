extends Node2D

func update_positions():
	for child in get_children():
		child.update_position()
