extends Control

onready  var PlayersInfos : VBoxContainer = $Panel/PlayersInfos
onready var winnerAnnouncer : Label = $Panel/PlayersInfos/WinnerSentence
onready var readyButton  : Button = $Panel/Button

const playerInfo = preload("res://Scenes/PlayerInfos.tscn")
var players = []

func _ready():
	winnerAnnouncer.text  = ""
# warning-ignore:return_value_discarded
	readyButton.connect("pressed",self,"player_ready")
	

func announce_winner(winner :  String)  -> void :
	winnerAnnouncer.text  =  winner


func add_player(var player_id ,  color ,user_name : String, state  : String, victories) -> void:
	var inst = playerInfo.instance()
	
	players.append(inst)
	var  index : int  =  players.size()  -  1
	PlayersInfos.add_child(players[index])
	
	inst.player_id  =  player_id
	inst.set_username(user_name)
	inst.set_victories(String(victories))
	inst.set_state(state)
	inst.set_color(NetworkManager._COLORS[color])
	

	
func set_my_color(color) -> void :
	for inst  in players :
		if inst.player_id == NetworkManager.get_user_id():
			inst.set_color(NetworkManager._COLORS[color])

	
func remove_player(id) -> void:
	for player  in  players :
		if  player.player_id  == id  :
			players.remove(players.find(player))
			player.queue_free()
	
func player_ready() -> void  :
	for inst  in players :
		if inst.player_id == NetworkManager.get_user_id():
			inst.set_state("Ready")
			NetworkManager.send_ready_state()
			
func presence_ready(id) ->  void :
	for inst  in players :
		if inst.player_id == id :
			inst.set_state("Ready")
	
func back_to_connected() -> void :
	for inst in players   :
		inst.set_state("connected")

func update_player_victories() -> void :
	for key in  NetworkManager._victories.keys():
		for inst in players :
			if key == inst.player_id:
				inst.update_victories(NetworkManager._victories[key])
			
