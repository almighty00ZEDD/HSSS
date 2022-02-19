extends KinematicBody2D


var velocite = Vector2()
var speed = 500
var gravity = 500
var jumpCount = 0.4

# Called when the node enters the scene tree for the first time.
func _ready():
	velocite.y = gravity
	#$camera.limit_left = 402.347
	#$camera.limit_bottom = 201.514
	pass

func _physics_process(delta):
	 
	
	if Input.is_action_pressed("ui_right"):
		velocite.x = speed
		$Sprite.flip_h = false
	elif Input.is_action_pressed("ui_left"):
		velocite.x = (-speed)
		$Sprite.flip_h = true
		
	else :
		velocite.x = 0
		
	if Input.is_action_pressed("ui_up") and jumpCount == 0.4:
		
		velocite.y = (-gravity) * 1.7
		jumpCount -= delta
	if jumpCount < 0.4 :
		jumpCount -= delta
	if jumpCount <= 0 :
		jumpCount = 0.4	
	if jumpCount == 0.4 :
		velocite.y = gravity
	
		
	move_and_slide(velocite)


