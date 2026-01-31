extends StaticBody3D

@export var defect : PackedScene
@export var defect_position_padding : float


func _ready() -> void:
	
	var repair_plane = $RepairPlane
	
	
	for i in 7:
		
		var aabb = repair_plane.get_aabb()
		var size = repair_plane.get_aabb().size
		
		var defect_instance = defect.instantiate()
		
		defect_instance.position =  repair_plane.position + aabb.position + Vector3(randf_range(defect_position_padding,size.x - defect_position_padding), randf_range(defect_position_padding,size.y - defect_position_padding), 0)
		
		add_child(defect_instance)
