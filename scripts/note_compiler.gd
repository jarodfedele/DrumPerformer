extends Node

func test(highway):
	return [[], [], []]
	
func run(highway):
	var lua := LuaState.new()
	lua.open_libraries()
	
	var drumkit_data = "lanes=" + str(int(Global.drum_kit["Lanes"]))
	var pad_list = Global.drum_kit["Pads"]
	
	for pad_index in range(pad_list.size()):
		var pad = pad_list[pad_index]
		var pad_type = pad["Type"]
		drumkit_data += "\n" + "type=" + pad_type
		if pad.has("Position"):
			var pad_position = pad["Position"]
			drumkit_data += " position=" + str(pad_position)
			if pad_type == "octoban" or pad_type == "racktom" or pad_type == "floortom":
				var pad_order = pad["Order"]	
				drumkit_data += " order=" + str(pad_order)
	
	print(drumkit_data)

	#########################################
	
	var gem_name_table = lua.create_table()
	var config_text_table = lua.create_table()
	for x in range(Global.gem_texture_list.size()):
		var gem = Global.gem_texture_list[x][0]
		var config_text = Utils.load_text_file(Global.GEMS_PATH + gem + "/config.txt")
		gem_name_table.set(x+1, gem)
		config_text_table.set(x+1, config_text)
		
	lua.open_libraries()

	var globals = lua.get_globals()
	globals["gamedataFileText"] = Global.current_gamedata
	globals["drumkitFileText"] = drumkit_data
	globals["gemNameTable"] = gem_name_table
	globals["configTextTable"] = config_text_table
	var globalized_file_path = ProjectSettings.globalize_path(Directory.OUTPUT_TEXT_FILE_PATH)
	globals["outputTextFilePath"] = globalized_file_path
	
	var lua_code = Utils.load_text_file("res://note_compiler.lua")
	lua.do_string(lua_code)
	var run_compiler = lua.globals.get("runCompiler")
	run_compiler.invoke(Global.current_gamedata, drumkit_data, gem_name_table, config_text_table, globalized_file_path)

	const NUM_CONSTANTS = 1
	const NUM_ARRAYS = 19
	var num_lanes
	
	var time_list = []
	var velocity_list = []
	var position_list = []
	var gem_list = []
	var color_r_list = []
	var color_g_list = []
	var color_b_list = []
	var color_a_list = []
	var notation_color_r_list = []
	var notation_color_g_list = []
	var notation_color_b_list = []
	var shift_x_list = []
	var shift_y_list = []
	var scale_list = []
	var z_index_list = []
	var pad_index_list = []
	var sustain_line_list = []
	var pedal_list = []
	var midi_id_list = []
	
	var file = FileAccess.open(Directory.OUTPUT_TEXT_FILE_PATH, FileAccess.READ)
	if file:
		var line_id = 0
		while not file.eof_reached():
			var line = file.get_line()
			if line.is_valid_float():
				line = float(line)
			if line_id == 0:
				num_lanes = int(line)
			#ATTENTION: if adding new constant, update NUM_CONSTANTS!
			else:
				var array_id = (line_id - NUM_CONSTANTS) % NUM_ARRAYS
				var arr
				
				if array_id == 0:
					arr = time_list
				if array_id == 1:
					arr = velocity_list
				if array_id == 2:
					arr = position_list
				if array_id == 3:
					arr = gem_list
				if array_id == 4:
					arr = color_r_list
				if array_id == 5:
					arr = color_g_list
				if array_id == 6:
					arr = color_b_list
				if array_id == 7:
					arr = color_a_list
				if array_id == 8:
					arr = notation_color_r_list
				if array_id == 9:
					arr = notation_color_g_list
				if array_id == 10:
					arr = notation_color_b_list
				if array_id == 11:
					arr = shift_x_list
				if array_id == 12:
					arr = shift_y_list
				if array_id == 13:
					arr = scale_list
				if array_id == 14:
					arr = z_index_list
				if array_id == 15:
					arr = pad_index_list
				if array_id == 16:
					arr = sustain_line_list
				if array_id == 17:
					arr = pedal_list
				if array_id == 18:
					arr = midi_id_list
				#ATTENTION: if adding new array, update NUM_ARRAYS!
				
				arr.append(line)
			line_id += 1
		file.close()
	
	var hihat_pedal_values = []
	var gamedata_lines = Global.current_gamedata.split("\n")
	var current_section = null
	for line in gamedata_lines:
		line = line.strip_edges()
		var values = Utils.separate_string(line)
		
		if values.size() == 1:
			current_section = line
		elif values.size() != 0:
			if current_section == "HIHAT_PEDALS":
				var hihat_cc = int(Global.get_value_from_key(line, "cc"))
				hihat_pedal_values.append([hihat_cc, []])
				for i in range(1, values.size(), 3):
					var time = values[i]
					var cc_val = values[i+1]
					var gradient_int = int(values[i+2])
					
					#var alpha = Utils.convert_range(cc_val, 127, 0, 0, Global.MAX_HHPEDAL_ALPHA)/255.0
					var is_gradient = (gradient_int == 1)
					
					var point_data = [time, cc_val, is_gradient]
					hihat_pedal_values[hihat_pedal_values.size()-1][1].append(point_data)
	
	var note_data = []
	var sustain_data = []
	var hihatpedal_data = []
	var hihat_cc_global_data = []
	
	for x in range(time_list.size()):
		var time = time_list[x]
		var gem = gem_list[x]
		var position = position_list[x]
		var color_r = color_r_list[x]
		var color_g = color_g_list[x]
		var color_b = color_b_list[x]
		var pad_index = pad_index_list[x]
		var velocity = velocity_list[x]
		var sustain_line = sustain_line_list[x]
		var pedal_cc = pedal_list[x]
		var midi_id = midi_id_list[x]
		
		var pedal_val = -1
		if pedal_cc != -1 and !gem.ends_with("_pedal"):
			var found_global_data = false
			for data in hihat_cc_global_data:
				if data[0] == pedal_cc:
					found_global_data = true
			if !found_global_data:
				hihat_cc_global_data.append([pedal_cc, [position, color_r, color_g, color_b]])
				
			for hihat_data in hihat_pedal_values:
				if hihat_data[0] == pedal_cc:
					var values = hihat_data[1]
					var index = Utils.binary_search_closest_or_less(values, time, 0)
					if not index:
						print("BAD NO HHPEDAL INDEX! " + str(time))
					
					var pedal_time_start = values[index][0]
					var pedal_val_start = values[index][1]
					var is_gradient = values[index][2]
					#print(str(pedal_time_start) + " " + str(pedal_val_start) + " " + str(is_gradient))
					if index < values.size() and is_gradient:
						var pedal_time_end = values[index+1][0]
						var pedal_val_end = values[index+1][1]
						pedal_val = Utils.convert_range(time, pedal_time_start, pedal_time_end, pedal_val_start, pedal_val_end)
					else:
						pedal_val = pedal_val_start
					pedal_val = int(clamp(pedal_val, 0.0, 127.0))
						
		note_data.append([time, gem, position, pad_index, velocity, pedal_val, midi_id])
		
		if sustain_line is String:
			var sustain_type = Global.get_value_from_key(sustain_line, "type")
			var lane_data = [position, color_r, color_g, color_b, sustain_type, []]

			var values = Utils.separate_string(sustain_line)
			for i in range(3, values.size(), 3):
				var sustain_time = values[i]
				var cc_val = values[i+1]
				var gradient_int = values[i+2]
				
				var percentage = Utils.get_sustain_size_percentage(cc_val)
				var is_gradient = (gradient_int == 1)
				
				var point_data = [sustain_time, percentage, is_gradient]
				lane_data[5].append(point_data)
			
			sustain_data.append(lane_data)
	
	for hihat_data in hihat_pedal_values:
		#send hihat_pedal_data to highway
		var hihat_cc = hihat_data[0]
		var values = hihat_data[1]
		for point_data in values:
			var cc_val = point_data[1]
			var alpha = Utils.convert_range(cc_val, 0, 127, 0, Global.MAX_HHPEDAL_ALPHA)/255.0
			point_data[1] = alpha
		for global_data in hihat_cc_global_data:
			if global_data[0] == hihat_cc:
				var data = global_data[1]
				var position = data[0]
				var color_r = data[1]
				var color_g = data[2]
				var color_b = data[3]
				hihatpedal_data.append([position, color_r, color_g, color_b, values])
				break
	
	return [note_data, sustain_data, hihatpedal_data]
	
func _ready():
	pass
