extends Node3D

var fix_threshold : float = 2
var fix_rate : float = 2

var fix_amount := 0.0
var interacting := false
var delta_cache : float = 0

func _ready() -> void:
	$Timer.wait_time = randf_range(2,4)
	$Timer.start()

func _physics_process(delta: float) -> void:
	fix_threshold = 2
	fix_rate = 2
	delta_cache += delta
	if interacting:
		fix_amount += fix_rate * delta_cache
		delta_cache = 0
		$MeshInstance3D.mesh.material.albedo_color.g = fix_threshold/(fix_threshold-fix_amount) - 1
		print(fix_amount)
		print(fix_threshold)
	else:
		delta_cache = 0

		
	if fix_amount >= fix_threshold:
		
		get_parent().defect_count -= 1
		call_deferred("queue_free")
		
	interacting = false

func _on_timer_timeout() -> void:
	$GPUParticles3D.emitting = true
	$Timer2.start(1.9)
	$Timer.wait_time = randf_range(2,4)
	$Timer.start()


func _on_timer_2_timeout() -> void:
	$GPUParticles3D.restart()
	$GPUParticles3D.emitting = false
	
func interact() -> void:
	interacting = true
