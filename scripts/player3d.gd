extends CharacterBody3D

@export var gravity: float
@export var jump_vel: float
@export var move_vel: float
@export var camera_speed: float
@export var invulnerability_time : float

@onready var cam = $Camera3D
@onready var collider = $CollisionShape3D
@onready var invulnerability_timer = $InvulnerabilityTimer
@onready var damage_overlay = $GasMask/DamageOverlay
@onready var gasmask_rect: ColorRect = $Mask/ColorRect

var is_dead = false
var can_take_damage := true
var hanging: bool = false
var hang_pos: Vector3 = Vector3.ZERO
var can_move = true
var player_won := false

var time_at_death := 0.0

@onready var postproc: CanvasLayer = $Mask

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
	if (!can_move): return
	
	if hanging and Input.is_action_just_pressed('jump'):
		hanging = false
		# this stops the hanging animation
		var tweens := get_tree().get_processed_tweens()
		if tweens.size() > 0:
			tweens[0].kill()
		velocity.y = jump_vel
	
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
		velocity.y = 0.0
		velocity += 20.0 * to_hangpos
	
	move_and_slide()
	
	if Globals.health == 0:
		Globals.die.emit('Critical injuries')
	
func start_invulnerability():
	invulnerability_timer.start(invulnerability_time)
	can_take_damage = false

func _on_invulnerability_timer_timeout() -> void:
	can_take_damage = true
	
func kill() -> void:
	if (is_dead): return
	
	if time_at_death < 1:
		time_at_death = Globals.time
	
	is_dead = true
	can_move = false	
	invulnerability_timer.start(99)
	can_take_damage = false
	var tween := create_tween()
	tween.tween_property(self, 'rotation:z', deg_to_rad(90), 1.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.finished.connect(begin_fade)

func _get_gasmask_mul() -> Vector2:
	var mat: ShaderMaterial = gasmask_rect.material
	return mat.get_shader_parameter('gasmask_mul')

func _set_gasmask_mul(mul: Vector2) -> void:
	var mat: ShaderMaterial = gasmask_rect.material
	mat.set_shader_parameter('gasmask_mul', mul)

func _get_pixelate_factor() -> float:
	var mat: ShaderMaterial = $Postproc/ColorRect.material
	return mat.get_shader_parameter('pixelate_factor')

func _set_pixelate_factor(fac: float) -> void:
	var mat: ShaderMaterial = $Postproc/ColorRect.material
	return mat.set_shader_parameter('pixelate_factor', fac)

func win_fade() -> void:
	can_take_damage = false
	player_won = true
	collision_layer = 0
	collision_mask = 0
	gravity = 10.0
	jump_vel = 0.0
	
	$GameOver/ColorRect.color = Color.WHITE
	$GameOver/ColorRect.color.a = 0.0
	
	# for transition to win screen scene
	var dupe_rect = $GameOver/ColorRect.duplicate()
	dupe_rect.color.a = 1.0
	TitleGlobal.add_child(dupe_rect)
	
	var tween := create_tween()
	
	tween.tween_property($GameOver/ColorRect, 'color:a', 1.0, 4.0)
	for child: Control in damage_overlay.get_children():
		tween.parallel().tween_property(child, 'modulate:a', 0.0, 4.0)
	tween.parallel().tween_property(self, 'move_vel', 0.0, 2.5)
	tween.parallel().tween_method(_set_gasmask_mul, _get_gasmask_mul(), Vector2(0.3, 0.3), 3.5)
	#tween.parallel().tween_method(_set_pixelate_factor, _get_pixelate_factor(), 1.0, 3.5)
	tween.finished.connect(
		func():
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file('res://scenes/win_screen.tscn')
	)

func begin_fade() -> void:
	var fade := $GameOver/ColorRect
	fade.color.a = 0.0
	
	var fade_tween := create_tween()
	fade_tween.tween_property(fade, 'color:a', 1.0, 2)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_IN)
	fade_tween.finished.connect(finish_fade)
	
func finish_fade() -> void:
	var hold_timer := Timer.new()
	hold_timer.one_shot = true
	hold_timer.wait_time = 1.0
	add_child(hold_timer)
	hold_timer.start()
	hold_timer.timeout.connect(show_labels)
	
func show_labels() -> void:
	var label := $GameOver/ColorRect/Label
	var label2 := $GameOver/ColorRect/Label2
	var cause := $GameOver/ColorRect/Cause
	
	var time_text : String
	
	var hour : int
	var minutes : int
	hour = int(floor(time_at_death)) / 60
	minutes = int(floor(time_at_death)) % 60
	
	if minutes < 10:
		time_text = str(hour) + ':0' + str(minutes)
	else:
		time_text = str(hour) + ':' + str(minutes)
	
	label2.text = 'TIME SURVIVED:\n' + time_text
	
	label2.visible = true
	label.visible = true
	
	var delay := Timer.new()
	delay.one_shot = true
	delay.wait_time = 1.0
	add_child(delay)
	delay.start()
	delay.timeout.connect(func(): 
		cause.visible = true
		delay.wait_time = 3.0
		delay.start()
		delay.timeout.connect(Globals.restart_game)
	)
	
func set_cause(cause : String) -> void:
	var label := $GameOver/ColorRect/Cause
	label.text = cause
