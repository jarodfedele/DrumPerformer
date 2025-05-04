extends FileDialog

@onready var song = get_node("/root/Game/Song")
@onready var gem_selector = $"../GemSelector"
@onready var reload_gems_button = $"../ReloadGemsButton"

func _ready():
	dir_selected.connect(_on_dir_selected)
	
func _on_dir_selected(path):
	Global.GEMS_PATH = path + "/"
	Global.DEBUG_GEMS = true
	gem_selector.visible = true
	reload_gems_button.visible = true
	
	song.load_song(Global.current_song_path)
