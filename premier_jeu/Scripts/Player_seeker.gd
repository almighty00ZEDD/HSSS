extends KinematicBody2D

var velocite = Vector2()
var speed = 200
var gravity = 300
var jumpCount = 0.4

const MINUTE : float = 60.0
const WAITING_TIME :  float = 10.0
const ROUND_DURATION :  float = 5.0 * MINUTE
const WAITING_FIX_LOG : String = "WAITING FOR THE OTHERS TO HIDE : "

var idle_sprite = preload("res://Sprites/pixel_Advnture_Sprites/Free/Main Characters/Virtual Guy/Idle (32x32).png")
var run_sprite = preload("res://Sprites/pixel_Advnture_Sprites/Free/Main Characters/Virtual Guy/Run (32x32).png")
var bullet : PackedScene = preload("res://PreLoadable/Bullet/Bullet.tscn")

const where_floor = Vector2(0,-1)
var stop_anim = false
onready var delay  : Timer = $send_pos_delay
onready var camera  : Camera2D = $Camera2D
onready var gun : Sprite = $gun
onready var shoot_point : Position2D = $shoot_point
onready var cool_down_delay : Timer = $cool_dewn_delay
onready var waiting  : Timer = $waiting
onready var round_chrono : Timer  = $round_chrono
var Time_logger :  Label

var can_shoot : bool = true
var can_move  =  false

func _ready():	
	velocite.y = gravity
# warning-ignore:return_value_discarded
	delay.connect("timeout",self,"send_position")
	camera.current  =  true
# warning-ignore:return_value_discarded
	cool_down_delay.connect("timeout",self,"on_cool_down")
	waiting.wait_time  = WAITING_TIME
	round_chrono.wait_time = ROUND_DURATION
# warning-ignore:return_value_discarded
	waiting.connect("timeout",self,"on_waiting_over")
# warning-ignore:return_value_discarded
	round_chrono.connect("timeout",self,"on_round_over")
	Time_logger.text = WAITING_FIX_LOG + String(WAITING_TIME)
	Time_logger.show()
	waiting.start()
	
	
func _physics_process(delta):
	 
	if can_move :
		run()
	else :
		Time_logger.text = WAITING_FIX_LOG + String(int(waiting.time_left))
		
	jump(delta)
	#if(Input.is_action_pressed("ui_select")):
	#	setHBColor()
	if Input.is_action_pressed("ui_space"):
		shoot()
		
	
	if velocite.x == 0 and !stop_anim :
		anim_idle()
		
# warning-ignore:return_value_discarded
	move_and_slide(velocite, where_floor)

func anim_idle():
	$Sprite.texture = idle_sprite;
	$anim.playback_speed = 1
	$Sprite.hframes = 11
	$collision_base.position.y -= 5
	gun.position.y = 18
	animate("idlea")
	
func anim_run():
	$Sprite.texture = run_sprite;
	$anim.playback_speed = 2	
	$Sprite.hframes = 12
	gun.position.y = 15
	animate("run")
	
func animate(anim_name):
	if $anim.current_animation == anim_name:
		pass
	else:
		$anim.play(anim_name)

func jump(delta):
	if Input.is_action_pressed("ui_up") and jumpCount == 0.4 and is_on_floor():

		velocite.y = (-gravity) * 1.7
		jumpCount -= delta
	if jumpCount < 0.4 :
		jumpCount -= delta
	
	if jumpCount <= 0 :
		jumpCount = 0.4	
	
	if jumpCount == 0.4 :
		velocite.y = gravity
		
func run():
	if Input.is_action_pressed("ui_right"):
		velocite.x = speed
		$Sprite.flip_h = false
		gun.flip_h = false
		gun.position.x = 13
		shoot_point.position.x = (42)
		anim_run()
		
	elif Input.is_action_pressed("ui_left"):
		velocite.x = (-speed)
		$Sprite.flip_h = true
		gun.flip_h =  true
		gun.position.x = (-13)
		shoot_point.position.x = (-42)
		anim_run()
	else :
		velocite.x = 0


func set_shader_color(color):
	for i in range(3):
		$Sprite.material.set("shader_param/BLUE" + String(i+1),Globals.head_band[color -1 ][i])



func send_position() -> void :
	NetworkManager.send_position_update(global_position)

func send_shoot(dir) -> void :
	NetworkManager.send_shoot(dir)
	
func set_initial_position(pos : Vector2) :
	global_position =   pos
	
func shoot() -> void:
	if not can_shoot:
		return
	
	var b = bullet.instance()
	b.setPosition(shoot_point.global_position)
	var dir = 1
	if gun.flip_h :
		dir = -1
	
	b.setDirection(dir)
	send_shoot(dir)
	#add_child(b)
	get_parent().add_child(b)
	can_shoot = false
	cool_down_delay.start()
	
func on_cool_down() -> void:
	can_shoot  = true

func on_waiting_over() -> void :
	can_move = true
	Time_logger.hide()

func on_round_over() -> void :
	pass
