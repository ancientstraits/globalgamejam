extends Area3D

func _on_body_entered(body: Node3D) -> void:
	print('amogus')
	body.hanging = true
	body.hang_pos = $PlayerPosition.global_position
	
	var tween = body.create_tween()
	tween.tween_property(body, 'global_position', $PlayerPosition.global_position, 0.5)
