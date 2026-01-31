extends TextureRect

@export var ouch1 : Texture2D
@export var ouch2 : Texture2D
@export var ouch3 : Texture2D
@export var flash_weight : float

@onready var ouch_flash := $OuchFlash

var flashing := false
var timer_start := false
var flash_alpha : float = 1

func _ready() -> void:
	Globals.take_damage.connect(show_ouch_flash)

func _process(delta: float) -> void:
	
	if Globals.health == 4:
		texture = null
	elif Globals.health == 3:
		texture = ouch1
	elif Globals.health == 2:
		texture = ouch2
	elif Globals.health == 1:
		texture = ouch3
		
	if flashing:
		flash_alpha = lerpf(flash_alpha,0,flash_weight)
		ouch_flash.modulate = Color(1.0, 1.0, 1.0, flash_alpha)
		if timer_start == false:
			timer_start = true
			$Timer.start()

func show_ouch_flash():
	flashing = true

func _on_timer_timeout() -> void:
	flashing = false
	ouch_flash.modulate = Color(1,1,1,0)
	flash_alpha = 1
