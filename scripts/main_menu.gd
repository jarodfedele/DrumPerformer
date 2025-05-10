extends Node2D

@onready var base_path = $PanelContainer/VBoxContainer

@onready var drum_kit_editor_button = base_path.get_node("DrumKitEditorButton")
@onready var profile_editor_button = base_path.get_node("ProfileEditorButton")
@onready var load_song_button = base_path.get_node("LoadSongButton")
@onready var modify_art_button = base_path.get_node("ModifyArtButton")

func update_contents():
	pass
	
func _ready():
	drum_kit_editor_button.pressed.connect(_on_drum_kit_editor_button_pressed)
	profile_editor_button.pressed.connect(_on_profile_editor_button_pressed)
	load_song_button.pressed.connect(_on_load_song_editor_button_pressed)
	modify_art_button.pressed.connect(_on_modify_art_editor_button_pressed)

func _on_drum_kit_editor_button_pressed():
	SceneManager.set_scene("DrumKitEditor")
func _on_profile_editor_button_pressed():
	SceneManager.set_scene("ProfileEditor")
func _on_load_song_editor_button_pressed():
	SceneManager.set_scene("Song")
func _on_modify_art_editor_button_pressed():
	SceneManager.set_scene("Song")
