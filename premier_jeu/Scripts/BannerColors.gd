extends Label

var count : int = 0

var colors = [Color("ff1800"),Color("22fa04"),Color("f10ced"),Color("0e0cf1"),Color("f8b606"),Color("dfff00"),Color("6316c0")]
func _ready():
	$Timer.connect("timeout",self,"change_color")
	
func change_color():
	if (count == 6)  :
		count = 0
	else  :
		count =  count +  1
	
	add_color_override("font_color",colors[count])


