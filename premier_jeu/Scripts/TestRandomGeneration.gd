extends Node2D

var box  : PackedScene = preload("res://PreLoadable/Transformables/CWbox.tscn")
var tonneau  : PackedScene =  preload("res://PreLoadable/Transformables/Tonneau.tscn")
var treasure : PackedScene =  preload("res://PreLoadable/Transformables/Treasure.tscn")

onready var gen_point1 : Position2D = $gen_point1
onready var gen_point2 : Position2D = $gen_point2
onready var gen_point3 : Position2D = $gen_point3
onready var gen_point4 : Position2D = $gen_point4
onready var gen_point5 : Position2D = $gen_point5
onready var gen_point6 : Position2D = $gen_point6
onready var gen_point7 : Position2D = $gen_point7
onready var gen_point8 : Position2D = $gen_point8


const LENGTHS = [470,650,300,550,600,900,570,700]
const NB_OBJS  = [8,15,6,12,12,25,12,16]

var server_seed : int  =  1

func _ready():
	var points = [gen_point1,gen_point2,gen_point3,gen_point4,gen_point5,gen_point6,gen_point7,gen_point8]
	seed(server_seed)
	for i in 8 :
		spawn_random_objects(points[i].position,LENGTHS[i],NB_OBJS[i])
 
func spawn_random_objects(start_pos,length,nb_objects):
	for i in nb_objects:
		var b
		
		match randi() % 3 :
			0:
				b = box.instance()
			1:
				b = tonneau.instance()
			2:
				b = treasure.instance()
			
		b.global_position.x  = start_pos.x  + (length * randf())
		b.global_position.y  = start_pos.y
		add_child(b)
