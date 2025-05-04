extends Node2D

@onready var highway = $Highway

@onready var sprite = $NotationSprite
@onready var line = $NotationLine
@onready var rect = $NotationRect
@onready var circle = $NotationCircle
@onready var measure_number = $NotationMeasureNumber
@onready var staff = get_parent().get_parent()

var category : String
var time
var file_name
var xMin : float #need these coordinates for all types because of paging
var yMin : float
var xMax : float
var yMax : float
