extends Area3D

var hang_tween: Tween = null

func _on_body_entered(body: Node3D) -> void:
	print('amogus')
	body.hanging = true
	body.hang_pos = $PlayerPosition.global_position
	
	hang_tween = body.create_tween()
	hang_tween.tween_property(body, 'global_position', $PlayerPosition.global_position, 0.5)
