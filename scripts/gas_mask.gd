extends Node3D

@export var max_gas : float
@export var gas_rate : float

var gas := 0.0
var in_gas := false

func _physics_process(delta: float) -> void:
	if in_gas:
		gas += gas_rate * delta
	if gas >= max_gas:
		Globals.die.emit()
