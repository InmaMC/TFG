extends Sprite


export var bot_scale = 0.1


func _ready():
	pass 


# scale the bot so it doesn't change its position when the viewport is scaled
# same coordenates as the viewport
func _process(delta):
	
	self.global_transform.x = Vector2.RIGHT*bot_scale
	self.global_transform.y = Vector2.DOWN*bot_scale
#	pass
