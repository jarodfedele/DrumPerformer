extends Polygon2D

func _draw():
	var xMax = Global.NOTATION_DRAW_AREA_XOFFSET+Global.NOTATION_BOUNDARYXMINOFFSET+12
	var points = [
		Vector2(Global.NOTATION_XMIN, Global.NOTATION_YMIN),
		Vector2(xMax, Global.NOTATION_YMIN),
		Vector2(xMax, Global.NOTATION_YMAX),
		Vector2(Global.NOTATION_XMIN, Global.NOTATION_YMAX)
	]
	draw_polygon(points, [Global.STAFF_BACKGROUND_COLOR])
	#draw_polygon(points, [Color(1, 0, 0)])
