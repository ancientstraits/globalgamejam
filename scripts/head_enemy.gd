extends CharacterBody3D

@export var drop_speed : float
@export var wander_radius : float
@export var min_distance : float
@export var time_since_dropped_threshold : float
@export var y_offset : float
@export var giggle_distance : float


@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var hitbox := $Hitbox
@onready var player_detector := $PlayerDetector
@onready var nav_update_timer := $NavigationUpdateTimer
@onready var audio_player = $AudioStreamPlayer3D

var can_update_navigation := true
var triggered := false
var time_since_dropped := 0.0
var giggled := false

func _ready() -> void:
	position.y += y_offset
	up_direction.y = -1

func _physics_process(delta: float) -> void:
	
	var player_position = Globals.player.global_position
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, player_position)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	if result and result['collider'].is_in_group('player'):
		var player = result['collider']
		if Vector3(Vector3(global_position.x, player.global_position.y, global_position.z) - player.global_position).length() < giggle_distance:
			if giggled == false:
				giggled = true
				audio_player.play()
	
	if triggered:
		velocity.y -= drop_speed * delta
		up_direction.y = 1
		time_since_dropped += delta
	elif giggled:
		time_since_dropped += delta
		velocity = Vector3.ZERO
	else:
		time_since_dropped = 0
		velocity = Vector3.ZERO
	
	if time_since_dropped > time_since_dropped_threshold:
			time_since_dropped = 0
			pick_random_destination()
	can_update_navigation = false
	nav_update_timer.start()
	
	move_and_slide()

	for i in hitbox.get_overlapping_bodies():
		if i.is_in_group('player'):
			if i.can_take_damage == true:
				Globals.take_damage.emit()
				Globals.health -= 1

func pick_random_destination():
	
	giggled = false
	up_direction.y = -1
	triggered = false
	time_since_dropped = 0
	
	print('Head moving!')
	
	var nav_map := nav_agent.get_navigation_map()
	var randx = randf_range(-1,1)
	var x_offset : float
	if randx < 0:
		x_offset = -min_distance
	else:
		x_offset = min_distance
	var randy = randf_range(-1,1)
	var z_offset : float
	if randy < 0:
		z_offset = -min_distance
	else:
		z_offset = min_distance
	
	var random_offset = Vector3(
	randx * wander_radius + x_offset,0,randy * wander_radius + z_offset)
	var target_position = Globals.player.global_position + random_offset
	var valid_point = NavigationServer3D.map_get_closest_point(nav_map,target_position)
	global_position = valid_point
	global_position.y += y_offset

func _on_navigation_update_timer_timeout() -> void:
	can_update_navigation = true


func _on_player_detector_body_entered(body: Node3D) -> void:
	if body.is_in_group('player'):
		triggered = true
