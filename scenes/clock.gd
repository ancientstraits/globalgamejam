extends StaticBody3D

@export var time_stretch : int

@onready var labels: Array[Label3D] = [$Label3DFront, $Label3DBack]

var player_won := false

func _set_label_text(text: String):
	for label in labels:
		label.text = text

func is_game_over(hour: int, minutes: int) -> bool:
	return hour >= 6

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
	
	if not player_won and is_game_over(hour, minutes):
		player_won = true
		Globals.player.win_fade()
	
