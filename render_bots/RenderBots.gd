extends Node2D

enum Markers{
	RED = 1,	# FIRST BIT
	GREEN = 2,	# SECOND BIT
	BLUE = 4,	# THIRD BIT
	ALPHA = 8	# FOURTH BIT
}

class_name RenderBots
export var start_button : NodePath
export var pause_button : NodePath
#export var stop_button : NodePath
export var hide_bots_button : NodePath
export var show_bots_button : NodePath
export var edgebots_button : NodePath
export var hatchbots_button : NodePath
export var saveImage_button : NodePath
export var killbots_button : NodePath
export var saveFileDialog : NodePath
export var confirmationDialog : NodePath
onready var _start_button = get_node(start_button) as Button
onready var _pause_button = get_node(pause_button) as Button
#onready var _stop_button = get_node(stop_button) as Button
onready var _hide_bots_button = get_node(hide_bots_button) as Button
onready var _show_bots_button = get_node(show_bots_button) as Button
onready var _edgebots_button = get_node(edgebots_button) as Button
onready var _hatchbots_button = get_node(hatchbots_button) as Button
onready var _saveImage_button = get_node(saveImage_button) as Button
onready var _killbots_button = get_node(saveImage_button) as Button
onready var _saveFileDialog = get_node(saveFileDialog) as FileDialog
onready var _confirmationDialog = get_node(confirmationDialog) as ConfirmationDialog

var active = false
export var max_marker_dist : float = 255.0
var g_buffer : GBuffer setget set_g_buffer
var target_image : Image = Image.new()
var temp_image : Image = Image.new()
var bots_hided = false
var paused = false
var restart = false

#var region_count = 8
#var regions : Array 
#var region_size : Vector2 

func set_g_buffer(value : GBuffer):
	g_buffer = value  # initialize the g_buffer
	if g_buffer:
		_start_button.disabled = false
		_pause_button.disabled = true
#		_stop_button.disabled = true
		_edgebots_button.disabled = true
		_hatchbots_button.disabled = false
		_saveImage_button.disabled = true
		_killbots_button.disabled = true
		# Initialize the texture with the image data
		($PreviewSprite.texture as ImageTexture).create_from_image(g_buffer.color) 
		# Set regions size
#		region_size = g_buffer.color.get_size()/region_count

func _ready():
	$PreviewSprite.texture = ImageTexture.new()
	_saveFileDialog.add_filter("*.png ; PNG Images")
	pass 


func _physics_process(delta: float) -> void:
	if active :
		target_image.lock()
		temp_image.lock()
		get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "Bots", "step_bot", self)   # renderbots have the gbuffer and the target image
		target_image.unlock()
		temp_image.unlock()
		
#		print(($PreviewSprite.texture as ImageTexture).get_format())
		($PreviewSprite.texture as ImageTexture).set_data(target_image)
		
		
		

func start() -> void:
	restart = true
	_start_button.text = "Re-Start"
	# lock gbuffer
	g_buffer.lock()
	active = true
	#_start_button.disabled = true
	_pause_button.disabled = false
#	_stop_button.disabled = false
	_saveImage_button.disabled = false
	_killbots_button.disabled = false
	
	# new image: size equal to the buffer's size, mipmap false, regular format
	target_image.create(g_buffer.color.get_width(), g_buffer.color.get_height(), false, Image.FORMAT_RGBA8)
	
	# Format: red channel, 32b float precision
	temp_image.create(g_buffer.color.get_width(), g_buffer.color.get_height(), false, Image.FORMAT_RGBA8)
	
	# fill image with max distance to marker
	#temp_image.fill(Color(max_marker_dist, max_marker_dist, max_marker_dist))
	temp_image.fill(Color.black)
	target_image.fill(Color.white)

		
# hacer que los renderbots empiecen a trabajar
func _on_Start_pressed() -> void:
	if restart:
		_confirmationDialog.popup_centered()
		return 
	else:
		start()
	
	
	
	### Define Regions 
#	regions = Array()
#	regions.resize(region_count * region_count)
#	for i in regions.size():
#		# array of all the markers in the region
#		regions[i] = Array()
	

# returns the region the position is at
#func get_region_at_position(pos : Vector2) -> int:
#	var x : int = clamp(pos.x/region_size.x, 0, region_count - 1)
#	var y : int = clamp(pos.y/region_size.y, 0, region_count - 1)
#	return x + region_count * y

# we use bit flags to be able to combine the markers later
func put_marker(pos : Vector2, type : int) -> void:
	var red = min(1, type&Markers.RED)
	var green = min(1, type&Markers.GREEN)
	var blue = min(1, type&Markers.BLUE)
	var alpha = min(1, type&Markers.ALPHA)
	# avoid erasing markers that are already there, always keep the marker already setted
	var pix = temp_image.get_pixelv(pos) 
	red = max(pix.r, red)
	green = max(pix.g, green)
	blue = max(pix.b, blue)
	alpha = max(pix.a, alpha)
	temp_image.set_pixelv(pos, Color(red, green, blue, alpha))
	
