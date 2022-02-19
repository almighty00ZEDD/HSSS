extends VBoxContainer

const game_scene : PackedScene  =  preload("res://Scenes/Map1.tscn")

#username section variables
onready var _nickName_le : LineEdit =  $UserNameSelection/HBoxContainer/LineEdit
onready var  _start_btn : Button = $UserNameSelection/nknmButton
onready var _nickname_menu : VBoxContainer =  $UserNameSelection

#main navigation buttons variables
onready var _main_nav_menu : VBoxContainer  =  $MainNavButtons
onready var _pm_join : Button   = $MainNavButtons/Button3
onready var _pm_create : Button = $MainNavButtons/Button2
onready var _random  :  Button  = $MainNavButtons/Button 

#private match join variables
onready var _menu_pmj : VBoxContainer = $PMJoin
onready var _match_id_pmj : LineEdit = $PMJoin/HBoxContainer/LineEdit
onready var _join_pmj : Button = $PMJoin/JoinBtn

#private match create variables
onready var _menu_pmc : VBoxContainer  =  $PMCreation
onready var _pmc_le : LineEdit = $PMCreation/HBoxContainer/LineEdit
onready var _pmc_join_btn  :  Button = $PMCreation/JoinBtn

func _ready():
	_start_btn.connect("pressed",self,"nickname_selected")
	_pm_create.connect("pressed",self,"create_private_match")
	_pm_join.connect("pressed",self,"join_private_match")
	_join_pmj.connect("pressed",self,"join_private_match2")
	_pmc_join_btn.connect("pressed",self,"start_private_match")
	_random.connect("pressed",self,"start_matchmaking")
	
func nickname_selected():
	#keep the nickname somewhere -- use network manager
	var username  : String = _nickName_le.text
	if username == "":
		return
	else:
		yield(NetworkManager.authentificate_async(),"completed")
	NetworkManager.set_username(username)
	yield(NetworkManager.connect_to_server_async(),"completed")
	_nickname_menu.hide()
	_main_nav_menu.show()

func create_private_match():
	var id :  String =  yield(NetworkManager.create_private_match(),"completed")
	if not (id == null):
		_pmc_le.text = id
	_main_nav_menu.hide()
	_menu_pmc.show()
	
func join_private_match():
	_main_nav_menu.hide()
	_menu_pmj.show()
	
func join_private_match2():
	var world_id : String = _match_id_pmj.text
	if(world_id == ""):
		return
	else:
		yield(NetworkManager.join_private_match(world_id),"completed")
	
	get_tree().change_scene_to(game_scene)

func start_private_match() -> void :
	load_match_scene()
	

func load_match_scene()  -> void  :
	get_tree().change_scene_to(game_scene)

func start_matchmaking() -> void :
	yield(NetworkManager.join_matchmaker(),"completed")
	get_tree().change_scene_to(game_scene)
	pass
