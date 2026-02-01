extends Control

var listen := false

func _process(_delta: float) -> void:
	if get_tree().current_scene != null and get_tree().current_scene.name != 'Title':
		for child in get_children():
			child.queue_free()
