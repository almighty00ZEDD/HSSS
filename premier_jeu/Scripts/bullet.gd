extends KinematicBody2D

const vitesse : Vector2 = Vector2(600,0)
const where_floor = Vector2(0,-1)
var direction : int
var start_point  : int
const MAX_DISTANCE : int = 650

func _process(delta):	
	var collision = move_and_collide(vitesse * delta * direction)
	if collision :
		if collision.collider.has_method("die"):
			collision.collider.die()
		queue_free()
	 
	if abs(global_position.x - start_point) > MAX_DISTANCE :
		queue_free()


func setPosition(coord):
	position = coord
	start_point = coord.x

func setDirection(dir : int):
	direction = dir
	
func set_shader_color(color):
	$Sprite.material.set("shader_param/NEW",Color(NetworkManager._COLORS[color]))
