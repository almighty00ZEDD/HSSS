extends KinematicBody2D

var next_position = global_position
var idle_sprite = preload("res://Sprites/pixel_Advnture_Sprites/Free/Main Characters/Virtual Guy/Idle (32x32).png")
var run_sprite = preload("res://Sprites/pixel_Advnture_Sprites/Free/Main Characters/Virtual Guy/Run (32x32).png")
var bullet : PackedScene = preload("res://PreLoadable/Bullet/Bullet.tscn")
var tomb_stone = preload("res://PreLoadable/Tombstone/Tomb_Stone.tscn")

var stop_anim = false
var _shape : String

onready var gun : Sprite = $gun
onready var shoot_point : Position2D = $shoot_point
onready var tween : Tween = $Tween

var transformed : bool = false
var transformed_sprite = null
var transformed_collider = null
var shader_color : int

var bullets = []
# warning-ignore:unused_argument
func _physics_process(delta):
	run()
	
func anim_idle():
	$Sprite.texture = idle_sprite;
	$anim.playback_speed = 1
	$Sprite.hframes = 11
	$Sprite.position = Vector2(0,2)
	gun.position.y = 18
	animate("idlea")
# warning-ignore:return_value_discarded
	connect("mouse_entered",self,"_on_CWbox_mouse_entered")
# warning-ignore:return_value_discarded
	connect("mouse_exited",self,"_on_CWbox_mouse_exited")
	
func anim_run():
	$Sprite.texture = run_sprite;
	$anim.playback_speed = 2	
	$Sprite.hframes = 12
	$Sprite.position = Vector2.ZERO
	gun.position.y = 15
	animate("run")
	
func animate(anim_name):
	if $anim.current_animation == anim_name:
		pass
	else:
		$anim.play(anim_name)
		
func run():
	
# warning-ignore:return_value_discarded
	tween.interpolate_property(self,"global_position",global_position,next_position,0.1)
# warning-ignore:return_value_discarded
	tween.start()
	
	if stepify(global_position.x,0.01) == stepify(next_position.x,0.01) :
		anim_idle()
	
	if global_position.x  < next_position.x:
		
		$Sprite.flip_h = false
		gun.flip_h = false
		gun.position.x = 13
		shoot_point.position.x = (42)
		anim_run()
		
	if global_position.x  > next_position.x:
		
		$Sprite.flip_h = true
		gun.flip_h =  true
		gun.position.x = (-13)
		shoot_point.position.x = (-42)
		anim_run()
	


func set_shader_color(color):
	for i in range(3):
		$Sprite.material.set("shader_param/BLUE" + String(i+1),Globals.head_band[color - 1][i])
	shader_color = color
		
func set_initial_position(pos : Vector2) :
	global_position =   pos

func set_next_position(pos : Vector2):
	next_position  = pos
	
func shoot(dir) -> void :
	var b = bullet.instance()
	b.setPosition(shoot_point.global_position)
	b.setDirection(dir)
	b.set_shader_color(shader_color)
	bullets.append(b)
	get_parent().add_child(b)

func render() -> void :
	$Camera2D.current = true
	
func transformation_manoeuvre(shape  : String):
	
	if shape == "none":
		stopTransformation()
	
	else :	
		var res = detectCollision(shape)
		if(res == 0): 
			return
		else:
			input_pickable = true
			changeAppearance(res)
		transformed = true
		transformed_collider.position = $collision_base.position 
		transformed_sprite.position = $collision_base.position
		add_child(transformed_collider)
		add_child(transformed_sprite)
		transformation()
		#$particles.emitting = true
	

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
		_shape = "CWBox"
		return 1
	if(not (col_name.find("Tonneau",0) == -1)):
		_shape = "Tonneau"
		return 2
	if(not (col_name.find("Treasure",0) == -1)):
		_shape = "Treasure"
		return 3
		
	return 0
	
func stopTransformation():
	input_pickable = false
	$collision_base.disabled = false
	$Sprite.visible = true
	#$particles.emitting = true pas nécéssaire
	transformed_sprite.queue_free()
	transformed_collider.queue_free()
	gun.show()
	transformed = false

func transformation():
	$collision_base.disabled = true
	$Sprite.visible = false
	gun.hide()
	
func die_c() -> void  :
	for inst in bullets:
		if is_instance_valid(inst):
			inst.queue_free()
	bullets.clear()
	if transformed :
		stopTransformation()
	var ts = tomb_stone.instance()
	ts.setPosition(self.global_position)
	get_parent().add_child(ts)
	queue_free()

func _on_CWbox_mouse_entered():

	Globals.trasform_to(_shape)
	modulate.r = 2.2
	modulate.g = 2.2
	modulate.b = 2.2
	

func _on_CWbox_mouse_exited():

	Globals.quitTransform()
	modulate.r = 1
	modulate.g = 1
	modulate.b = 1
