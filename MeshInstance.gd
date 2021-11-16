extends MeshInstance

signal mesh_changed(mesh)


var loadedFile:File = File.new()
var elements:Array

var vertex_count
var v_prop_count = 0
var vertex_prop:Array
var vertex_type:Array
#var vertex = []

var faces_count
var faces_prop:Array
var faces_type:Array
#var indexs = []

#class Edges:
#	var count:int
#	var prop:Array
#	var type:Array
#
#class Materials:
#	var count:int
#	var prop:Array
#	var type:Array


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func create_mesh(filePath:String):

		# abrir y comprobar que el archivo funciona
		var err = loadedFile.open(filePath, File.READ)
		if err != OK:
			return err
		
		# variables auxiliares
		var line = ""
		var data = ""
		
		
		# crear el SurfaceTool para formar la geometría
		var meshBuilder = SurfaceTool.new()
		meshBuilder.begin(Mesh.PRIMITIVE_TRIANGLES)
		meshBuilder.add_smooth_group(true)
		# lectura del header #### TODO: BUSCAR NORMALS, UV (s,t)#########
		#######################################
		var inicio = true
		while line != "end_header":
			if(inicio):
				line = loadedFile.get_line()
				data = line.split(" ")
				# comprobación del formato ascii
				if data[0] == "format":
					if data[1] != "ascii":
						print("Solo se admiten ficheros en formato ascii")
						return err
			
			# lectura elementos
			if data[0] == "element":
				inicio = false
				match data[1]:
					"vertex":
						elements.append("vertex")
						vertex_count = int(data[2])
						line = loadedFile.get_line()
						data = line.split(" ")
						while data[0] != "element":						
							if data[0] == "property":
								vertex_type.append(data[1])
								vertex_prop.append(data[2])
								v_prop_count += 1
							
							line = loadedFile.get_line()
							data = line.split(" ")
							if line == "end_header":
								break
					"face":
						elements.append("faces")
						faces_count = int(data[2])
						line = loadedFile.get_line()
						data = line.split(" ")
						while data[0] != "element":						
							if data[0] == "property":
								faces_type.append(data[1])
								if data[1] == "list":
									faces_type.append(data[2])
									faces_type.append(data[3])
									faces_prop.append(data[4])
								else:
									faces_prop.append(data[2])
							
							line = loadedFile.get_line()
							data = line.split(" ")
							
							if line == "end_header":
								break
#					"edge":
#						elements.append("edges")
#						Edges.count = int(data[2])
#						pass
#					"material":
#						elements.append("materials")
#						Materials.count = int(data[2])
#						pass
		
		
		# lectura de datos
		var count:int = 0
		while not loadedFile.eof_reached():
			if count == 0:
				line = loadedFile.get_line()
				if line == "":
					break
				data = line.split(" ")
			
			match elements[count]:
				"vertex":
					for i in range(vertex_count):
						#meshBuilder.add_normal(Vector3.UP)
						meshBuilder.add_vertex(Vector3(float(data[0]),
											float(data[1]),
											float(data[2])))
											
						# include normals and uv
#						if v_prop_count == 6:
#							meshBuilder.add_normal(Vector3(float(data[3]),
#											float(data[4]),
#											float(data[5])))
#							meshBuilder.add_uv(Vector2(float(data[6]), float(data[7])))
						
						line = loadedFile.get_line()
						if line == "":
							break
						data = line.split(" ")
					count = count + 1
				
				"faces":
#					for i in range(faces_count):
#						if int(data[0]) == 3:
#							meshBuilder.add_index(int(data[1]))
#							meshBuilder.add_index(int(data[2]))
#							meshBuilder.add_index(int(data[3]))
#						if int(data[0]) == 4:
#							meshBuilder.add_index(int(data[1]))
#							meshBuilder.add_index(int(data[2]))
#							meshBuilder.add_index(int(data[3]))
#
#							meshBuilder.add_index(int(data[1]))
#							meshBuilder.add_index(int(data[3]))
#							meshBuilder.add_index(int(data[4]))
#						line = loadedFile.get_line()
#						if line == "":
#							break
#						data = line.split(" ")
#

					for i in range(faces_count):
						if int(data[0]) == 0:
							pass
						elif int(data[0]) < 3:
							for j in range(1,int(data[0])):
								meshBuilder.add_index(int(data[j]))
						else:
							for j in range(1,int(data[0])-1):
								meshBuilder.add_index(int(data[j+1]))
								meshBuilder.add_index(int(data[1]))
								meshBuilder.add_index(int(data[j+2]))
						line = loadedFile.get_line()
						if line == "":
							break
						data = line.split(" ")
					
					count = count + 1

#
#		var result_mesh = Mesh.new();
		meshBuilder.generate_normals()
		var result_mesh = meshBuilder.commit()
		self.mesh = result_mesh;
		emit_signal("mesh_changed", self.mesh)    # señal de que el mesh ha sido cambiado
		var col = CollisionShape.new()
		col.set_shape(self.mesh.create_trimesh_shape())
		add_child(col)
		loadedFile.close()
		
		var aabb = self.mesh.get_aabb()
		var aabb_center : Vector3 = Vector3.ZERO
		var aabb_position = aabb.position
		aabb_center = aabb_position + aabb.size/(2)
#		aabb_center.x = aabb.size.x / 2
#		aabb_center.y = aabb.size.y / 2
#		aabb_center.z = aabb.size.z / 2
#		global_transform.origin
#		transform.origin
		if aabb.get_longest_axis_size() != 0:
			self.scale = Vector3(5/aabb.get_longest_axis_size(), 5/aabb.get_longest_axis_size(), 5/aabb.get_longest_axis_size())
		self.translation = -(aabb_center*self.scale)
		
		#self.get_position_in_parent()
		
