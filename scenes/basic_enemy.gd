extends CharacterBody3D

@export var speed : float

@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D

func _physics_process(delta: float) -> void:
	nav_agent.set_target_position(Globals.player.position)
	
	var destination = nav_agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	velocity = direction * speed
	move_and_slide()
