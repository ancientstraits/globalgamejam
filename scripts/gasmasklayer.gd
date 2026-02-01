extends CanvasLayer

var gasmask_off: Vector2 = Vector2.ZERO
var gasmask_mul: Vector2 = Vector2.ZERO

var initial_gasmask_off: Vector2
var initial_gasmask_mul: Vector2

var mat: ShaderMaterial

func _ready():
	mat = $ColorRect.material
	initial_gasmask_off = mat.get_shader_parameter('gasmask_off')
	initial_gasmask_mul = mat.get_shader_parameter('gasmask_mul')

func _process(delta: float) -> void:
	if not $'..'.player_won:
		mat.set_shader_parameter('gasmask_off', initial_gasmask_off + gasmask_off)
		mat.set_shader_parameter('gasmask_mul', initial_gasmask_mul + gasmask_mul)
