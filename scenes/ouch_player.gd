extends AudioStreamPlayer3D

func _ready() -> void:
	Globals.take_damage.connect(play_audio)
	
func play_audio():
	pitch_scale = randf_range(0.9,1.1)
	play()
