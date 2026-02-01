extends VBoxContainer

@export var progress_bars : Array[ProgressBar]

func _ready() -> void:
	if (Globals.generators.is_empty()): return
	
	for i in range(Globals.generators.size()):
		var gen = Globals.generators[i]
		progress_bars[i].max_value = gen.defect_lose_threshold

func _physics_process(delta: float) -> void:
	if (Globals.generators.is_empty()): return
	
	for i in range(Globals.generators.size()):
		var bar = progress_bars[i]
		var gen = Globals.generators[i]
		#print('Generator ' + str(i) + ' has ' + str(gen.defect_count) + ' defects, max is ' + str(gen.defect_lose_threshold))
		bar.value =  gen.defect_lose_threshold - gen.defect_count
