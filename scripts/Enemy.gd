
extends Node2D

var points = []


func _ready():
	set_fixed_process(true)


func _fixed_process(delta):
	# refresh the points in the path
	points = get_tree().get_root().get_node("Game/Level").get_simple_path(get_global_pos(), get_global_mouse_pos(), false)

func _draw():
	# if there are points to draw
	if points.size() > 1:
		for p in points:
			draw_circle(p - get_global_pos(), 8, Color(1, 0, 0,0.5)) # we draw a circle (convert to global position first)



