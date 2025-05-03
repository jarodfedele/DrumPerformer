extends Polygon2D

@onready var highway = get_parent()

func generate_uvs(points: PackedVector2Array) -> PackedVector2Array:
	var min_y = points[0].y
	var max_y = points[0].y
	for p in points:
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var height = max_y - min_y
	var uvs = PackedVector2Array()
	for p in points:
		var u = 0.5  # Optional: center of gradient
		var v = (p.y - min_y) / height if height != 0 else 0.0
		uvs.append(Vector2(u, v))
	return uvs
	
func _ready():
	# Load shader from file
	var shader = load("res://shaders/highway_cover.gdshader")

	# Create a ShaderMaterial and assign the shader to it
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader

	# Assign it to this Polygon2D
	self.material = shader_material
	
	# Dummy texture (only way the gradient works?)
	var image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 1))
	var dummy_texture = ImageTexture.create_from_image(image)
	self.texture = dummy_texture
		
	var border_points = highway.get_fade_points()

	polygon = border_points
	uv = generate_uvs(border_points) # <- Add this!
