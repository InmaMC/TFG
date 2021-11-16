extends MeshInstance



func _ready() -> void:
	pass 



# cuando se recibe la señal de que el mesh principal ha sido cambiado, aquí también cambia
func _on_MeshPrincipal_mesh_changed(_mesh) -> void:
	self.mesh = _mesh
