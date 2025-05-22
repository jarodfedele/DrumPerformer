class_name Game extends Node

@onready var current_scene = $CurrentScene

func _init():
	Global.store_gem_textures_in_list()
	
	Global.drum_kit = Utils.load_json_file(Directory.DRUM_KIT_PATH)
	Global.profiles_list = Utils.load_json_file(Directory.PROFILES_PATH)
	
	if !Global.drum_kit.has("Lanes"):
		Global.drum_kit["Lanes"] = 6
		Utils.save_json_file(Directory.DRUM_KIT_PATH, Global.drum_kit)

func set_scene(file_name):
	for child in current_scene.get_children():
		child.queue_free()
	var scene = load("res://scenes/" + file_name + ".tscn").instantiate()
	current_scene.add_child(scene)
	return scene
	
func _ready():
	Global.game = self
	
	set_scene("main_menu")
	await get_tree().process_frame
	print("NODE COUNT: " + str(Utils.count_all_nodes(self)))
