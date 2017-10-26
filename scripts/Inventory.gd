extends CanvasLayer

const SLOT_NONE = 0



onready var panel = get_node("Panel")
var idx = 0
var can_pause = true

var off
func _ready():
	panel.hide()
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("INVENTORY"):
		get_tree().set_pause(!get_tree().is_paused())
		set_process(get_tree().is_paused())
		
		if can_pause and get_tree().is_paused():
			panel.show()
		else:
			panel.hide()
	
