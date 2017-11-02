extends KinematicBody2D

var meleeEffectScene = preload("res://scenes/effects/melee_attack.scn")
var bulletScene = preload("res://scenes/bullet.xml")

const STATE_PLAYING = 1
const STATE_DEAD = 2
const STATE_WIN = 4
const STATE_INIT = 99
var state = 99

# godot is broken?
# no but you cannot assing to dictionary in scripts global scope, IT SEEMS
var xorbox = {}
# input_last
#xorbox.moveUp = 0
#xorbox["moveDown"] = 0
#xorbox["moveLeft"] = 0
#xorbox["moveRight"] = 0
#xorbox["attackInput"] = 0
#xorbox["shootInput"] = 0
#
var input_new = {}
#input_new["moveUp"] = 0
#input_new["moveDown"] = 0
#input_new["moveLeft"] = 0
#input_new["moveRight"] = 0
#input_new["attackInput"] = 0
#input_new["shootInput"] = 0

var movement = Vector2()
var velocity = Vector2()

var acc = 20
var dec = 60
var frc = 20
var top = 122

var scaleY = 0.5

var direction = Vector2(0, 1)
const FACING_UP = 1
const FACING_RIGHT = 2
const FACING_DOWN = 3
const FACING_LEFT = 4
var facing = FACING_DOWN

var anim = "Idle"
var newAnim = "Idle"

onready var animNode = get_node("Anim")

var attacking = false
var can_attack = true
var shooting = false

var maxHealth = 10
var health = 10
var is_hurt = false

func take_damage(amnt=1):
	if health > 0 and not is_hurt:
		health = clamp(health - amnt, 0, maxHealth)
		
		if health <= 0:
			state = STATE_DEAD
			get_node("/root/Game").set_state(get_node("/root/Game/").STATE_LOSE)
		else:
			is_hurt = true
			get_node("Damaged Timer").start()

func heal(amnt=2):
	if health < maxHealth:
		health = clamp(health + amnt, 0, maxHealth)
		return true
	
	return false

func get_dead():
	return (state == STATE_DEAD)

func do_attack():
	var areas = get_node("AttackAxis/Punch").get_overlapping_areas()
	var punchhit = false
	for i in range(areas.size()):
		var target = areas[i]
		if target.is_in_group("Enemy Damage Area"):
			target.get_parent().take_damage(get_pos())
			punchhit = true

func _ready():
	set_fixed_process(true)

# laurin debug print {
var _custom_debug_calls = 0
func _custom_debug_print_multiline():
	_custom_debug_calls += 1
	print("custom debug called: .. ", _custom_debug_calls, " ", "times")
	print("old anim name: ........ ", anim)
	print("new anim name: ........ ", newAnim)
	print("player facing enum:.... ", facing)
	print("-")

func _custom_debug_print_oneline():
	return
	_custom_debug_calls += 1
	var formatstring = "p - calls: %s oanim: %s nanim: %s facingnum: %s -"
	var toprint = formatstring % [_custom_debug_calls, anim, newAnim, facing]
	print(toprint)

func _custom_debug_input_state_print(inputarr):
	var has_input = false
	var index = 0
	var foo
	while (index < inputarr.size()):
		foo = inputarr[index]
		if foo == true:
			has_input = true
			inputarr[index] = 1
		else:
			inputarr[index] = 0
		index += 1
	var formatstring = "ebin - u %s l %s d %s r %s a %s s %s -"
	var toprint = formatstring % inputarr
	if has_input: print(toprint)
# }

