extends StaticBody3D

@export var defect : PackedScene
@export var defect_position_padding : float
@export var defect_spawn_rate : float
@export var defect_spawn_rate_variability : float
@export var defect_lose_threshold : int

var defect_count := 0

func _ready() -> void:
	var timer = $Timer
	timer.start(randf_range(defect_spawn_rate - defect_spawn_rate_variability, defect_spawn_rate + defect_spawn_rate_variability))

func _on_timer_timeout() -> void:
	
	if defect_count >= defect_lose_threshold:
<<<<<<< Updated upstream
		Globals.die.emit()
=======
		Globals.timeout.emit('Generator malfunction')
>>>>>>> Stashed changes
		
		# lose type shi
	else:
		var repair_plane = $RepairPlane
		var aabb = repair_plane.get_aabb()
		var size = repair_plane.get_aabb().size
		
		var defect_instance = defect.instantiate()
		
		defect_instance.position =  repair_plane.position + aabb.position + Vector3(randf_range(defect_position_padding,size.x - defect_position_padding), randf_range(defect_position_padding,size.y - defect_position_padding), 0)
		
		add_child(defect_instance)
		defect_count += 1
		
		var timer = $Timer
		timer.start(randf_range(defect_spawn_rate - defect_spawn_rate_variability, defect_spawn_rate + defect_spawn_rate_variability))
