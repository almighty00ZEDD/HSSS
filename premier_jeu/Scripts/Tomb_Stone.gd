extends KinematicBody2D

var speed : Vector2 = Vector2(0,300)
const where_floor = Vector2(0,-1)

func _ready():

# warning-ignore:return_value_discarded
	Globals.connect("destroy_tombstones",self,"on_destroy_tombstones")
	$particles.emitting = true

# warning-ignore:unused_argument
func _process(delta):
# warning-ignore:return_value_discarded
	move_and_slide(speed ,where_floor)
	

func setPosition(coord):
	global_position = coord
	
func on_destroy_tombstones() -> void  :
	queue_free()
