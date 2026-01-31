extends Node3D

@onready var interaction = $InteractCast
@onready var holding = $HoldCast
@onready var hold_point = $HoldPoint

var throw_magnitude = 5
var hold_distance = 4
var stiffness = 100
var damping = 20

var _held_prop: RigidBody3D = null
	
func _process(delta: float) -> void:
	if (Input.is_action_just_pressed('prop_interact')):
		if (!interaction.is_colliding()):
			return
		
		var hit = interaction.get_collider()
		print("Hit:", hit)

		if (hit && hit.is_in_group('props')):
			_held_prop = hit
			_held_prop.rotation = Vector3.ZERO
	
	if (_held_prop && Input.is_action_pressed('prop_interact')):
		hold_object(delta)
		
	if (_held_prop && Input.is_action_just_pressed('prop_throw')):
		throw_prop()

func hold_object(delta):
	var target_pos = hold_point.global_position
	var prop_pos = _held_prop.global_position
	var dir = target_pos - prop_pos
	var distance = dir.length()

	if (distance > hold_distance):
		drop_prop()
		return

	var force = dir * stiffness - _held_prop.linear_velocity * damping
	_held_prop.apply_central_force(force)	
	_held_prop.linear_velocity = Vector3.ZERO
	_held_prop.angular_velocity = Vector3.ZERO

func drop_prop() -> void:
	if _held_prop:
		holding.remove_exception(_held_prop)
	_held_prop = null
	
func throw_prop() -> void:
	var target_pos = global_position
	var prop_pos = _held_prop.global_position
	var dir = prop_pos - target_pos
	
	_held_prop.linear_velocity += Vector3(dir.x, 1, dir.z) * throw_magnitude
	_held_prop.angular_velocity += dir
	drop_prop()
	
