extends StaticBody2D

var shape

func _on_CWbox_mouse_entered():
	if NetworkManager.seeker  :
		return
		
	Globals.trasform_to(shape)
	modulate.r = 2.2
	modulate.g = 2.2
	modulate.b = 2.2


func _on_CWbox_mouse_exited():
	if NetworkManager.seeker :
		return
		
	Globals.quitTransform()
	modulate.r = 1
	modulate.g = 1
	modulate.b = 1

#func redefineShape(new_shape):
#	shape = new_shape

func setUp(shape_name):
	if NetworkManager.seeker :
		return
		
	shape = shape_name
	input_pickable = true;
	connect("mouse_entered",self,"_on_CWbox_mouse_entered")
	connect("mouse_exited",self,"_on_CWbox_mouse_exited")
