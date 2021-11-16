extends Area2D

export var color : Color = Color.black

# initialize the bot in the assigned position 
func initialize(start_position):
	if start_position == null:
		return ("posición erronea")
	else:
		position = start_position

# ARREGLAR: no consigo crear un event cuando hay collision con CollisionShape2D
# if the distance of the bot to the mouse is lower than 16 it deletes it
func _unhandled_input(event):
	if event.is_action("click_derecho") and event.is_pressed():
		if get_local_mouse_position().length() < 16:
			queue_free()
			get_viewport().set_input_as_handled()

#func _on_bot_input_event(viewport, event, shape_idx):
#	print("Collision", event)
#	pass # Replace with function body.

#func _on_bot_mouse_entered():
#	print("mouse")
#	pass # Replace with function body.


#func _on_Area2D_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
#	print(event)
#	if event is InputEventMouseButton:
#		if Input.is_action_just_pressed("click_derecho"):
#			queue_free()


# each step of the bot 
func step_bot(render_bots : RenderBots):
	rotation += 1.0*get_process_delta_time()
	self.modulate = render_bots.g_buffer.color.get_pixelv(position)
	for area in get_overlapping_areas():
		if area.is_in_group("Bots"):
			print(area)
	

# toggle visibility of the bot
# toggle visibility of the bot
func hide_bot():
	self.visible = false


func show_bot():
	self.visible = true


#func transparency(trans : float):
#	self.modulate.a = trans
