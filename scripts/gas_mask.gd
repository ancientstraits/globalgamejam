extends Node3D

@export var max_gas : float
@export var gas_gain_rate : float
@export var gas_drain_rate : float

var gas := 0.0
var in_gas := false

func _physics_process(delta: float) -> void:
	if in_gas:
		gas += gas_gain_rate * delta
	else: 
		gas -= gas_drain_rate * delta
	if gas >= max_gas:
		Globals.die.emit()
	if get_tree().current_scene.has_node('GasMeter'):
		get_tree().current_scene.get_node('GasMeter').value = gas
