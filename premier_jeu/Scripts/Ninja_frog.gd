extends KinematicBody2D

var velocite = Vector2()
var speed = 200
var gravity = 200
const MAX_JUMP  =  0.55
var jumpCount 
var bullets = []


var idle_sprite = preload("res://Sprites/pixel_Advnture_Sprites/Free/Main Characters/Ninja Frog/Idle (32x32).png")
var run_sprite = preload("res://Sprites/pixel_Advnture_Sprites/Free/Main Characters/Ninja Frog/Run (32x32).png")
var bullet : PackedScene = preload("res://PreLoadable/Bullet/Bullet.tscn")

onready var gun : Sprite = $gun
onready var shoot_point : Position2D = $shoot_point
onready var cool_down_delay : Timer = $cool_dewn_delay

const where_floor = Vector2(0,-1)
var stop_anim = false
var jumpc = 2
var transformed = false
var tombstone : PackedScene = preload("res://PreLoadable/Tombstone/Tomb_Stone.tscn")
var shape : String

var transformed_sprite = null
var transformed_collider = null
var can_shoot : bool = true

func _ready():	
	velocite.y = gravity
	jumpCount  = MAX_JUMP
	cool_down_delay.connect("timeout",self,"on_cool_down")
	connect("mouse_entered",self,"_on_CWbox_mouse_entered")
	connect("mouse_exited",self,"_on_CWbox_mouse_exited")


func _physics_process(delta):
	 
	#running manoeuvre
	run()
	if(is_on_floor()):
		velocite.y  =  0
		jumpc = 2
		
	#jumping manoeuvre
	quit_transformation()
	jump(delta)
	
	if Input.is_action_pressed("ui_space"):
		shoot()
		
	#ajouter au player et characters des la mort ces bullets douvent disparaitre
	#pour ajouter une petite anim a la fun du match
	if Input.is_action_pressed("right_click"):
		for bullet in bullets:
			if is_instance_valid(bullet):
				bullet.queue_free()
		bullets.clear()
	
	transformation_manoeuvre()
	
	if abs(velocite.x) == 0 and !stop_anim :
		anim_idle()
		
	var alteredVelocity = move_and_slide(velocite, where_floor)
	if (alteredVelocity.y == 0) and (velocite.y < 0) and is_on_floor():
		alteredVelocity.y = velocite.y
	velocite = alteredVelocity

func anim_idle():
	if(transformed):
		return
	$Sprite.texture = idle_sprite;
	$anim.playback_speed = 1
	$Sprite.hframes = 11
	$Sprite.position = Vector2(0,2)
	animate("idlea")
	
func anim_run():
	if(transformed):
		return
	$Sprite.texture = run_sprite;
	$anim.playback_speed = 2
	$Sprite.hframes = 12
	$Sprite.position = Vector2.ZERO
	animate("run")
	
func animate(anim_name):
	if $anim.current_animation == anim_name:
		pass
	else:
		$anim.play(anim_name)

func jump(delta):
	if Input.is_action_pressed("ui_up") and jumpCount == MAX_JUMP and is_on_floor():
		jumpc -=1
		velocite.y = (-gravity) * 1.7
		jumpCount -= delta
	if jumpCount < MAX_JUMP :
		jumpCount -= delta
	if jumpCount <= 0 :
		jumpCount = MAX_JUMP
		if(jumpc > 1):
			jumpCount = MAX_JUMP
	if jumpCount == MAX_JUMP :
		jumpc = 2
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

func quit_transformation():
	if(Input.is_action_pressed("ui_down")):
		if(transformed):
			stopTransformation()
			input_pickable  = false
			gun.show()



func transformation_manoeuvre():
	if Input.is_action_just_pressed("ui_click"):
		print(shape)
		if(Globals.shape != "none" and not transformed):
	
			var res = detectCollision(Globals.shape)

			if(res == 0): 
				return
			else:
				input_pickable = true
				changeAppearance(res)
			#++ pour l'ancien seeker
			gun.hide()
			transformed = true
			transformed_collider.position = $collision_base.position 
			transformed_sprite.position = $collision_base.position
			add_child(transformed_collider)
			add_child(transformed_sprite)
			transformation()
			$particles.emitting = true
	

func changeAppearance(num):
	if(num == 1):
		transformed_collider = preload("res://PreLoadable/Transformables/colliderCWbox.tscn").instance()
		transformed_sprite = preload("res://PreLoadable/Transformables/spriteCWbox.tscn").instance()
	
	if(num == 2):
		transformed_collider = preload("res://PreLoadable/Transformables/colliderTonneau.tscn").instance()
		transformed_sprite = preload("res://PreLoadable/Transformables/spriteTonneau.tscn").instance()

	if(num == 3):
		transformed_collider = preload("res://PreLoadable/Transformables/colliderTreasure.tscn").instance()
		transformed_sprite = preload("res://PreLoadable/Transformables/spriteTreasure.tscn").instance()

func detectCollision(col_name):
	if(not (col_name.find("CWBox",0) == -1)):
		shape = "CWBox"
		return 1
	if(not (col_name.find("Tonneau",0) == -1)):
		shape = "Tonneau"
		return 2
	if(not (col_name.find("Treasure",0) == -1)):
		shape = "Treasure"
		return 3
		
	return 0
	
func stopTransformation():
	$collision_base.disabled = false
	$Sprite.visible = true
	$particles.emitting = true
	transformed_sprite.queue_free()
	transformed_collider.queue_free()
	transformed = false

func transformation():
	$collision_base.disabled = true
	$Sprite.visible = false

func shoot() -> void:
	if can_shoot and (not transformed):
		var  mouse_pos :  Vector2  = get_global_mouse_position()
		var dir : int = 1
		if $Sprite.flip_h :
			dir = - 1
	
		var b = bullet.instance()
		b.setPosition(shoot_point.global_position)
		b.setDirection(dir)
		b.set_shader_color(2)
		bullets.append(b)
		get_parent().add_child(b)
		can_shoot = false
		cool_down_delay.start()

func on_cool_down() -> void:
	can_shoot  = true

func _on_CWbox_mouse_entered():

	Globals.trasform_to(shape)
	modulate.r = 2.2
	modulate.g = 2.2
	modulate.b = 2.2
	

func _on_CWbox_mouse_exited():

	Globals.quitTransform()
	modulate.r = 1
	modulate.g = 1
	modulate.b = 1
