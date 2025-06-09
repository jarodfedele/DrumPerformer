extends Node

const ROOT_DIR = "res://"
const ASSETS_DIR = ROOT_DIR + "assets/"
const SONGS_DIR = ROOT_DIR + "songs/"
const JAM_TRACKS_DIR = ROOT_DIR + "jam_tracks/"
const LESSONS_DIR = ROOT_DIR + "lessons/"
const CHUNKS_DIR = ROOT_DIR + "chunks/"

const NOTE_MAP_TEXT_FILE_PATH = ROOT_DIR + "note_map.txt"

const IMG_SIZES_FILE_PATH = ASSETS_DIR + "sizes.txt"

const CHUNKS_TEXT_FILE_PATH = CHUNKS_DIR + "chunks.txt"

const USER_DIR = "user://"
const CONFIG_DIR = USER_DIR + "config/"

const DRUM_KIT_PATH = CONFIG_DIR + "drum_kit.json"
const PROFILES_PATH = CONFIG_DIR + "profiles.json"
const OUTPUT_TEXT_FILE_PATH = USER_DIR + "output.txt"

const SONG_DATA_FILE_PATH = USER_DIR + "songdata.txt"

func ensure_directories(paths: Array):
	for path in paths:
		var segments = path.replace("user://", "").split("/")
		var cumulative = "user://"
		for segment in segments:
			cumulative += segment + "/"
			var dir = DirAccess.open("user://")
			if dir and not dir.dir_exists(cumulative.replace("user://", "")):
				dir.make_dir(cumulative.replace("user://", ""))

func ensure_json_file(path: String, default_data):
	if not FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(default_data, "\t"))
			file.close()
		
func _init():
	ensure_directories([
		"user://profiles",
		"user://config",
		"user://logs"
	])
	
	var default_drum_kit = {
		"Channels": [0],
		"Input": "",
		"Lanes": 6,
		"Pads": [],
		"Valid": false
	}
	ensure_json_file(DRUM_KIT_PATH, default_drum_kit)
	
	ensure_json_file(PROFILES_PATH, [])
	