func _fixed_process(delta):
	# test hack to get dictionary working
	if state == STATE_INIT:
		# xorbox is definet in start of this file
		xorbox["moveUp"] = 0
		xorbox["moveDown"] = 0
		xorbox["moveLeft"] = 0
		xorbox["moveRight"] = 0
		xorbox["attackInput"] = 0
		xorbox["shootInput"] = 0

		input_new["moveUp"] = null
		input_new["moveDown"] = null
		input_new["moveLeft"] = null
		input_new["moveRight"] = null
		input_new["attackInput"] = null
		input_new["shootInput"] = null
		state = STATE_PLAYING

	if state != STATE_PLAYING:
		return false

	# from now on state is STATE_PLAYING
	var newAnim = ""
		
	# get input state: {
	# save last state
	for key in xorbox:
		xorbox[key] = input_new[key]

	# read new state
	input_new["moveUp"] = Input.is_action_pressed("ui_up")
	input_new["moveDown"] = Input.is_action_pressed("ui_down")
	input_new["moveLeft"] = Input.is_action_pressed("ui_left")
	input_new["moveRight"] = Input.is_action_pressed("ui_right")
	input_new["attackInput"] = Input.is_action_pressed("ATTACK")
	input_new["shootInput"] = Input.is_action_pressed("ATTACK2")

	# resolve state diff:
	var state_diff = false
	for key in xorbox:
		if xorbox[key] != input_new[key]:
			state_diff = true

	# legacy names support hack:
	var moveUp = input_new['moveUp']
	var moveDown = input_new['moveDown']
	var moveLeft = input_new['moveLeft']
	var moveRight = input_new['moveRight']
	var attackInput = input_new['attackInput']
	var shootInput = input_new['shootInput']

	var moving = moveUp or moveDown or moveLeft or moveRight
	if state_diff: _custom_debug_input_state_print([moveUp, moveLeft, moveDown, moveRight, attackInput, shootInput])
	# }

	#Movement X
	if moveLeft:
		facing = FACING_LEFT
		if movement.x > 0:
			movement.x -= dec
		elif movement.x > -top:
			movement.x -= acc
	elif moveRight:
		facing = FACING_RIGHT
		if movement.x < 0:
			movement.x += dec
		elif movement.x < top:
			movement.x += acc
	else:
		movement.x -= min(abs(movement.x), frc) * sign(movement.x)

	#Movement Y
	if moveUp:
		facing = FACING_UP
		if movement.y > 0:
			movement.y -= dec
		elif movement.y > -top:
			movement.y -= acc
	elif moveDown:
		facing = FACING_DOWN
		if movement.y < 0:
			movement.y += dec
		elif movement.y < top:
			movement.y += acc
	else:
		movement.y -= min(abs(movement.y), frc) * sign(movement.y)
	
	#Movement normalized
	var speed = Vector2(abs(movement.x), abs(movement.y))
	var moveDir = movement.normalized()
	velocity = moveDir * speed
	
	if can_attack:
		var motion = velocity * delta
		motion.y *= scaleY
		motion = move(motion)
		
		if is_colliding():
			var normal = get_collision_normal()
			motion = normal.slide(motion)
			motion = move(motion)

	##Facing direction
	#if leftFacing and velocity.x < 0:
	#	set_scale(Vector2(-1, 1))
	#elif not leftFacing and velocity.x > 0:
	#	set_scale(Vector2(1, 1))

	#Rotation
	if moving:
		direction = moveDir
		
		newAnim = ""
		animNode.set_speed(1.25)
		
		var ang = atan2(direction.x, direction.y)
		if facing == FACING_LEFT and velocity.x < 0:
			ang = atan2(direction.y, direction.x) - deg2rad(90)
		
		#get_node("GroundOffset/Arrow").set_rot(ang)
		get_node("AttackAxis").set_rot(ang)

	#Attacking
	if can_attack and attackInput and not attacking:
		can_attack = false
		get_node("Attack Cooldown").start()
		
		do_attack()
		
		var eff = meleeEffectScene.instance()
		get_parent().add_child(eff)
		eff.set_pos(get_node("AttackAxis/Punch").get_global_transform().get_origin())
		eff.set_effect_rot(atan2(direction.x, direction.y))
		eff.set_fast(moving)

	attacking = attackInput
	if can_attack and shootInput and not shooting:
		can_attack = false
		get_node("Attack Cooldown").start()

		var bul = bulletScene.instance()
		get_parent().add_child(bul)
		bul.set_pos(get_pos())
		bul.fire(direction)

	shooting = shootInput

	if not can_attack:
		if facing == FACING_UP: newAnim = "Attack_Up"
		if facing == FACING_DOWN: newAnim = "Attack_Down"
		if facing == FACING_LEFT: newAnim = "Attack_Left"
		if facing == FACING_RIGHT: newAnim = "Attack_Right"

	#Damaged modulate
	if is_hurt:
		get_node("Player Sprite").set_modulate(Color(1,1,1, 0.5 + (0.5 * sin(OS.get_ticks_msec() / 10.0))))

	#Animation
	# remove this line: #print("facing: " + str(facing))

	if facing == FACING_UP:
		#print("Ylos")
		newAnim = "Idle_Up"
		
	if facing == FACING_DOWN:
		#print("Alas")
		newAnim = "Idle_Down"
		
	if facing == FACING_LEFT:
		#print("Vasen")
		newAnim = "Idle_Left"
	
	if facing == FACING_RIGHT:
		#print("Oikee")
		newAnim = "Idle_Right"

	if moveUp:
		newAnim = "Walk_Up"
	elif moveDown:
		newAnim = "Walk_Down"
	elif moveLeft:
		newAnim = "Walk_Left"
	elif moveRight:
		newAnim = "Walk_Right"

	if newAnim != anim and state_diff:
		# this block is run if animation was updated.
		_custom_debug_print_oneline()
		anim = newAnim
		animNode.play(anim)

func _on_Attack_Cooldown_timeout():
	can_attack = true

func _on_Damaged_Timer_timeout():
	is_hurt = false
	get_node("Player Sprite").set_modulate(Color(1,1,1,1))

