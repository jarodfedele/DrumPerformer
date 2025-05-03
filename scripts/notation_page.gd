extends Node2D

signal render_complete(texture: Texture2D)

func take_screenshot(index):
	var viewport := SubViewport.new()
	viewport.size = Vector2(Global.NOTATION_XSIZE*2, Global.NOTATION_YSIZE)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.transparent_bg = true
	add_child(viewport)

	var container := Node2D.new()
	for child in get_children():
		if child != viewport:
			var clone = child.duplicate()
			container.add_child(clone)
	viewport.add_child(container)
	
	await RenderingServer.frame_post_draw
	
	var img = viewport.get_texture().get_image()
	img.save_png("user://test_notation_page_" + str(index) + ".png")

	viewport.queue_free()
	
func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not is_visible_in_tree():
			Global.set_process_recursive(self, false)
		else:
			Global.set_process_recursive(self, true)
