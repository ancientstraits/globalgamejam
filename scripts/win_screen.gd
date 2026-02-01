extends Control

func _ready() -> void:
	var tween := create_tween()
	$Overlay.color.a = 1.0
	tween.tween_property($Overlay, 'color:a', 0.0, 0.7)
	tween.finished.connect($Overlay.queue_free)


func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_play_again_pressed() -> void:
	get_tree().change_scene_to_file('res://scenes/title.tscn')
