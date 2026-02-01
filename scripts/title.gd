extends Control

@export var mul: Vector2
@export var off: Vector2
@export var scene_path: String

@onready var gas_mask: ColorRect = $ColorRect/GasMask
@onready var mat: ShaderMaterial = gas_mask.material
var pressed := false

var gasmask_off:
	get():
		return mat.get_shader_parameter('gasmask_off')
	set(new):
		mat.set_shader_parameter('gasmask_off', new)

var gasmask_mul:
	get():
		return mat.get_shader_parameter('gasmask_mul')
	set(new):
		mat.set_shader_parameter('gasmask_mul', new)

func _load_scene() -> void:
	while ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
	var scene := ResourceLoader.load_threaded_get(scene_path)
	
	TitleGlobal.add_child(gas_mask.duplicate())
	TitleGlobal.add_child($Postproc.duplicate())
	TitleGlobal.listen = true
	get_tree().change_scene_to_packed(scene)

func _on_start_game_pressed() -> void:
	if pressed:
		return
	pressed = true
	
	var loader := ResourceLoader.load_threaded_request(scene_path, 'PackedScene', true)
	
	var tween := create_tween()
	tween.tween_property($ColorRect/Label, 'modulate:a', 0.0, 0.5)
	tween.parallel().tween_property($ColorRect/StartGame, 'modulate:a', 0.0, 0.5)
	tween.parallel().tween_property($ColorRect/Generator, 'modulate:a', 0.0, 0.5)
	
	tween.tween_property(self, 'gasmask_off', off, 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(self, 'gasmask_mul', mul, 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func(): _load_scene())
