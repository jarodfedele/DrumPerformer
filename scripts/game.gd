extends Node2D

@onready var song = $Song

@onready var drum_kit_editor_highway = $DrumKitEditor/Highway

func _init():
	Global.store_gem_textures_in_list()
	
	Global.drum_kit = Utils.load_json_file(Directory.DRUM_KIT_PATH)
	Global.profiles_list = Utils.load_json_file(Directory.PROFILES_PATH)
	
	if !Global.drum_kit.has("Lanes"):
		Global.drum_kit["Lanes"] = 6
		Utils.save_json_file(Directory.DRUM_KIT_PATH, Global.drum_kit)

func _ready():
	drum_kit_editor_highway.num_lanes = Global.drum_kit["Lanes"]
	drum_kit_editor_highway.refresh_boundaries(false)
		
	SceneManager.init(self)
	SceneManager.set_scene("MainMenu")
	
	await get_tree().process_frame
	print("NODE COUNT: " + str(Utils.count_all_nodes(self)))
