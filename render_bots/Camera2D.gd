extends Camera2D

export var sprite : NodePath

onready var sprite_node : Sprite = get_node(sprite) as Sprite

func _ready() -> void:
	pass # Replace with function body.



func _process(delta: float) -> void:
	if not sprite_node.texture.get_size() == Vector2.ZERO:
		# camera in the middle of the sprite (image)
		self.offset = sprite_node.texture.get_size() * 0.5
		# camera's zoom relative to the viewport
		self.zoom = Vector2.ONE * max(sprite_node.texture.get_size().y/get_viewport_rect().size.y, sprite_node.texture.get_size().x/get_viewport_rect().size.x)
	
