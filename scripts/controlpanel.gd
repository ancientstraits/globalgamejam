extends Node3D

@onready var bars: Array[MeshInstance3D] = [$CylRed, $CylGreen, $CylBlue]

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if Globals.generators.is_empty():
		return
	
	# print(Globals.generators[0].defect_count, ' ', Globals.generators[1].defect_count, ' ', Globals.generators[2].defect_count)
	
	for i in range(Globals.generators.size()):
		var gen = Globals.generators[i]
		#print(gen.defect_count)
		var frac: float = gen.defect_count / gen.defect_lose_threshold
		#print('frac for generator ', i, ' is ', frac)
		bars[i].set_blend_shape_value(0, frac)
	
