extends Node2D

@onready var song = $Song

func _ready():
	Global.store_gem_textures_in_list()
	
	Global.drum_kit = Utils.load_json_file(Global.drum_kit_path)
	Global.profiles_list = Utils.load_json_file(Global.profiles_path)
	
	SceneManager.init(self)
	SceneManager.set_scene("MainMenu")
	
	await get_tree().process_frame
	print("NODE COUNT: " + str(Utils.count_all_nodes(self)))
