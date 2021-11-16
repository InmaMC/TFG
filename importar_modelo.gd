extends TextureButton


func _ready():
	pass 

# cambiar escena de inicio por la principal
func _on_importar_modelo_pressed():
	get_tree().change_scene("res://Main.tscn")
