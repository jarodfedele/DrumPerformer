extends Node2D

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
var beam_integers : Array
var node_type: String

func get_child_node():
	var children = get_children()
	if children.size() == 0:
		return
	return children[0]
