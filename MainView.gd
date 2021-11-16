extends TabContainer

# capturar el ratón presionando "esc"
func _unhandled_input(event):
	if not self.is_visible_in_tree():
		return
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event.is_action_pressed("ui_cancel"):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().set_input_as_handled()

var filePath:String

# recibe el archivo PLY e inicia _read_PLY
func _ready():
	get_tree().connect("files_dropped", self, "_read_PLY")
	pass

# si el mainView está visible, inicia la creación del mesh
func _read_PLY(_files:PoolStringArray,screen:int): #->void:
	if self.is_visible_in_tree():
		filePath = _files[0]
		var _mesh =$Color/Viewport/Spatial/MeshPrincipal
		_mesh.create_mesh(filePath)


func _on_Button_pressed() -> void:
	$FileDialog.popup()


func _on_FileDialog_file_selected(path: String) -> void:
	var _files : PoolStringArray
	_files.push_back(path)
	_read_PLY(_files, 1)
