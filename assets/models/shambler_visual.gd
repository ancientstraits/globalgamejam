extends Node3D

var rotation_rate: float

func _ready():
    rotation_degrees.y = randf() * PI
    rotation_rate = randf() * 4 + 1
    $AnimationPlayer.play("ArmatureAction")

func _physics_process(float):
    rotation_degrees.y += rotation_rate