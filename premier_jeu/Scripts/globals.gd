extends Node

var shape = "none"


var blue = [Color("1816c1"),Color("021491"),Color("3836d6")]
var yellow = [Color("fff500"),Color("898a0b"),Color("fffc50")]
var red = [Color("cc3048"),Color("9c1b4d"),Color("e44a4a")]
var green = [Color("16b104"),Color("197e00"),Color("5cdf54"),]

var head_band = [red,blue,green,yellow]

func trasform_to(name):
	shape = name

func quitTransform():
	shape = "none"
	

