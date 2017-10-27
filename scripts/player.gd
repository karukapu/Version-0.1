extends KinematicBody2D

var meleeEffectScene = preload("res://scenes/effects/melee_attack.scn")
var bulletScene = preload("res://scenes/bullet.xml")

const STATE_PLAYING = 1
const STATE_DEAD = 2
const STATE_WIN = 4

var state = 1

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
#			
#		
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
func _custom_debug_print():
	_custom_debug_calls += 1
	print("custom debug called: .. ", _custom_debug_calls, " ", "times")
	print("old anim name: ........ ", anim)
	print("new anim name: ........ ", newAnim)
	print("player facing enum:.... ", facing)
	print("-")
# }


func _fixed_process(delta):
	if state == STATE_PLAYING:
		
		
		var newAnim = ""
		
		var moveUp = Input.is_action_pressed("ui_up")
		var moveDown = Input.is_action_pressed("ui_down")
		var moveLeft = Input.is_action_pressed("ui_left")
		var moveRight = Input.is_action_pressed("ui_right")
		
		var attackInput = Input.is_action_pressed("ATTACK")
		var shootInput = Input.is_action_pressed("ATTACK2")
		
		var moving = moveUp or moveDown or moveLeft or moveRight
		
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
		
#		#Facing direction
#		if leftFacing and velocity.x < 0:
#			set_scale(Vector2(-1, 1))
#		elif not leftFacing and velocity.x > 0:
#			set_scale(Vector2(1, 1))
		
		#Rotation
		if moving:
			direction = moveDir
			
			newAnim = ""
			animNode.set_speed(1.25)
			
			var ang = atan2(direction.x, direction.y)
			if facing == FACING_LEFT and velocity.x < 0:
				ang = atan2(direction.y, direction.x) - deg2rad(90)
			
#			get_node("GroundOffset/Arrow").set_rot(ang)
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
#		
		attacking = attackInput
#		
		if can_attack and shootInput and not shooting:
			can_attack = false
			get_node("Attack Cooldown").start()
			
			
			var bul = bulletScene.instance()
			get_parent().add_child(bul)
			bul.set_pos(get_pos())
			bul.fire(direction)
		
		shooting = shootInput
		
		if not can_attack and FACING_UP:
			newAnim = "Attack_Up"
		if not can_attack and FACING_DOWN:
			newAnim = "Attack_Down"
		if not can_attack and FACING_LEFT:
			newAnim = "Attack_Left"
		if not can_attack and FACING_RIGHT:
			newAnim = "Attack_Right"
		
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
			
		if moveDown:
			newAnim = "Walk_Down"
			
		if moveLeft:
			newAnim = "Walk_Left"
			
		if moveRight:
			newAnim = "Walk_Right"
		
		if newAnim != anim:
			# this block is run if animation was updated.
			_custom_debug_print()
			anim = newAnim
			animNode.play(anim)

func _on_Attack_Cooldown_timeout():
	can_attack = true


func _on_Damaged_Timer_timeout():
	is_hurt = false
	get_node("Player Sprite").set_modulate(Color(1,1,1,1))

