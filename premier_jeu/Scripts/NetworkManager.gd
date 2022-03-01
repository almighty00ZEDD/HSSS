extends Node

const KEY := "ZEDD_GAME"
var _session  : NakamaSession
var _client  := Nakama.create_client(KEY,"127.0.0.1",7350,"http")
var _socket : NakamaSocket
var _world_id = null

#red, blue ,green, yellow
const _COLORS = ["ffffff","ff0000","2600ff","0cff00","fffd21"]


var _presences := {}
var _nicknames := {}
var _colors := {}
var _game_states := {}
var _victories :=  {}
var _positions  := {}

var _user_name : String 
var in_round : bool = false
var safe_join : bool = false

signal previous_presences
signal presences_disconnections
signal new_presence(id,nickname)
signal my_color_received(color)
signal presence_ready(id)
signal character_dead(id)
signal stop_match(reason)


signal match_start(server_seed)
signal pos_received
signal transformation(shape,id)
signal shoot(dir,id)

#mettre une var seeker pour empecher les boite de s'illuminer quand on est seeker!

#ne pas oublier de changer les numeros correspondant car on changera ces codes de toute façons
#cote serveur dois etre la meme chose que ici niiveau enum et code
enum OpCodes {
	PREVIOUS_PRESENCES = 1,
	NEW_PRESENCE,
	READY_PRESENCE,
	START_ROUND,
	UPDATE_POSITION,
	TRANSFORMATION,
	SHOOT,
	DEATH,
	DECLARE_WINNER,
	ALL_OTHERS_LEFT,
}


#authentification avec  id unique de sa machine (juste une formalité pour éviter la création de comptes)
func authentificate_async() -> int:
	var result := OK
	var deviceid = OS.get_unique_id()
	
	var test_session : NakamaSession = yield(_client.authenticate_device_async(deviceid,null,true),"completed")
	if not test_session.is_exception():
		_session =  test_session
	return result
	
func connect_to_server_async() -> int:
	_socket = Nakama.create_socket_from(_client)
	var result :  NakamaAsyncResult = yield(_socket.connect_async(_session),"completed")
	if not result.is_exception():

		#warning-ignore: return_value_discarded
		_socket.connect("closed", self, "_on_NakamaSocket_closed")
		
		#warning-ignore: return_value_discarded
		_socket.connect("received_match_presence", self, "_on_NakamaSocket_received_match_presence")
	
		#warning-ignore: return_value_discarded
		_socket.connect("received_match_state", self, "_on_NakamaSocket_received_match_state")
		
		return OK
	return ERR_CANT_CONNECT

func _on_nakama_socket_closed() -> void:
	_socket = null

func join_matchmaker():
	var world :  NakamaAPI.ApiRpc = yield(_client.rpc_async(_session,"join_matchmaker",""),"completed")
	if not world.is_exception():
		_world_id = world.payload
	else:
		return("error world id  : %s  ---  exeption  :  %s" % [_world_id, world.get_exception().message])
	
	var match_join_result : NakamaRTAPI.Match  = yield(_socket.join_match_async(_world_id),"completed")	
	if match_join_result.is_exception():
		var exception : NakamaException =  match_join_result.get_exception()
		return("Error joining the match :   %s -  %s"  % [exception.status_code, exception.message])
	else :
		return "OK"

func leave_match_async():
	var match_leave_result : NakamaAsyncResult =  yield(_socket.leave_match_async(_world_id),"completed")
	_world_id   =  null
	if match_leave_result.is_exception() :
		var exception : NakamaException =  match_leave_result.get_exception()
		return("Error joining the match :   %s -  %s"  % [exception.status_code, exception.message])

func create_private_match() -> String:
	var world :  NakamaAPI.ApiRpc = yield(_client.rpc_async(_session,"create_private_match",""),"completed")
	if not world.is_exception():
		_world_id = world.payload 
		print("world id retourné , valeur   : %s " %[_world_id])
		
		var match_join_result : NakamaRTAPI.Match  = yield(_socket.join_match_async(_world_id),"completed")	
		if match_join_result.is_exception():
			var exception : NakamaException =  match_join_result.get_exception()
			printerr("Error joining the match :   %s -  %s"  % [exception.status_code, exception.message])
		
		return _world_id
	else:
		return("error world id  : %s  ---  exeption  :  %s" % [_world_id, world.get_exception().message])
		
	

func join_private_match(input_world_id : String) -> String:
	
	var match_join_result : NakamaRTAPI.Match  = yield(_socket.join_match_async(input_world_id),"completed")
	if match_join_result.is_exception():
		var exception : NakamaException =  match_join_result.get_exception()
		return ("Error joining the match :   %s -  %s"  % [exception.status_code, exception.message])
	else:
		_world_id =  input_world_id
		return "OK"
		
	
func _on_NakamaSocket_received_match_presence(new_presences: NakamaRTAPI.MatchPresenceEvent) -> void :
	
	for leave in new_presences.leaves:
		#warning-ignore: return_value_discarded
		_presences.erase(leave.user_id)
# warning-ignore:return_value_discarded
		_nicknames.erase(leave.user_id)
# warning-ignore:return_value_discarded
		_colors.erase(leave.user_id)
# warning-ignore:return_value_discarded
		_game_states.erase(leave.user_id)
# warning-ignore:return_value_discarded
		_victories.erase(leave.user_id)

	emit_signal("presences_disconnections")
	
