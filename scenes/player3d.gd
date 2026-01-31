extends CharacterBody3D

@export var gravity: float
@export var jump_vel: float
@export var move_vel: float
@export var camera_speed: float

@onready var cam = $Camera3D

# var camera_velocity: Vector2

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_cancel'):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion:
		# TODO should we use event.screen_velocity? idk
		# print(event.screen_velocity)
		var camera_velocity: Vector2 = camera_speed * event.screen_relative
		rotate_y(-camera_velocity.x) # sideways camera rotation
		cam.rotation.x = clamp(cam.rotation.x - camera_velocity.y, -PI/2, PI/2) # vertical camera rotation

# 2d is so mainstream, WE are all doing 3d now
func _process(delta: float) -> void:
	var vel_vec := Vector2( \
		Input.get_axis('move_left', 'move_right'), Input.get_axis('move_forward', 'move_backward')  \
	).normalized()
	var dir := (transform.basis * Vector3(vel_vec.x, 0.0, vel_vec.y)).normalized()
	
	if is_on_floor():
		if Input.is_action_just_pressed('jump'):
			velocity.y = jump_vel
	else:
		velocity.y += gravity * delta
	
	velocity.z = move_vel * dir.z
	velocity.x = move_vel * dir.x
	move_and_slide()
