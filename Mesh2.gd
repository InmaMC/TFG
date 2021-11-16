extends MeshInstance

export var curvature_multiplier = 1.0


func _ready() -> void:
	pass 


func compute_curvature():
	var arrays = mesh.surface_get_arrays(0)    #cantidad de caras del mesh
	var vertices = PoolVector3Array(arrays[Mesh.ARRAY_VERTEX])   # array de vértices
	var normals = PoolVector3Array(arrays[Mesh.ARRAY_NORMAL])    # array de normales
	var indices = PoolIntArray(arrays[Mesh.ARRAY_INDEX])         # array de indices
	var colors = PoolColorArray()    # array de color del tamaño del de vértices
	colors.resize(vertices.size())   
	
	var edges : Array = Array()      # array de edges del tamaño del de vértices
	edges.resize(vertices.size())
	for i in edges.size():
		# convertirlo en matriz
		edges[i] = Array()
	
	# crear la matriz de edges que tiene cada indice
	for i in indices.size()/3:   # cada 3 porque trabajamos con triángulos
		if not edges[indices[3*i]].has(indices[3*i + 1]):
			edges[indices[3*i]].push_back(indices[3*i + 1])
		if not edges[indices[3*i + 1]].has(indices[3*i]):
			edges[indices[3*i + 1]].push_back(indices[3*i])
		
		if not edges[indices[3*i]].has(indices[3*i + 2]):
			edges[indices[3*i]].push_back(indices[3*i + 2])
		if not edges[indices[3*i + 2]].has(indices[3*i]):
			edges[indices[3*i + 2]].push_back(indices[3*i])
		
		if not edges[indices[3*i + 1]].has(indices[3*i + 2]):
			edges[indices[3*i + 1]].push_back(indices[3*i + 2])
		if not edges[indices[3*i + 2]].has(indices[3*i + 1]):
			edges[indices[3*i + 2]].push_back(indices[3*i + 1])
	
	# recorrer matriz
	for a in edges.size():
		var curvature = 0.0;   # reiniciar curvatura
		for b in edges[a]:     # para cada edge de cada indice
			# dot =  dot product
			# curvatura = normal del indice por la resta de la normal del edge menos la normal del indice
			curvature += normals[a].normalized().dot((vertices[b] - vertices[a]).normalized())
		curvature /= edges[a].size()   # se divide por el todal de edges que tiene, se normaliza
		colors[a] = Color(curvature*curvature_multiplier + 0.5, 0, 0)    # determinar el color según la curvatura, 0.5 se añade para no tener valores negativos
	
	# crear el mesh con el mapa de la curvatura
	self.mesh = ArrayMesh.new()
	arrays[Mesh.ARRAY_COLOR] = colors
	(self.mesh as ArrayMesh).add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


# cuando se recibe la señal de que el mesh principal ha sido cambiado, aquí también cambia
func _on_MeshPrincipal_mesh_changed(_mesh) -> void:
	self.mesh = _mesh
	compute_curvature()
