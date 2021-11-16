extends Spatial



# Porcentaje de pantalla que movera la cámara cuando el ratón esté sobre ella
const screen_amount = 0.1;

# Valocidad de la cámara
export var max_move_speed := 1.0
export var max_accel := 2.0
export var sensitivity := 0.01
# Guarda la velocidad de la cámara
var velocity := Vector3()

var yaw := 0.0
var pitch := 0.0
# Rotacion inicial de la cámara
var initial_rotation := rotation.y



# cuando se captura el ratón, se rota la cámara con él 
func _input(event):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			yaw -= event.relative.x*sensitivity
			yaw = wrapf(yaw, -PI, PI)
			pitch -= event.relative.y*sensitivity
			pitch = clamp(pitch, -PI*0.5, PI*0.5)

func _process(delta: float) -> void:
	max_move_speed = GlobalConfig.cam_speed
	max_accel = max_move_speed * 2
	
	var target_velocity := Vector3.ZERO
	target_velocity.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	target_velocity.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	target_velocity.y = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	target_velocity = target_velocity.normalized()*min(target_velocity.length(), 1.0)*max_move_speed
	target_velocity = target_velocity.rotated(Vector3.UP, yaw)
	
	var delta_velocity = target_velocity - velocity
	delta_velocity = delta_velocity.normalized()*min(max_accel*delta, delta_velocity.length())
	velocity += delta_velocity
	global_transform.origin += velocity*delta 
	rotation.y = yaw
	rotation.x = pitch


#func _exit_tree() -> void:
#	# Restore the mouse cursor upon quitting
#	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
