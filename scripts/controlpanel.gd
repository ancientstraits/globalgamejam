extends Node3D

@onready var bars: Array[MeshInstance3D] = [$CylRed, $CylGreen, $CylBlue]

@export var bar_max_pos: float
@export var bar_min_pos: float

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if Globals.generators.is_empty():
		return
	
	# print(Globals.generators[0].defect_count, ' ', Globals.generators[1].defect_count, ' ', Globals.generators[2].defect_count)
	
	for i in range(Globals.generators.size()):
		var gen = Globals.generators[i]
		#print(gen.defect_count)
		var frac: float = 1.0 - (float(gen.defect_count) / float(gen.defect_lose_threshold))
		print(frac)
		#print('frac for generator ', i, ' is ', frac)
		bars[i].position.y = bar_min_pos + (abs(bar_max_pos - bar_min_pos) * frac)
	
