extends Node2D

const usrname = "ZEDD"
onready var _NManager := $NetworkManager

#toujours marquer les fonctions lentes par yield a chaque appel meme si déja fait dans la fonction appelée sinon ça crash :p
func _ready():
	yield(authentificate(),"completed")
	yield(connect_to_server(),"completed")
	yield(join_world(),"completed")

func authentificate() -> void:
	var result : int = yield(_NManager.authentificate_async(),"completed")
	
	if result == OK:
		print("Successful authentification!")
	else:
		print("Failed to authentificate :'( ")
		
func connect_to_server() -> void:
	var result  : int = yield(_NManager.connect_to_server_async(),"completed")
	if result == OK:
		print("Connected to server successfully !!!")
	else:
		print("Could not connect to the server :'( ")

func join_world() -> void :
	var presences: Dictionary =  yield(_NManager.join_world_async(),"completed")
	print("joined the world!")
	print("presences in this world : %s" % [presences.size()])
