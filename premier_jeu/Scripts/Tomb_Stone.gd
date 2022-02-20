extends KinematicBody2D

var speed : Vector2 = Vector2(0,300)
const where_floor = Vector2(0,-1)

func _ready():
	NetworkManager.connect("stop_match",self,"on_match_stop")

func _process(delta):
	move_and_slide(speed ,where_floor)
	

func setPosition(coord):
	global_position = coord
	
func on_match_stop(reason) -> void :
	queue_free()
