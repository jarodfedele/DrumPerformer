extends Polygon2D

func _draw():
	var points = [
		Vector2(Global.NOTATION_XMIN, Global.NOTATION_YMIN),
		Vector2(Global.NOTATION_XMAX, Global.NOTATION_YMIN),
		Vector2(Global.NOTATION_XMAX, Global.NOTATION_YMAX),
		Vector2(Global.NOTATION_XMIN, Global.NOTATION_YMAX)
	]
	draw_polygon(points, [Global.STAFF_BACKGROUND_COLOR])
