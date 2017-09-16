
extends Node2D



func set_effect_rot(ang):
	get_node("Axis").set_rot(ang)


func set_fast(isFast):
	if isFast:
		get_node("AnimationPlayer").play("move fast")


func effectEnd():
	queue_free()

