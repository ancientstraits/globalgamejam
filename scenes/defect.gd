extends Node3D

@export var fix_threshold : float
@export var fix_rate : float

var fix_amount := 0.0
var interacting := false

func _ready() -> void:
	$Timer.wait_time = randf_range(2,4)
	$Timer.start()

func _physics_process(delta: float) -> void:
	if interacting:
		fix_amount += fix_rate * delta
		print(fix_amount)
	if fix_amount >= fix_threshold:
		queue_free()
		
	interacting = false

func _on_timer_timeout() -> void:
	$GPUParticles3D.emitting = true
	$Timer2.start(1.9)
	$Timer.wait_time = randf_range(2,4)
	$Timer.start()


func _on_timer_2_timeout() -> void:
	$GPUParticles3D.restart()
	$GPUParticles3D.emitting = false
