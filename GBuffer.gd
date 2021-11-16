extends Resource

# Clase G-Buffer
class_name GBuffer

# imagen original del modelo
export var color : Image

# imagen del mapa de la curvatura del modelo
export var curvature : Image

export var normal : Image

export var depth : Image

export var edge : Image

export var dist_edge : Image

# Debug - guardar las imagenes como png	
func save_as_png():
	color.save_png("res://.temp/color.png")
	curvature.save_png("res://.temp/curvature.png")
	normal.save_png("res://.temp/normal.png")
	depth.save_png("res://.temp/depth.png")
	edge.save_png("res://.temp/edge.png")
	dist_edge.save_png("res://.temp/dist_edge.png")
	
func lock():
	color.lock()
	curvature.lock()
	normal.lock()
	depth.lock()
	edge.lock()
	dist_edge.lock()

	

func unlock():
	color.unlock()
	curvature.unlock()
	normal.unlock()
	depth.unlock()
	edge.unlock()
	dist_edge.unlock()
