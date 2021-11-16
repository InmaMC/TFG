extends Node
# export (PackedScene) var bot_scene
signal g_buffer_changed(new_g_buffer)

var g_buffer : GBuffer = GBuffer.new()

# cargar los Viewports
onready var curvature_view : Viewport = $"TabContainer/3DView/MainView/Curvature/Viewport"
onready var color_view : Viewport = $"TabContainer/3DView/MainView/Color/Viewport"
onready var normal_view : Viewport = $"TabContainer/3DView/MainView/Normal/Viewport"
onready var depth_view : Viewport = $"TabContainer/3DView/MainView/Depth/Viewport"
onready var edge_view : Viewport = $"TabContainer/3DView/MainView/Edge/Viewport"
onready var dist_edge_view : Viewport = $"TabContainer/3DView/MainView/DistEdge/Viewport"
onready var dist_edge_texture : TextureRect = $"TabContainer/3DView/MainView/DistEdge/Viewport/TextureRect"
onready var render_bots = $TabContainer/Renderbots/ViewportContainer/Viewport/RenderBots

# Marcando los parámetros necesarios para el viewport
func prepare_viewport(viewport : Viewport, size : Vector2):
	viewport.size_override_stretch = true   #  size override afecta al stretch
	viewport.size = size                    # cambiamos el tamaño del viewport al deseado
	viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS    # El viewport (render target) se actualiza siempre
	viewport.render_target_v_flip = true    # voltear verticalmente el resultado del renderizado

# reset parámetros
func reset_viewport(viewport : Viewport):
	viewport.size_override_stretch = false
	viewport.render_target_v_flip = false
	viewport.size = (viewport.get_parent() as ViewportContainer).get_rect().size   # devolver al tamaño que tiene el Viewport principal
	viewport.render_target_update_mode = Viewport.UPDATE_WHEN_VISIBLE


# Cuando el botón Generate G-Buffer se presione
func _on_GenGBuffer_pressed():
	var size := Vector2.ZERO
	# recoger el tamaño deseado de la imagen
	size.x = $"TabContainer/3DView/ControlPanel/x_size/Value".value
	size.y = $"TabContainer/3DView/ControlPanel/y_size/Value".value
	
	dist_edge_texture.visible = true
	
	prepare_viewport(curvature_view, size)
	prepare_viewport(color_view, size)
	prepare_viewport(normal_view, size)
	prepare_viewport(depth_view, size)
	prepare_viewport(edge_view, size)
	prepare_viewport(dist_edge_view, size)

	
	# esperar a que el frame haya termiando antes de coger la textura
	yield(VisualServer, "frame_post_draw")
	
	# recoger la información de la textura y guardarla en el g_buffer
	g_buffer.color = color_view.get_texture().get_data()
	g_buffer.curvature = curvature_view.get_texture().get_data()
	g_buffer.normal = normal_view.get_texture().get_data()
	g_buffer.depth = depth_view.get_texture().get_data()
	g_buffer.edge = edge_view.get_texture().get_data()
	g_buffer.dist_edge = dist_edge_view.get_texture().get_data()
	g_buffer.save_as_png()
	
	reset_viewport(curvature_view)
	reset_viewport(color_view)
	reset_viewport(normal_view)
	reset_viewport(depth_view)
	reset_viewport(edge_view)
	reset_viewport(dist_edge_view)
	dist_edge_texture.visible = false
	# señal de que el g_buffer ha sido cambiado
	emit_signal("g_buffer_changed", g_buffer)
	g_buffer.save_as_png()

	# pasar el buffer a la escena de Renderbots
	render_bots.g_buffer = g_buffer
	pass 


func _on_velocity_value_changed(value: float) -> void:
	GlobalConfig.cam_speed = value
