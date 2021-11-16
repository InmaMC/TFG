extends ColorRect

var origin : Vector2 = Vector2.ZERO
var light_dir : Vector3 = Vector3.DOWN
var radius : float

var yaw : float = 0
var pitch : float = 0
var pressed : bool = false

func _ready() -> void:
	update_light_dir()
	update_origin()
	pass # Replace with function body.

func update_origin():
	origin = get_rect().size*0.5;
	radius = min(origin.x, origin.y)
	(material as ShaderMaterial).set_shader_param("Origin", origin)

func update_light_dir():
	light_dir = Vector3.FORWARD.rotated(Vector3.UP, yaw).rotated(Vector3.RIGHT, pitch)
	(material as ShaderMaterial).set_shader_param("Light", light_dir)

func _on_BallLight_gui_input(event: InputEvent) -> void:
#	print(event)
#	print(pressed)
	pressed = pressed and Input.is_mouse_button_pressed(BUTTON_LEFT)
	if event is InputEventMouseMotion and pressed:
		yaw += 0.5*PI*event.relative.x/radius
		pitch += 0.5*PI*event.relative.y/radius
		yaw = wrapf(yaw, -PI, PI)
		pitch = clamp(pitch, -PI*0.5, PI*0.5)
#		print(yaw, " ", pitch)
		update_light_dir()
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		pressed = true
	pass # Replace with function body.


func _on_BallLight_resized() -> void:
	update_origin()
	pass # Replace with function body.
