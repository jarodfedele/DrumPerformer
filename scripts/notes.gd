extends Node2D

@onready var highway = get_parent()

const NoteScene = preload("res://scenes/note.tscn")
const Utils = preload("res://scripts/utils.gd")

func _ready():
	spawn_notes()

func set_note_configs():
	for child in get_children():
		child.queue_free()

	# Create new notes
	for data in highway.note_data:
		var note = NoteScene.instantiate()
		
		note.time = data[0]
		var gem = data[1]
		note.gem = gem
		note.color_r = data[2]
		note.color_g = data[3]
		note.color_b = data[4]
		note.lane_start = data[5]
		note.lane_end = data[6]
		note.velocity = data[7]
		note.gem_path = Global.GEMS_PATH + note.gem + "/"
		note.original_gem_path = Global.ORIGINAL_GEMS_PATH + note.gem + "/"
		
		var positioning_shift_x = highway.get_gem_config_setting(gem, "shiftx")
		if positioning_shift_x:
			note.positioning_shift_x = positioning_shift_x
		var positioning_shift_y = highway.get_gem_config_setting(gem, "shifty")
		if positioning_shift_y:
			note.positioning_shift_y = positioning_shift_y
		var positioning_scale = highway.get_gem_config_setting(gem, "scale")
		if positioning_scale:
			note.positioning_scale = positioning_scale
		var blend_tint = highway.get_gem_config_setting(gem, "blend_tint")
		if blend_tint:
			note.blend_tint = blend_tint
		var blend_lighting = highway.get_gem_config_setting(gem, "blend_lighting")
		if blend_lighting:
			note.blend_lighting = blend_lighting
		var z_order = highway.get_gem_config_setting(gem, "zorder")
		if z_order:
			note.z_index = z_order
		var color_r = highway.get_gem_config_setting(gem, "color_r")
		if color_r:
			note.color_r = color_r
		var color_g = highway.get_gem_config_setting(gem, "color_g")
		if color_g:
			note.color_b = color_g
		var color_b = highway.get_gem_config_setting(gem, "color_b")
		if color_b:
			note.color_b = color_b
		var color_a = highway.get_gem_config_setting(gem, "alpha")
		if color_a:
			note.color_a = color_a

		add_child(note)
		
func spawn_notes():
	set_note_configs()

func update_positions():
	for child in get_children():
		child.update_position()

func update_sprites():
	for child in get_children():
		child.update_sprites()

func update_textures():
	highway.store_gem_textures_in_list()
	for child in get_children():
		child.update_textures()

func set_gem_property(gem, header, val):
	if not Global.debug_update_notes:
		return
		
	var file_path = Global.get_gem_config_file_path(gem)
	var config_text = Utils.read_text_file(file_path)
	var lines = config_text.split("\n")
	var found_header = false
	var line_to_add = header + " " + str(val)
	for i in range(lines.size()):
		var line = lines[i]
		if line.substr(0, header.length()+1) == header + " ":
			found_header = true
			lines[i] = line_to_add
			break
	if not found_header:
		lines.append(line_to_add)
		
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		for line in lines:
			if line.strip_edges() != "":
				file.store_line(line)
		file.close()
	
	update_textures()
	spawn_notes()
