extends Node

var player : CharacterBody3D
var health : int
var time := 0.0

signal die(cause: String)
signal take_damage

var generators : Array
func _ready() -> void:
	die.connect(on_die)
	
func on_die(cause: String):
	pass
