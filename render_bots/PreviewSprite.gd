extends Sprite

enum States{
	EDGE,
	HATCH
} 

func _ready():
	pass 

var bot = preload("res://render_bots/bots/edgeBot/EdgeBot.tscn")
var hatchbot = preload("res://render_bots/bots/hatchbots/Hatchbot.tscn")
var state = States.EDGE  # default: edgebots

func _process(delta):
	#if self.is_visible_in_tree():
	# escalar el sprite para que se ajuste al viewport
#	if self.texture.get_size().x > 0 and self.texture.get_size().y > 0:
#		self.scale = Vector2.ONE*min(get_viewport_rect().size.y/self.texture.get_size().y, get_viewport_rect().size.x/self.texture.get_size().x)
#	var own_size = self.texture.get_size()*self.scale
#	var offset_from_center = -own_size*0.5
#	var center = get_viewport_rect().size*0.5
#	self.global_position = center + offset_from_center
	pass


func _input(event: InputEvent) -> void:
#	print(event)
	if event.is_action("click") and event.is_pressed():
		var position2D = get_local_mouse_position()    # conseguir la posición local del ratón
		print(position2D)
		if self.get_rect().has_point(position2D):     # si se encuentra dentro de la imagen, crea el bot
			#var tam = (get_node("Control/LineEdit"))
			var b
			if state == States.EDGE:
				b = bot.instance()
			elif state == States.HATCH:
				b = hatchbot.instance()
	#		if tam.empty():
	#			b.set_rad(0.05)
	#		else:
	#			#b.set_rad(float(tam.get_text()))
	#			b.set_rad(float(tam))
			b.initialize(position2D)
			$Node2D.add_child(b)
			
