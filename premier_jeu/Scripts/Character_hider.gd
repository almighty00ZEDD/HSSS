extends KinematicBody2D

var next_position  = global_position
onready var tween  :  Tween = $Tween

var idle_sprite = preload("res://Sprites/pixel_Advnture_Sprites/Free/Main Characters/Ninja Frog/Idle (32x32).png")
var run_sprite = preload("res://Sprites/pixel_Advnture_Sprites/Free/Main Characters/Ninja Frog/Run (32x32).png")
var tomb_stone = preload("res://PreLoadable/Tombstone/Tomb_Stone.tscn")

var stop_anim = false
var transformed = false
var transformed_sprite = null
var transformed_collider = null

signal died(ts,is_player)

func _ready():	
	#velocite.y = gravity
	pass

func _physics_process(delta):
	 
	run()
	

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

		
func set_next_position(pos : Vector2):
	next_position  = pos

func run():
	tween.interpolate_property(self,"global_position",global_position,next_position,0.1)
	tween.start()
	
	if stepify(global_position.x,0.01) == stepify(next_position.x,0.01) :
		anim_idle()
	
	if global_position.x  < next_position.x:
		$Sprite.flip_h = false
		anim_run()
		
	if global_position.x  > next_position.x:
		$Sprite.flip_h = true
		anim_run()

func transformation_manoeuvre(shape  : String):
	
	if shape == "none":
		stopTransformation()
	
	else :	
		var res = detectCollision(shape)
		if(res == 0): 
			return
		else:
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
	#$particles.emitting = true pas nécéssaire
	transformed_sprite.queue_free()
	transformed_collider.queue_free()
	transformed = false

func transformation():
	$collision_base.disabled = true
	$Sprite.visible = false

func set_shader_color(color):
	$particles.process_material.set("color",NetworkManager._COLORS[color])
	for i in range(3):
		$Sprite.material.set("shader_param/BLUE" + String(i+1),Globals.head_band[color - 1][i])

func set_initial_position(pos : Vector2) :
	global_position =   pos

func die_c() -> void  :
	if transformed :
		stopTransformation()
	var ts = tomb_stone.instance()
	ts.setPosition(self.global_position)
	get_parent().add_child(ts)
	emit_signal("died",ts,false)
	queue_free()
