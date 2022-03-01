extends Node2D

onready var  UI :  CanvasLayer = $UI
onready var timer_grace_seconds = $round_grace_seconds

var PlayersInfos : Control   =  preload("res://Scenes/Lobby.tscn").instance()
var characters : Dictionary = {}

var player_scene : PackedScene = preload("res://PreLoadable/Characters/Pseeker.tscn")
var character_scene : PackedScene = preload("res://PreLoadable/Characters/Cseeker.tscn")

var box  : PackedScene = preload("res://PreLoadable/Transformables/CWbox.tscn")
var tonneau  : PackedScene =  preload("res://PreLoadable/Transformables/Tonneau.tscn")
var treasure : PackedScene =  preload("res://PreLoadable/Transformables/Treasure.tscn")

var spawn_positions : Dictionary = {}
var round_transformables  =  []

onready var pos_spawn1  :  Position2D = $pos_spawn1
onready var pos_spawn2  :  Position2D  = $pos_spawn2
onready var pos_spawn3  :  Position2D  = $pos_spawn3
onready var pos_spawn4  :  Position2D  = $pos_spawn4

onready var gen_point1 : Position2D = $gen_point1
onready var gen_point2 : Position2D = $gen_point2
onready var gen_point3 : Position2D = $gen_point3
onready var gen_point4 : Position2D = $gen_point4
onready var gen_point5 : Position2D = $gen_point5
onready var gen_point6 : Position2D = $gen_point6
onready var gen_point7 : Position2D = $gen_point7
onready var gen_point8 : Position2D = $gen_point8

var points  =  []
const LENGTHS = [470,650,300,550,600,900,570,700]
const NB_OBJS  = [8,15,6,12,12,25,12,16]

var _player = null

func _ready():
	spawn_positions["1"] = pos_spawn1.position
	spawn_positions["2"] = pos_spawn2.position
	spawn_positions["3"] = pos_spawn3.position
	spawn_positions["4"] = pos_spawn4.position
	points = [gen_point1,gen_point2,gen_point3,gen_point4,gen_point5,gen_point6,gen_point7,gen_point8]

	UI.add_child(PlayersInfos)
	
	timer_grace_seconds.connect("timeout",self,"on_grace_seconds_over")
# warning-ignore:return_value_discarded
	NetworkManager.connect("previous_presences",self,"_on_networkmanager_presences_changed")
# warning-ignore:return_value_discarded
	NetworkManager.connect("presences_disconnections",self,"_on_presences_disconnections")
# warning-ignore:return_value_discarded
	NetworkManager.connect("new_presence",self,"add_new_presence")
# warning-ignore:return_value_discarded
	NetworkManager.connect("my_color_received",self,"set_my_color")
# warning-ignore:return_value_discarded
	NetworkManager.connect("presence_ready",self,"on_presence_ready")
	if not (NetworkManager._user_name  ==  null)  :
		PlayersInfos.add_player(NetworkManager.get_user_id(),0,NetworkManager._user_name,"connected",0)
	NetworkManager.send_my_presence_info()
	NetworkManager.send_previous_joined_presences()
	
# warning-ignore:return_value_discarded
	NetworkManager.connect("match_start",self,"on_match_start")
# warning-ignore:return_value_discarded
	NetworkManager.connect("pos_received",self,"on_pos_received")
# warning-ignore:return_value_discarded
	NetworkManager.connect("pos_received",self,"on_pos_received")
# warning-ignore:return_value_discarded
	NetworkManager.connect("transformation",self,"on_transformation")
# warning-ignore:return_value_discarded
	NetworkManager.connect("shoot",self,"on_shoot")
# warning-ignore:return_value_discarded
	NetworkManager.connect("character_dead",self,"on_character_dead")
# warning-ignore:return_value_discarded
	NetworkManager.connect("stop_match",self,"on_stop_match")


func show_playersInfos()  -> void  :
	PlayersInfos.visible  =  true

func hide_playersInfos()  ->  void :
	PlayersInfos.visible  =  false 


