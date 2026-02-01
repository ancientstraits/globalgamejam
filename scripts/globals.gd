extends Node

var game_scene := 'res://scenes/title.tscn'
var player : CharacterBody3D
var health := 4
var time := 0.0

signal die(cause: String)
signal timeout(cause: String)
signal take_damage

var generators : Array
func _ready() -> void:
	die.connect(on_die)
	timeout.connect(on_explode)
	
func on_die(cause: String):
	player.set_cause(cause)
	player.kill()
	
func on_explode(cause: String):
	player.set_cause(cause)
	player.kill()

func restart_game():
	get_tree().paused = false
	Globals.reset_game()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file(game_scene)

func reset_game():
	health = 4
	time = 0
	generators.clear()
