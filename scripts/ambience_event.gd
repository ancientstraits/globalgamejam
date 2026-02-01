extends CharacterBody3D

@export var wander_radius : float
@export var min_distance : float
@export var time_between_sounds : float
@export var time_variability : float
@export var sounds : Array[AudioStreamOggVorbis]

@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var timer := $Timer
@onready var audio_player = $AudioStreamPlayer3D

func _ready() -> void:
	timer.start(time_between_sounds + time_variability * randf_range(-1,1))

func pick_random_destination():

	
	var nav_map := nav_agent.get_navigation_map()
	
	var randx = randf_range(-1,1)
	var x_offset : float
	if randx < 0:
		x_offset = -min_distance
	else:
		x_offset = min_distance
	var randy = randf_range(-1,1)
	var y_offset : float
	if randy < 0:
		y_offset = -min_distance
	else:
		y_offset = min_distance
	
	var random_offset = Vector3(
	randx * wander_radius + x_offset,0,randy * wander_radius + y_offset)
	var target_position = Globals.player.global_position + random_offset
	var valid_point = NavigationServer3D.map_get_closest_point(nav_map,target_position)
	global_position = valid_point
	
	audio_player.stream = sounds[randi_range(0,6)]
	audio_player.play()

	timer.start(time_between_sounds + time_variability * randf_range(-1,1))
		
	print(audio_player.stream)

func _on_timer_timeout() -> void:
	pick_random_destination()
