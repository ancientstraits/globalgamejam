extends Node3D

func _ready() -> void:
	$Timer.wait_time = randf_range(0,0.5)
	$Timer.start()


func _on_timer_timeout() -> void:
	$GPUParticles3D.emitting = true
	$Timer.wait_time = randf_range(0,0.5)
	$Timer.start()
