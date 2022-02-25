extends KinematicBody2D

var shape
var velocite : Vector2 = Vector2(0,300)
const where_floor = Vector2(0,-1)


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

func _process(delta):
	if not is_on_floor():
		move_and_slide(velocite,where_floor)
	
	
	
func setUp(shape_name):
	shape = shape_name
	input_pickable = true;
	connect("mouse_entered",self,"_on_CWbox_mouse_entered")
	connect("mouse_exited",self,"_on_CWbox_mouse_exited")
