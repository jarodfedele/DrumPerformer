extends Node2D

@onready var highway = $"../../Highway"

const Utils = preload("res://scripts/utils.gd")

func _ready():
	spawn_stafflines()

func spawn_stafflines():
	# Clean up old notes
	for child in get_children():
		child.queue_free()

	# Create new notes
	for yPos in highway.staffline_data:
		var line = Line2D.new()
		line.default_color = Color(0, 0, 0)
		line.width = 2
		line.add_point(Vector2(Global.NOTATION_XMIN, yPos))
		line.add_point(Vector2(Global.NOTATION_XMAX, yPos))

		add_child(line)
