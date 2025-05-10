extends Node

# In scene_manager.gd (autoload singleton)
var main_menu
var song_select_menu
var song
var drum_kit_editor
var profile_editor

var scene_list

func init(game_node):
	main_menu = game_node.get_node("MainMenu")
	song_select_menu = game_node.get_node("SongSelectMenu")
	song = game_node.get_node("Song")
	drum_kit_editor = game_node.get_node("DrumKitEditor")
	profile_editor = game_node.get_node("ProfileEditor")
	
	scene_list = [
	main_menu, 
	song_select_menu, 
	song,
	drum_kit_editor, 
	profile_editor
	]
	
func set_scene(scene_name):
	print("---------")
	for scene in scene_list:
		if scene.get_name() == scene_name:
			scene.update_contents()
			scene.visible = true
			Global.set_process_recursive(scene, true)
			print("ON: " + scene.get_name())
		else:
			scene.visible = false
			Global.set_process_recursive(scene, false)
			print("OFF: " + scene.get_name())
