extends KinematicBody2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var dir = Vector2()
const vitesse = 200
# Called when the node enters the scene tree for the first time.
func _ready():
	dir = Vector2.ZERO
	pass
	
func _set_dir(direction):
	dir = direction


func _physics_process(delta):
	move_and_slide(dir * vitesse)
