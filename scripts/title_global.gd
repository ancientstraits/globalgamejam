extends Control

var listen := false

@onready var essential = $Essential

func _process(_delta: float) -> void:
	essential.visible = get_tree().current_scene == null or get_tree().current_scene.name == 'Title'
	
	if get_tree().current_scene != null and get_tree().current_scene.name != 'Title':
		listen = false
		for child in get_children():
			if child != essential:
				child.queue_free()
