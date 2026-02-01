extends ShapeCast3D

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("action1"):
		var col : Node3D
		
		for i in get_collision_count():
			col = get_collider(i)
			var parent = col.get_parent()
			if (parent.has_method('interact')):
				parent.interact()
