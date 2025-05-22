class_name Game extends Node

@onready var current_scene = $CurrentScene

var node_count : int = 0

func _init():
	Global.store_gem_textures_in_list()
	
	Global.drum_kit = Utils.load_json_file(Directory.DRUM_KIT_PATH)
	Global.profiles_list = Utils.load_json_file(Directory.PROFILES_PATH)
	
	if !Global.drum_kit.has("Lanes"):
		Global.drum_kit["Lanes"] = 6
		Utils.save_json_file(Directory.DRUM_KIT_PATH, Global.drum_kit)

func get_node_count():
	return Utils.count_all_nodes(self)
	
func set_scene(file_name):
	for child in current_scene.get_children():
		child.queue_free()
	var scene = load("res://scenes/" + file_name + ".tscn").instantiate()
	current_scene.add_child(scene)
	return scene

#func _process(_delta):
	#var current_node_count = get_node_count()
	#if current_node_count != node_count:
		#node_count = current_node_count
		#print("NODE COUNT: " + str(node_count)) #SLOW!
		
func _ready():
	Global.game = self
	
	set_scene("main_menu")
