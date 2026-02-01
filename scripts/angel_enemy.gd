extends CharacterBody3D

@export var speed : float
@export var wander_radius : float
@export var min_distance : float
@export var time_not_seen_threshold : float

@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var hitbox := $Hitbox
@onready var nav_update_timer := $NavigationUpdateTimer

var can_update_navigation := true
var flashed := false
var seen_once := false
var time_not_seen := 0.0

var delta_cache := 0.0

func _physics_process(delta: float) -> void:
	
	delta_cache += delta
	
	if can_update_navigation:
		var player_position = Globals.player.global_position
		
		if flashlight_hits_enemy(Globals.player.get_node('Camera3D/Flashlight/SpotLight3D')):
			flashed = true

		else:
			flashed = false
			
			
		if flashed:
			time_not_seen = 0
			seen_once = true
			nav_agent.set_target_position(Globals.player.position)
			
			var destination = nav_agent.get_next_path_position()
			var local_destination = destination - global_position
			var direction = local_destination.normalized()
				
			velocity = direction * speed
		elif seen_once == true:
			velocity = Vector3.ZERO
			time_not_seen += delta
			if time_not_seen > time_not_seen_threshold:
				seen_once = false
				time_not_seen = 0
				pick_random_destination()
		else:
			velocity = Vector3.ZERO
		
		can_update_navigation = false
		nav_update_timer.start()
		
	
	move_and_slide()

	for i in hitbox.get_overlapping_bodies():
		if i.is_in_group('player'):
			if i.can_take_damage == true:
				Globals.take_damage.emit()
				Globals.health -= 1

func pick_random_destination():
	
	print('MOVE MF')
	
	var nav_map := nav_agent.get_navigation_map()
	var random_offset = Vector3(
	randf_range(-wander_radius + min_distance, wander_radius - min_distance),2,randf_range(-wander_radius + min_distance, wander_radius - min_distance))
	var target_position = global_position + random_offset
	var valid_point = NavigationServer3D.map_get_closest_point(nav_map,target_position)
	global_position = valid_point

func flashlight_hits_enemy(
	flashlight: SpotLight3D,
	) -> bool:
	if not flashlight.visible:
		return false

	var light_pos = flashlight.global_position

	# Distance check
	var to_enemy = global_position - light_pos
	var distance = to_enemy.length()
	if distance > flashlight.spot_range:
		return false

	# Cone check
	var flashlight_forward = -flashlight.global_transform.basis.z.normalized()
	var dir_to_enemy = to_enemy.normalized()

	var angle = acos(flashlight_forward.dot(dir_to_enemy))
	if angle > deg_to_rad(flashlight.spot_angle):
		return false

	# Occlusion check (walls, props, etc)
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(light_pos, global_position)
	query.exclude = [self]

	var hit = space.intersect_ray(query)
	if hit:
		return false

	return true


func _on_navigation_update_timer_timeout() -> void:
	can_update_navigation = true
