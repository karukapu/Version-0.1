
extends Node

var playerKeys = 0 setget set_keys, get_keys


func set_keys(val):
	playerKeys = max(val, 0)


func add_keys(val):
	playerKeys = max(playerKeys + val, 0)


func get_keys():
	return playerKeys


func _ready():
	return
	get_node("Camera2D").set_zoom(Vector2(2,2))
#	OS.set_window_size(OS.get_window_size() * 2)
