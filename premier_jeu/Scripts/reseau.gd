extends Node2D
var socket = PacketPeerUDP.new()
var joueurs = []

func _ready():
	if(socket.listen(5454) != OK):
		print("erreur listening")
	else :
		print("ecoute du port 5454 sur localhost")
		

func _process(delta):
	if(socket.get_available_packet_count() > 0):
		var data = socket.get_packet().get_string_from_ascii();
		var ip = socket.get_packet_ip()
		if joueurs.has(ip) == false and joueurs.size() < 2 :
			joueurs.push_back(ip)
			print(joueurs.size())
		#$Label.text += data +"\n"
		#socket.get_packet_ip() sert toi en pour multi manettes avec tableau de peers
		
		if joueurs.size() != null:
		#remote movements
			if data == "d":
				if ip == joueurs[0]:
					$remote_frog._set_dir(Vector2.RIGHT)
				else:
					$remote_frog2._set_dir(Vector2.RIGHT)
					
			if data == "g":
				if ip == joueurs[0]:
					$remote_frog._set_dir(Vector2.LEFT)
				else:
					$remote_frog2._set_dir(Vector2.LEFT)
					
			if data == "h":
				if ip == joueurs[0]:
					$remote_frog._set_dir(Vector2.UP)
				else:
					$remote_frog2._set_dir(Vector2.UP)
			if data == "b":
				if ip == joueurs[0]:
					$remote_frog._set_dir(Vector2.DOWN)
				else:
					$remote_frog2._set_dir(Vector2.DOWN)
			if data == "s":
				if ip == joueurs[0]:
					$remote_frog._set_dir(Vector2.ZERO)
				else:
					$remote_frog2._set_dir(Vector2.ZERO)
