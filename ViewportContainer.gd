extends ViewportContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var viewport = get_child(0) as Viewport

func _gui_input(event : InputEvent):
	var transformed = event.xformed_by(viewport.get_final_transform(), self.rect_global_position)
	viewport.update_worlds()
	viewport.input(transformed)
	if not viewport.is_input_handled():
		viewport.unhandled_input(transformed)
	
