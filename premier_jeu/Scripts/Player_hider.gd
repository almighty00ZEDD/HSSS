extends KinematicBody2D

var velocite = Vector2()
var speed = 200
var gravity = 300
var jumpCount = 0.4

var idle_sprite = preload("res://Sprites/pixel_Advnture_Sprites/Free/Main Characters/Ninja Frog/Idle (32x32).png")
var run_sprite = preload("res://Sprites/pixel_Advnture_Sprites/Free/Main Characters/Ninja Frog/Run (32x32).png")
var tomb_stone = preload("res://PreLoadable/Tombstone/Tomb_Stone.tscn")

const where_floor = Vector2(0,-1)
var stop_anim = false
var jumpc = 2
var transformed = false
var color_num = 0
onready var delay  : Timer = $send_pos_delay
onready var camera  : Camera2D = $Camera2D

var transformed_sprite = null
var transformed_collider = null

signal died(ts,is_player)


func _ready():	
	velocite.y = gravity
# warning-ignore:return_value_discarded
	delay.connect("timeout",self,"send_position")
	camera.current  =  true
	
func _physics_process(delta):
	 
	run()
	if(is_on_floor()):
		jumpc = 2;

	quit_transformation()
	jump(delta)
	
	transformation_manoeuvre()
	
	if velocite.x == 0 and !stop_anim :
		anim_idle()
		
	# warning-ignore:return_value_discarded
	move_and_slide(velocite, where_floor)

func anim_idle():
	if(transformed):
		return
	$Sprite.texture = idle_sprite;
	$anim.playback_speed = 1
	$Sprite.hframes = 11
	$collision_base.position.y -= 5
	animate("idlea")
	
func anim_run():
	if(transformed):
		return
	$Sprite.texture = run_sprite;
	$anim.playback_speed = 2	
	$Sprite.hframes = 12
	animate("run")
	
func animate(anim_name):
	if $anim.current_animation == anim_name:
		pass
	else:
		$anim.play(anim_name)

func jump(delta):
	if Input.is_action_pressed("ui_up") and jumpCount == 0.4 and is_on_floor():
		jumpc -=1
		velocite.y = (-gravity) * 1.7
		jumpCount -= delta
	if jumpCount < 0.4 :
		jumpCount -= delta
	if jumpCount <= 0 :
		jumpCount = 0.4	
		if(jumpc > 1):
			jumpCount = 0.4
	if jumpCount == 0.4 :
		jumpc = 2
		velocite.y = gravity
		
func run():
	if Input.is_action_pressed("ui_right"):
		velocite.x = speed
		$Sprite.flip_h = false
		anim_run()
		
	elif Input.is_action_pressed("ui_left"):
		velocite.x = (-speed)
		$Sprite.flip_h = true
		anim_run()
	else :
		velocite.x = 0

func quit_transformation():
	if(Input.is_action_pressed("ui_down")):
		if(transformed):
			stopTransformation()


func transformation_manoeuvre():
	if Input.is_action_just_pressed("ui_click"):

		if(Globals.shape != "none" and not transformed):
			
			var res = detectCollision(Globals.shape)
			if(res == 0): 
				return
			else:
				changeAppearance(res)
			NetworkManager.send_transformation(Globals.shape)
			transformed = true
			transformed_collider.position = $collision_base.position 
			transformed_sprite.position = $collision_base.position
			add_child(transformed_collider)
			add_child(transformed_sprite)
			transformation()
			$particles.emitting = true
	

func changeAppearance(num):
	if(num == 1):
		transformed_collider = preload("res://PreLoadable/colliderCWbox.tscn").instance()
		transformed_sprite = preload("res://PreLoadable/spriteCWbox.tscn").instance()
	
	if(num == 2):
		transformed_collider = preload("res://PreLoadable/colliderTonneau.tscn").instance()
		transformed_sprite = preload("res://PreLoadable/spriteTonneau.tscn").instance()

func detectCollision(col_name):
	if(not (col_name.find("CWbox",0) == -1)):
		print("found cwbox")
		return 1
	if(not (col_name.find("Tonneau",0) == -1)):
		print("found brique")
		return 2
	return 0
	
func stopTransformation():
	$collision_base.disabled = false
	$Sprite.visible = true
	$particles.emitting = true
	transformed_sprite.queue_free()
	transformed_collider.queue_free()
	transformed = false
	NetworkManager.send_transformation("none")

func transformation():
	$collision_base.disabled = true
	$Sprite.visible = false

func set_shader_color(color):
	$particles.process_material.set("color",NetworkManager._COLORS[color])
	for i in range(3):
		$Sprite.material.set("shader_param/BLUE" + String(i+1),Globals.head_band[color - 1][i])



func send_position() -> void :
	NetworkManager.send_position_update(global_position)
	
func set_initial_position(pos : Vector2) :
	global_position =   pos

func die() -> void:
	if transformed :
		stopTransformation()
	var ts = tomb_stone.instance()
	ts.setPosition(self.global_position)
	get_parent().add_child(ts)
	emit_signal("died",ts,true)
	NetworkManager.send_death()
	queue_free()
