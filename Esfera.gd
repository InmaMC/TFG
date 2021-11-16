extends MeshInstance

var esfera = SphereMesh.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_esf(tam):
	print(tam)
	esfera.set_radius(tam)
	esfera.set_height(tam*2)
	self.mesh = esfera
