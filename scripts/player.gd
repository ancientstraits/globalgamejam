extends CharacterBody2D

@export var accel_y: float
@export var jump_vel: float
@export var side_vel: float

@export var reset_position: Vector2

func _init() -> void:
	reset_position = position

func reset() -> void:
	position = reset_position
	velocity.x = 0.0
	velocity.y = 0.0

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed('reset'):
		reset()
	
	velocity.x = side_vel * Input.get_axis('move_left', 'move_right')
	velocity.y += accel_y
	if is_on_floor() and Input.is_action_just_pressed('jump'):
		velocity.y = jump_vel

	move_and_slide()
