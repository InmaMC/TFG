extends KinematicBody


func initialize(start_position):
	if start_position == null:
		return ("posición erronea")
	else:
		translation = start_position


func _on_Area_input_event(camera, event, click_position, click_normal, shape_idx):
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("click_derecho"):
			queue_free()


func set_rad(tam):
	var esfera = get_node("Spatial/MeshInstance")
	var col = get_node("Area/CollisionShape")
	esfera.set_esf(tam)
	col.set_col(tam)
