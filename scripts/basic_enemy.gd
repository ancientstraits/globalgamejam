extends CharacterBody3D

@export var speed : float
@export var wander_radius : float
@export var always_see_player := false

@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var hitbox := $Hitbox
@onready var nav_update_timer := $NavigationUpdateTimer

var see_player := false
var nav_rid : RID
var can_update_navigation := true

func _ready() -> void:
	if !always_see_player:
		pick_random_destination()

func _physics_process(delta: float) -> void:
	
	if can_update_navigation:
		if nav_agent.is_navigation_finished() and !see_player and !always_see_player:
			pick_random_destination()
		
		
		
		var player_position = Globals.player.global_position
		
		if !always_see_player:
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(global_position, player_position)
			query.exclude = [self]
			var result = space_state.intersect_ray(query)
			if result and result['collider'].is_in_group('player'):
				see_player = true
				nav_agent.set_target_position(Globals.player.position)
			else:
				see_player = false
		else:
			nav_agent.set_target_position(Globals.player.position)
		
		
		can_update_navigation = false
		nav_update_timer.start()
		
	var destination = nav_agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
		
	velocity = direction * speed
	move_and_slide()

	for i in hitbox.get_overlapping_bodies():
		if i.is_in_group('player'):
			if i.can_take_damage == true:
				Globals.take_damage.emit()
				Globals.health -= 1

func pick_random_destination():
	var nav_map := nav_agent.get_navigation_map()
	var random_offset = Vector3(
	randf_range(-wander_radius, wander_radius),0.0,randf_range(-wander_radius, wander_radius))
	var target_position = global_position + random_offset
	var valid_point = NavigationServer3D.map_get_closest_point(nav_map,target_position)
	nav_agent.target_position = valid_point


func _on_navigation_update_timer_timeout() -> void:
	can_update_navigation = true
