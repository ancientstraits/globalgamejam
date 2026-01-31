extends Node3D

@export var canvas: CanvasLayer
@export var texture_inner: TextureRect
@export var texture_outer: TextureRect
@onready var initial_texture_scale = texture_inner.scale
@onready var flashlight = $SpotLight3D

var _wide_angle = 70
var _wide_energy = 5
var _wide_range = 5
var _tight_angle = 20
var _tight_energy = 20
var _tight_range = 30

var _tight_scale = 0.25
var _wide_scale = 1.5

func _process(delta):
	if (Input.is_action_just_pressed('flashlight')):
		flashlight.visible = !flashlight.visible
		canvas.visible = !canvas.visible
		
	# Widen flash
	if (Input.is_action_just_pressed('flashlight_scroll_up')):
		flashlight.light_energy = lerpf(flashlight.light_energy, _wide_energy, 0.1)
		flashlight.spot_angle = lerpf(flashlight.spot_angle, _wide_angle, 0.1)
		flashlight.spot_range = lerpf(flashlight.spot_range, _wide_range, 0.1)
		texture_inner.scale.x = lerpf(texture_inner.scale.x, _wide_scale, 0.1)
		texture_inner.scale.y = lerpf(texture_inner.scale.y, _wide_scale, 0.1)
		texture_outer.rotation_degrees = lerpf(texture_outer.rotation_degrees, 90, 0.1)
		
	# Tighten flash
	elif (Input.is_action_just_pressed('flashlight_scroll_down')):
		flashlight.light_energy = lerpf(flashlight.light_energy, _tight_energy, 0.1)
		flashlight.spot_angle = lerpf(flashlight.spot_angle, _tight_angle, 0.1)
		flashlight.spot_range = lerpf(flashlight.spot_range, _tight_range, 0.1)
		texture_inner.scale.x = lerpf(texture_inner.scale.x, _tight_scale, 0.1)
		texture_inner.scale.y = lerpf(texture_inner.scale.y, _tight_scale, 0.1)
		texture_outer.rotation_degrees = lerpf(texture_outer.rotation_degrees, 0, 0.1)
		
	texture_outer.rotation_degrees = clamp(texture_outer.rotation_degrees, 0, 180)
