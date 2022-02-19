extends KinematicBody2D

const vitesse = Vector2(900,0)
const where_floor = Vector2(0,-1)
var direction : int 

func _process(delta):
	if(is_on_ceiling() or is_on_floor() or is_on_wall()):
		self.queue_free()	
	move_and_slide(vitesse * direction ,where_floor)
	
func setPosition(coord):
	position = coord

func setDirection(dir : int):
	direction = dir
	

