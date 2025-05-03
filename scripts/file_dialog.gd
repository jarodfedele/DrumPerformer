extends FileDialog

@onready var gem_selector = $"../GemSelector"
@onready var notes = $"../../Highway/Notes"
@onready var reload_gems_button = $"../ReloadGemsButton"

func _ready():
	dir_selected.connect(_on_dir_selected)
	
func _on_dir_selected(path):
	Global.GEMS_PATH = path + "/"
	Global.DEBUG_GEMS = true
	gem_selector.visible = true
	reload_gems_button.visible = true
	
	notes.update_textures()
	notes.spawn_notes()
	
