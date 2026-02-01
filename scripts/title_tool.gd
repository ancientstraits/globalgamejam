@tool
extends Node

@export var set_mask_params: bool:
	set(new):
		var title := get_node('../')
		var scene := load('res://scenes/player.tscn') as PackedScene
		var player := scene.instantiate()
		var crect := player.get_node('Mask/ColorRect') as ColorRect
		var mat := crect.material as ShaderMaterial
		title.mul = mat.get_shader_parameter('gasmask_mul')
		title.off = mat.get_shader_parameter('gasmask_off')
		player.queue_free()
