extends StaticBody3D

@export var time_stretch : int

@onready var labels: Array[Label3D] = [$Label3DFront, $Label3DBack]

func _set_label_text(text: String):
	for label in labels:
		label.text = text

func is_game_over(hour: int, minutes: int) -> bool:
	return minutes >= 10

func _process(delta: float) -> void:
	Globals.time += delta
	var hour : int
	var minutes : int
	hour = int(floor(Globals.time)) / (60 * time_stretch)
	minutes = (int(floor(Globals.time)) % (60 * time_stretch)) / time_stretch
	
	if minutes < 10:
		_set_label_text(str(hour) + ':0' + str(minutes))
	else:
		_set_label_text(str(hour) + ':' + str(minutes))
	
	if is_game_over(hour, minutes):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file('res://scenes/win_screen.tscn')
