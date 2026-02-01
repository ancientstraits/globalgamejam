extends StaticBody3D

@export var time_stretch : int

@onready var label = $Label3D

func game_end() -> bool:
	var hour : int
	hour = int(floor(Globals.time)) / (60 * time_stretch)
	return hour >= 6

func _process(delta: float) -> void:
	Globals.time += delta
	var hour : int
	var minutes : int
	hour = int(floor(Globals.time)) / (60 * time_stretch)
	minutes = (int(floor(Globals.time)) % (60 * time_stretch)) / time_stretch
	
	if minutes < 10:
		label.text = str(hour) + ':0' + str(minutes)
	else:
		label.text = str(hour) + ':' + str(minutes)
