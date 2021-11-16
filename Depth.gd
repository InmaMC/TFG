extends MeshInstance



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# cuando se recibe la señal de que el mesh principal ha sido cambiado, aquí también cambia
# when the principal mesh change, this one changes too
func _on_MeshPrincipal_mesh_changed(_mesh) -> void:
	self.mesh = _mesh