#	temp_image.set_pixelv(pos, Color.white)
#	var start : Vector2 = pos - Vector2.ONE * max_marker_dist
#	start.x = max(start.x, 0)
#	start.y = max(start.y, 0)
##
#	var end : Vector2 = pos + Vector2.ONE * max_marker_dist
#	end.x = min(end.x + 1, temp_image.get_width())
#	end.y = min(end.y + 1, temp_image.get_height())
#
#	for y in range(start.y, end.y):
#		for x in range(start.x, end.x):
#			var distance = pos.distance_to(Vector2(x, y))
#			temp_image.set_pixel(x,y, Color(int(min(distance, temp_image.get_pixel(x,y).r)))) 
	
#	var reg_id = get_region_at_position(pos)
#	(regions[reg_id] as Array).push_back(pos)


# Returns markers in the distance around the position 
func get_markers(pos : Vector2, distance : int, type : int) -> Array:
	var markers = Array()
	var red = min(1, type&Markers.RED)
	var green = min(1, type&Markers.GREEN)
	var blue = min(1, type&Markers.BLUE)
	var alpha = min(1, type&Markers.ALPHA)
	
	var start : Vector2 = pos - Vector2.ONE * distance
	start.x = max(start.x, 0)
	start.y = max(start.y, 0)

	var end : Vector2 = pos + Vector2.ONE * distance
	end.x = min(end.x + 1, temp_image.get_width())
	end.y = min(end.y + 1, temp_image.get_height())
	
	# we check if there is a marker in the position in the relevant channels
	for y in range(start.y, end.y):
		for x in range(start.x, end.x):
			var pix = temp_image.get_pixel(x,y)
#			var distance = pos.distance_to(Vector2(x, y))
			if red * pix.r > 0.5:
					markers.push_back(Vector2(x,y))
			elif green * pix.g > 0.5:
					markers.push_back(Vector2(x,y))
			elif blue * pix.b > 0.5:
					markers.push_back(Vector2(x,y))
			elif alpha * pix.a > 0.5:
					markers.push_back(Vector2(x,y))
			
	return markers

#func get_neighbor_regions(pos : Vector2) -> Array:
#	var result = Array()
#	var center = get_region_at_position(pos)
#	var x : int = center % region_count
#	var y : int = center / region_count
#	for xx in range(x-1, x+2):
#		for yy in range(y-1, y+2):
#			if xx == clamp(xx, 0, region_count-1) and yy == clamp(yy, 0, region_count-1):
#				result.push_back(xx + yy*region_count)
#	return result


#func _on_Stop_pressed() -> void:
#	active = false
#	_start_button.disabled = false
#	_stop_button.disabled = true


func _on_HideBots_pressed() -> void:
	#get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "Bots", "hide_bot")
	$PreviewSprite/Node2D.visible = false


func _on_ShowBots_pressed() -> void:
	#get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "Bots", "show_bot")
	$PreviewSprite/Node2D.visible = true



func _on_Transparency_value_changed(value: float) -> void:
	# get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "Bots", "transparency", value)
	$PreviewSprite/Node2D.modulate.a = value


func _on_Edgebots_pressed() -> void:
	$PreviewSprite.state = $PreviewSprite.States.EDGE
	_hatchbots_button.disabled = false
	_edgebots_button.disabled = true


func _on_Hatchbots_pressed() -> void:
	$PreviewSprite.state = $PreviewSprite.States.HATCH
	_edgebots_button.disabled = false
	_hatchbots_button.disabled = true


func _on_SaveImage_pressed() -> void:
	_saveFileDialog.popup()


func _on_SaveFileDialog_file_selected(path: String) -> void:
	target_image.save_png(path)


func _on_KillBots_pressed() -> void:
	for child in $PreviewSprite/Node2D.get_children():
		child.queue_free()


func _on_KillHatchbots_pressed() -> void:
	for child in $PreviewSprite/Node2D.get_children():
		if child.is_in_group("Hatchbots"):
			child.queue_free()



func _on_KillEdgebots_pressed() -> void:
	for child in $PreviewSprite/Node2D.get_children():
		if child.is_in_group("EdgeBots"):
			child.queue_free()

func _on_Pause_pressed() -> void:
	if !paused:
		_pause_button.text = "Resume"
		active = false
		paused = true
	else:
		_pause_button.text = "Pause"
		active = true
		paused = false
	pass # Replace with function body.


func _on_ConfirmationDialog_confirmed() -> void:
	start()



func _on_hatchThick_value_changed(value: float) -> void:
	GlobalConfig.hatch_thick = value

func _on_hatchSeparation_value_changed(value: float) -> void:
	GlobalConfig.separation = value


func _on_HatchColorPicker_color_changed(color: Color) -> void:
	GlobalConfig.hatch_color = color


func _on_EdgeColorPicker_color_changed(color: Color) -> void:
	GlobalConfig.edge_color = color


func _on_EdgeThick_value_changed(value: float) -> void:
	GlobalConfig.edge_thick = value


func _on_angle_value_changed(value: float) -> void:
	var direction = Vector2.RIGHT.rotated(deg2rad(value))
	GlobalConfig.direction = direction
