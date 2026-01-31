extends CharacterBody3D

@export var gravity: float
@export var jump_vel: float
@export var move_vel: float
@export var camera_speed: float
@export var invulnerability_time : float

@onready var cam = $Camera3D
@onready var collider = $CollisionShape3D
@onready var invulnerability_timer = $InvulnerabilityTimer

var can_take_damage := true
var hanging: bool = false
var hang_pos: Vector3 = Vector3.ZERO

@onready var postproc: CanvasLayer = $Postproc

# var camera_velocity: Vector2
	
func _ready() -> void:
	Globals.take_damage.connect(start_invulnerability)
	Globals.player = self
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
		
		postproc.gasmask_off = 0.1 * camera_velocity

# 2d is so mainstream, WE are all doing 3d now
func _process(delta: float) -> void:
	if hanging and Input.is_action_just_pressed('jump'):
		hanging = false
	
	var vel_vec := Vector2( \
		Input.get_axis('move_left', 'move_right'), Input.get_axis('move_forward', 'move_backward')  \
	).normalized()
	var dir := (transform.basis * Vector3(vel_vec.x, 0.0, vel_vec.y)).normalized()
	
	postproc.gasmask_mul = \
		postproc.gasmask_mul.lerp(0.03 * vel_vec.y * Vector2.ONE, 0.5)
	
	if is_on_floor():
		if Input.is_action_just_pressed('jump'):
			velocity.y = jump_vel
	else:
		velocity.y += gravity * delta

	
	velocity.z = move_vel * dir.z
	velocity.x = move_vel * dir.x
	
	if hanging:
		var to_hangpos := hang_pos - global_position
		velocity += 20.0 * to_hangpos
		velocity.y = 0.0
	
	move_and_slide()
	
	
func start_invulnerability():
	invulnerability_timer.start(invulnerability_time)
	can_take_damage = false

func _on_invulnerability_timer_timeout() -> void:
	can_take_damage = true
