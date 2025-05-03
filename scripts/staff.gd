extends Node2D

const Utils = preload("res://scripts/utils.gd")

@onready var highway = $"../Highway"
@onready var notation_pages = $NotationPages

var prev_page_number
var took_screenshots = false

func get_current_notation_xOffset():
	var page_number = get_page_number(true)
	return float(Global.notation_page_list[page_number][0] - Global.NOTATION_XMIN)
			
func get_current_notation_xPos():
	var index = Utils.binary_search_closest_or_less(Global.notation_time_list, highway.current_song_time, 0)
	if index >= Global.notation_time_list.size()-1:
		return
	var current_time_point = Global.notation_time_list[index]
	var next_time_point = Global.notation_time_list[index+1]
	return Utils.convert_range(highway.current_song_time, current_time_point[0], next_time_point[0], current_time_point[1], next_time_point[1]) - get_current_notation_xOffset()

func get_notation_page(page_number):
	if page_number == null or page_number < 0 or page_number >= Global.notation_page_list.size():
		return
	return Global.notation_page_list[page_number][3]
	
func get_page_number(force_valid):
	var page_number
	if not highway:
		page_number = -1
	else:
		page_number = Utils.binary_search_closest_or_less(Global.notation_page_list, highway.current_song_time, 1)
	
	if force_valid:
		page_number = max(page_number, 0)
		page_number = min(page_number, Global.notation_page_list.size())
	return page_number
	
func _physics_process(delta):
	if not took_screenshots and Global.notation_page_list.size() > 0:
		took_screenshots = true
		var children = notation_pages.get_children()
		for i in range(children.size()):
			var notation_page = children[i]
			notation_page.visible = true
			notation_page.take_screenshot(i)
			await get_tree().process_frame
			notation_page.visible = false
	
		#clear junk from each notation page
		for notation_page in notation_pages.get_children():
			for child in notation_page.get_children():
				child.queue_free()	
		await get_tree().process_frame
		
		#add .png texture to each notatio page
		children = notation_pages.get_children()
		for i in range(children.size()):
			var notation_page = children[i]
			var tex_rect = TextureRect.new()
			
			var image = Image.new()
			if image.load("user://test_notation_page_" + str(i) + ".png") == OK:
				var tex = ImageTexture.create_from_image(image)
				tex_rect.texture = tex
			
			tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
			
			tex_rect.position = Vector2(Global.NOTATION_XMIN, Global.NOTATION_YMIN)
			tex_rect.size = Vector2(Global.NOTATION_XSIZE*2, Global.NOTATION_YSIZE) #TODO
			
			tex_rect.visible = true
			notation_page.add_child(tex_rect)
			
		await get_tree().process_frame
		
		get_notation_page(0).visible = true
		
		print("CHILDREN: " + str(notation_pages.get_children().size()))
	
	else:
		var page_number = get_page_number(true)
		if page_number != prev_page_number:
			var current_notation_page = get_notation_page(page_number)
			var prev_notation_page = get_notation_page(prev_page_number)
			if current_notation_page:
				print("CURRENT_PAGE: " + str(page_number))
				current_notation_page.visible = true
			if prev_notation_page:
				print("PREV_PAGE: " + str(page_number))
				prev_notation_page.visible = false
		prev_page_number = page_number
