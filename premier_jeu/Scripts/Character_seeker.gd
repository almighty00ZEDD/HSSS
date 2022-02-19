extends KinematicBody2D

var next_position = global_position
var idle_sprite = preload("res://Sprites/pixel_Advnture_Sprites/Free/Main Characters/Virtual Guy/Idle (32x32).png")
var run_sprite = preload("res://Sprites/pixel_Advnture_Sprites/Free/Main Characters/Virtual Guy/Run (32x32).png")
var bullet : PackedScene = preload("res://PreLoadable/Bullet/Bullet.tscn")


var stop_anim = false
var id

onready var camera  : Camera2D = $Camera2D
onready var gun : Sprite = $gun
onready var shoot_point : Position2D = $shoot_point
onready var tween : Tween = $Tween



func _ready():	
	pass
	
func _physics_process(delta):
	run()
	
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
		
func run():
	
	tween.interpolate_property(self,"global_position",global_position,next_position,0.1)
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
	
func set_initial_position(pos : Vector2) :
	global_position =   pos

func set_next_position(pos : Vector2):
	next_position  = pos
	
func shoot(dir) -> void :
	var b = bullet.instance()
	b.setPosition(shoot_point.global_position)
	b.setDirection(dir)
	get_parent().add_child(b)
