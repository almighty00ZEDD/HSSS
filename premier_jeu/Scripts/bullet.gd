extends KinematicBody2D

const vitesse = Vector2(600,0)
const where_floor = Vector2(0,-1)
var direction : int = 1


func _process(delta):	
	var collision = move_and_collide(vitesse * delta * direction)
	if collision :
		if collision.collider.has_method("die"):
			collision.collider.die()
		queue_free()
			
func setPosition(coord):
	position = coord

func setDirection(dir : int):
	direction = dir
	

