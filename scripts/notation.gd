class_name Notation extends Node2D

var category : String
var time
var xMin : float #need these coordinates for all types because of paging
var yMin : float
var xMax : float
var yMax : float
var xCenter : float
var yCenter: float
var midi_id: int
var color_r: float
var color_g: float
var color_b: float
var voice_index : int
var has_tie : bool
var beam_integers : Array
var node_type: String
var hairpin_type : String
var bpm_basis_filename : String
var bpm_basis_has_dot : bool
var bpm_value : String
var performance_direction : String
var collision_y_offset : float

func get_child_node():
	var children = get_children()
	if children.size() == 0:
		return
	return children[0]
