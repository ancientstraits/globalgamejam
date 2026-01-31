extends Area3D

var areas : Array[Area3D]

func _physics_process(delta: float) -> void:
	areas = get_overlapping_areas()
	
	var in_gas := false
	
	for i in areas:
		if i.is_in_group('gas'):
			in_gas = true
			
	get_parent().in_gas = in_gas
