extends Node3D

@onready var flashlight: SpotLight3D = $SpotLight3D
@export var canvas: CanvasLayer
@export var texture_outer: TextureRect
@export var texture_inner: TextureRect

var _wide_range = 10
var _wide_energy = 5
var _wide_angle = 40
var _wide_scale = 2
var _wide_rot = 90
var _wide_outer_rot = 30

var _tight_range = 40
var _tight_energy = 30
var _tight_angle = 15
var _tight_scale = 0.4
var _tight_rot = 0

enum FlashlightState {
	WIDE, TIGHT
}

var _state: FlashlightState = FlashlightState.WIDE

func _set_flashlight(state: FlashlightState) -> void:
	#_state = state
	if state == FlashlightState.WIDE:
		flashlight.light_energy = lerpf(flashlight.light_energy, _wide_energy, 0.5)
		flashlight.spot_angle = lerpf(flashlight.spot_angle, _wide_angle, 0.5)
		flashlight.spot_range = lerpf(flashlight.spot_range, _wide_range, 0.5)
		texture_outer.scale.x = lerpf(texture_outer.scale.x, _wide_scale, 0.5)
		texture_outer.scale.y = lerpf(texture_outer.scale.y, _wide_scale, 0.5)
		texture_inner.rotation_degrees = lerpf(texture_inner.rotation_degrees, _wide_rot, 0.5)
		texture_outer.rotation_degrees = lerpf(texture_outer.rotation_degrees, _wide_outer_rot, 0.5)
	else:
		flashlight.light_energy = lerpf(flashlight.light_energy, _tight_energy, 0.5)
		flashlight.spot_angle = lerpf(flashlight.spot_angle, _tight_angle, 0.5)
		flashlight.spot_range = lerpf(flashlight.spot_range, _tight_range, 0.5)
		texture_outer.scale.x = lerpf(texture_outer.scale.x, _tight_scale, 0.5)
		texture_outer.scale.y = lerpf(texture_outer.scale.y, _tight_scale, 0.5)
		texture_inner.rotation_degrees = lerpf(texture_inner.rotation_degrees, _tight_rot, 0.5)
		texture_outer.rotation_degrees = lerpf(texture_outer.rotation_degrees, _tight_rot, 0.5)

func _process(delta: float) -> void:
	if (Input.is_action_just_pressed("flashlight")):
		flashlight.visible = !flashlight.visible
		canvas.visible = !canvas.visible
		
	# Widen light
	if (Input.is_action_just_pressed("flashlight_scroll_up")):
		_state = FlashlightState.WIDE
		
	# Tighten light
	elif (Input.is_action_just_pressed("flashlight_scroll_down")):
		_state = FlashlightState.TIGHT
	
	# Toggle light
	if (Input.is_action_just_pressed("flashlight_toggle")):
		_state = FlashlightState.TIGHT if _state == FlashlightState.WIDE else FlashlightState.WIDE
	
	_set_flashlight(_state)
	