func _on_NakamaSocket_received_match_state(match_state: NakamaRTAPI.MatchData)  ->  void :
	
	var code := match_state.op_code
	var raw := match_state.data
	
	#if the player joins in the middle of a round he ignores the gameplay packets
	if (not in_round)  and (code > 4) and (code < 9):
		return

	match code:
		OpCodes.PREVIOUS_PRESENCES:
			var decoded: Dictionary = JSON.parse(raw).result
			var presences: Dictionary = decoded.presences
			var nicknames :  Dictionary = decoded.nicknames
			var colors : Dictionary = decoded.colors
			var game_states : Dictionary = decoded.game_states
			var victories  :  Dictionary =  decoded.victories
			
			for id in presences.keys():
				if not (id ==  get_user_id()) :
					_presences[id]  = presences[id]
					_nicknames[id]  =  nicknames[id]
					_colors[id] = colors[id]
					_game_states[id] = game_states[id]
					_victories[id] =  victories[id]
				
			emit_signal("previous_presences")
	
		OpCodes.NEW_PRESENCE:
			var decoded: Dictionary = JSON.parse(raw).result
			
			if(decoded.id == get_user_id()):
				_colors[decoded.id]  =  decoded.color
				_victories[decoded.id]  =  0  #interne  nouvelle presence  =  0 victoires par default
				_nicknames[decoded.id] =  _user_name
				emit_signal("my_color_received",decoded.color)
				safe_join = true #now we can receive the match start since the server can't start without the player being ready since there's no guarantee start_round would'nt arrive before the player's new_presence
			else :
				_presences[decoded.id] =  decoded.presence
				_nicknames[decoded.id] =  decoded.nickname
				_colors[decoded.id]  =  decoded.color
				_victories[decoded.id]  =  0  #interne  nouvelle presence  =  0 victoires par default
				emit_signal("new_presence",decoded.id,decoded.color,decoded.nickname,"connected",0)
			
		OpCodes.READY_PRESENCE:
			var decoded: Dictionary = JSON.parse(raw).result
			
			if not (decoded.id == get_user_id()) :
				emit_signal("presence_ready",decoded.id)
				
		OpCodes.START_ROUND:
			var decoded: Dictionary = JSON.parse(raw).result
			#when indeed the start round arrived before the server fully registered the player 
			#will crash the game of the other players in this match
			if(not safe_join):
				return
			in_round   = true
			emit_signal("match_start",decoded.seed)
			
		OpCodes.UPDATE_POSITION:
			var decoded: Dictionary = JSON.parse(raw).result
			
			if not decoded.has("positions") :
				return
			
			for key in decoded.positions.keys() :
				if not (key ==  get_user_id()):
					_positions[key] = decoded.positions[key]
				
			emit_signal("pos_received")
			
		OpCodes.TRANSFORMATION:
			var decoded: Dictionary = JSON.parse(raw).result
			
			if decoded.id  == get_user_id():
				return
			
			var shape  = decoded.shape
			emit_signal("transformation",shape,decoded.id)
		
		OpCodes.SHOOT:
			var decoded: Dictionary = JSON.parse(raw).result
			
			if decoded.id == get_user_id():
				return
			
			var dir :  int  =  decoded.direction
			emit_signal("shoot",dir,decoded.id)
		
		OpCodes.DEATH:
			var decoded: Dictionary = JSON.parse(raw).result
			
			if decoded.id == get_user_id():
				return
			
			emit_signal("character_dead",decoded.id)
		
		OpCodes.ALL_OTHERS_LEFT:
			emit_signal("stop_match","ALL THE OTHERS LEFT")
		
		OpCodes.DECLARE_WINNER:
			var decoded: Dictionary = JSON.parse(raw).result
			
			for key  in   _victories.keys():
				_victories[key] = decoded.victories[key]
			
			emit_signal("stop_match",_nicknames[decoded.id] + " WINS!")

			

		
		
	
func send_previous_joined_presences() -> void:
	if _socket:
		var payload := {}
		_socket.send_match_state_async(_world_id, OpCodes.PREVIOUS_PRESENCES, JSON.print(payload))

func send_my_presence_info() -> void:
	if _socket:
		var payload := {id  =  get_user_id() , nickname = _user_name}
		_socket.send_match_state_async(_world_id, OpCodes.NEW_PRESENCE, JSON.print(payload))

func send_ready_state()  -> void:
	if _socket:
		var payload := {id  =  get_user_id()}
		_socket.send_match_state_async(_world_id,OpCodes.READY_PRESENCE, JSON.print(payload))
		
func send_position_update(position: Vector2) -> void:
	if _socket:
		var payload := {id = get_user_id(), pos = {x = position.x, y = position.y}}
		_socket.send_match_state_async(_world_id, OpCodes.UPDATE_POSITION, JSON.print(payload))

func send_transformation(shape: String) -> void:
	if _socket:
		var payload := {id = get_user_id(), shape  =  shape}
		_socket.send_match_state_async(_world_id, OpCodes.TRANSFORMATION, JSON.print(payload))

func send_shoot(dir : int) -> void :
	if _socket:
		var payload := {id = get_user_id(), direction = dir}
		_socket.send_match_state_async(_world_id, OpCodes.SHOOT, JSON.print(payload))

func send_death() -> void :
	if _socket:
		var payload := {id = get_user_id()}
		_socket.send_match_state_async(_world_id, OpCodes.DEATH, JSON.print(payload))

func send_seeker_time_out() -> void :
	if _socket:
		var payload := {}
		_socket.send_match_state_async(_world_id, OpCodes.SEEKER_TIME_OUT, JSON.print(payload))

func get_user_id()  :
	return (_session.user_id)
	
func set_username(username : String) -> void :
	_user_name = username

