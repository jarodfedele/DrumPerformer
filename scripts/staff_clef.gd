extends Sprite2D

const Utils = preload("res://scripts/utils.gd")

func _ready():
	var xMin = Global.STAFF_SPACE_HEIGHT * 2 + Global.NOTATION_XMIN
	var yMin = Global.center_staff_line - Global.STAFF_SPACE_HEIGHT
	var xMax = xMin + 150 #TODO
	var yMax = Global.center_staff_line + Global.STAFF_SPACE_HEIGHT
	
	var xCenter = (xMin + xMax) * 0.5
	var yCenter = (yMin + yMax) * 0.5
	
	var scale_factor = 0.07 #TODO: set programatically
	scale = scale*scale_factor
	position = Vector2(xMin + 10, yCenter)
