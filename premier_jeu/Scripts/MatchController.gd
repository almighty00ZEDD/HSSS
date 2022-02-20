extends Node2D

onready var  UI :  CanvasLayer = $UI
var PlayersInfos : Control   =  preload("res://Scenes/Lobby.tscn").instance()
var characters := {}

var player_seeker : PackedScene = preload("res://PreLoadable/Characters/Pseeker.tscn")
var character_seeker : PackedScene = preload("res://PreLoadable/Characters/Cseeker.tscn")

var player_hider : PackedScene = preload("res://PreLoadable/Characters/Phider.tscn")
var character_hider : PackedScene = preload("res://PreLoadable/Characters/Chider.tscn")

var hider_positions : Dictionary = {}
var _seeker_id

onready var pos_hider1  :  Position2D = $pos_hider1
onready var pos_hider2  :  Position2D  = $pos_hider2
onready var pos_hider3  :  Position2D  = $pos_hider3
onready var pos_hider4  :  Position2D  = $pos_hider4

onready var pos_seeker  :  Position2D  = $pos_seeker

onready var time_log : Label = $UI/time_log
var _player

func _ready():
	hider_positions["1"] = pos_hider1.position
	hider_positions["2"] = pos_hider2.position
	hider_positions["3"] = pos_hider3.position
	hider_positions["4"] = pos_hider4.position
	
	UI.add_child(PlayersInfos)
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
	NetworkManager.connect("hider_dead",self,"on_hider_dead")
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


func on_match_start(seeker   :  bool, seeker_id) -> void :
	#hide match info
	PlayersInfos.back_to_connected()
	PlayersInfos.hide()
	
	_seeker_id = seeker_id	
	# setup player
	if seeker :
		_player = player_seeker.instance()
		_player.set_initial_position(pos_seeker.global_position)
		_player.Time_logger  =  time_log
	else :
		_player = player_hider.instance()
		_player.set_initial_position(hider_positions[String(NetworkManager._colors[NetworkManager.get_user_id()])])
		_player.connect("died",self,"on_player_dead")
	
	_player.set_shader_color(NetworkManager._colors[NetworkManager.get_user_id()])
		
	add_child( _player )

	#setup characters
	for key in NetworkManager._presences.keys() :
		if key == seeker_id:
			characters[key]  = character_seeker.instance()
			characters[key].set_initial_position(pos_seeker.global_position)
		else :
			characters[key] = character_hider.instance()
			characters[key].set_initial_position(hider_positions[String(NetworkManager._colors[key])])
		
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

func on_player_dead(ts,is_player) -> void:
	if is_player:
		characters[_seeker_id].render()

func on_hider_dead(id) -> void :
	characters[id].die_c()
	characters[id] = null
		
func on_stop_match(reason) -> void :
	for key in  characters.keys():
		if not (characters[key] ==  null) :
			characters[key].queue_free()
			characters[key] = null
	
	characters.clear()
	if not (_player  ==  null):
		_player.queue_free()
	_player = null

	
	PlayersInfos.announce_winner(reason)
	PlayersInfos.update_player_victories()
	PlayersInfos.show()
	