func _on_networkmanager_presences_changed() :
	var presences  := NetworkManager._presences
	var nicknames := NetworkManager._nicknames
	var victories  := NetworkManager._victories
	var colors :=  NetworkManager._colors
	var game_states := NetworkManager._game_states
	 
	var res : bool  =   true

		
	for key in presences:
		res = true
		for player in PlayersInfos.players:
			if (player.player_id == key):
				res  =  false
		if res :
			PlayersInfos.add_player(key,colors[key],nicknames[key],game_states[key],victories[key])
	
	
	

func _on_presences_disconnections():
	var presences  := NetworkManager._presences
	 
	var res : bool  =   true
	
	for player in PlayersInfos.players:
		res = true
		for key in presences:
			if(player.player_id == key):
				res = false
		if res and not (player.player_id ==  NetworkManager._session.user_id):
			PlayersInfos.remove_player(player.player_id)
	
	for keyC in characters :
		res  = true
		for keyP in presences :
			if keyC  ==  keyP :
				res = false
		if res and not (characters[keyC]  == null):
			characters[keyC].queue_free()
			characters[keyC] = null
				
func  add_new_presence(id,color,nickname  :  String,game_state,victories)  -> void :
	PlayersInfos.add_player(id,color,nickname,game_state,victories)

func set_my_color(color) -> void :
	PlayersInfos.set_my_color(color)
	
func on_presence_ready(id) -> void :
	PlayersInfos.presence_ready(id)


func on_match_start(server_seed) -> void :
	
	seed(server_seed)
	for i in 8 :
		spawn_random_objects(points[i].position,LENGTHS[i],NB_OBJS[i])

	#hide match info
	PlayersInfos.back_to_connected()
	PlayersInfos.hide()
	
	_player = player_scene.instance()
	_player.set_initial_position(spawn_positions[String(NetworkManager._colors[NetworkManager.get_user_id()])])
	_player.connect("died",self,"on_player_dead")
	_player.set_shader_color(NetworkManager._colors[NetworkManager.get_user_id()])
		
	add_child( _player )

	#setup characters
	for key in NetworkManager._presences.keys() :
		if (not key == NetworkManager.get_user_id()):
			create_character(key)

func create_character(key) :
	characters[key]  = character_scene.instance()
	characters[key].set_initial_position(spawn_positions[String(NetworkManager._colors[key])])
	characters[key].set_shader_color(NetworkManager._colors[key])
	add_child(characters[key])
	
	

func on_pos_received() -> void :
	for key in characters.keys():
		if not (NetworkManager._positions[key]  ==   null) :
			var pos : Vector2 = Vector2(NetworkManager._positions[key].x,NetworkManager._positions[key].y)
			if not (characters[key] == null):
				characters[key].set_next_position(pos)

func on_transformation(shape  : String,id) -> void :
	for key in characters.keys():
		if key == id :
			if not (characters[key] == null):
				characters[key].transformation_manoeuvre(shape)

func on_shoot(dir : int,id) -> void  :
	for key in characters.keys():
		if key == id :
			if not (characters[key] == null):
				characters[key].shoot(dir)


func on_player_dead() -> void:
	for key  in  characters.keys() :
		if is_instance_valid(characters[key]):
			characters[key].render()
			return

func on_character_dead(id) -> void :
	if characters.has(id):
		if is_instance_valid(characters[id]) and characters[id] != null: 
			characters[id].die_c()
			characters[id] = null
		
func on_stop_match(reason) -> void :
	PlayersInfos.display_info(reason)
	timer_grace_seconds.start()
	
func on_grace_seconds_over():
	
	for key in  characters.keys():
		if is_instance_valid(characters[key]):
			characters[key].queue_free()
		characters[key] = null
	
	characters.clear()
	if is_instance_valid(_player):
		_player.queue_free()
	_player = null
	
	PlayersInfos.game_states_on_round_over()
	
	PlayersInfos.update_player_victories()
	PlayersInfos.show()
	
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
		add_child(b)
		b.global_position.x  = start_pos.x  + (length * randf())
		b.global_position.y  = start_pos.y
		
