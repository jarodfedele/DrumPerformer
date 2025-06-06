extends Node2D

@onready var base_path = $PanelContainer/VBoxContainer

@onready var drum_kit_editor_button = base_path.get_node("DrumKitEditorButton")
#@onready var profile_editor_button = base_path.get_node("ProfileEditorButton")
@onready var load_song_panorama_button = base_path.get_node("LoadSongPanoramaButton")
@onready var load_song_page_button = base_path.get_node("LoadSongPageButton")
#@onready var modify_art_button = base_path.get_node("ModifyArtButton")

#TODO: tom order, and indicate on editor

func update_contents():
	pass
	
func _ready():
	drum_kit_editor_button.pressed.connect(_on_drum_kit_editor_button_pressed)
	#profile_editor_button.pressed.connect(_on_profile_editor_button_pressed)
	load_song_panorama_button.pressed.connect(_on_load_song_panorama_button_pressed)
	load_song_page_button.pressed.connect(_on_load_song_page_button_pressed)
	#modify_art_button.pressed.connect(_on_modify_art_editor_button_pressed)
	
	refresh_button_visibilities()
	
func _on_drum_kit_editor_button_pressed():
	Global.game.set_scene("drum_kit_editor")
func _on_profile_editor_button_pressed():
	Global.game.set_scene("profile_editor")
func _on_load_song_panorama_button_pressed():
	var scene = Global.game.set_scene("song")
	scene.load_song("res://test_song/", true)
func _on_load_song_page_button_pressed():
	var scene = Global.game.set_scene("song")
	scene.load_song("res://test_song/", false)
	
func refresh_button_visibilities():
	load_song_panorama_button.visible = Global.drum_kit["Valid"]
	load_song_page_button.visible = Global.drum_kit["Valid"]
	
func _on_main_menu_scene_set():
	refresh_button_visibilities()
