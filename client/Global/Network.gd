extends Node
# class_name Network

# region Player Data

# var PLAYER_ID: int = -1
# var PLAYER_NAME: String = ""
# var PLAYER_COLOR: Color = Color.WHITE



var mainPlayer: GlobalNames.Player = GlobalNames.Player.new()

enum PACKET_TYPE {
	EMPTY_PACKET,
	EXIT,
	PLAYER_JOIN,
	INITIAL_SETUP,
}

var socket: StreamPeerTCP = null

func _ready() -> void:
	# TODO: proper player handling and ID
	mainPlayer.id = randi()
	print("[Network.gd] Global script loaded")


func connect_to_server(address: String = "127.0.0.1", port: int = 4000) -> Error:
	print("[Network.gd] Connect Button pressed")
	
	if socket != null:
		print("[Network.gd] Connection to server already established")
		return FAILED 

	socket = StreamPeerTCP.new()

	var error := socket.connect_to_host(address, port)
	
	if error != OK:
		print("[Network.gd] Error while connecting: ", error_string(error))
		socket.disconnect_from_host()
		socket = null
		return error
	else:
		print("[Network.gd] Connecting to host")
		
		var initial_time := Time.get_ticks_msec()
		
		while socket.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			socket.poll()
			var time_difference := Time.get_ticks_msec() - initial_time
			if time_difference >= 3 * 1000:
				socket.disconnect_from_host()
				socket = null
				print("[Network.gd] Connection timed out")
				return ERR_TIMEOUT

		print("[Network.gd] Connection Succesful", socket.get_status())

		return OK

		# var names: PackedStringArray = [
		# 	"mogyoro",
		# 	"lekvar",
		# 	"aztapicsakurvamindensegit",
		# ]
		# var player_name := names[randi() % names.size()]
		# var player_data := PackedByteArray()
		# player_data.resize(14)
		# player_data.encode_u8(0, PACKET_TYPE.PLAYER_JOIN)
		# player_data.encode_u8(1, 12 + player_name.length())
		# player_data.encode_s64(2, 34673)
		# player_data.encode_u8(10, 110)
		# player_data.encode_u8(11, 230)
		# player_data.encode_u8(12, 78)
		
		# player_data.encode_u8(13, player_name.length())
		# #player_data.encode_var(13, player_name)
		# player_data.append_array(player_name.to_ascii_buffer())
		# #player_data.resize(256)
		
		# socket.put_data(player_data)
		
		
		# print("[Network.gd] sent data to server")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if socket != null: 
			# socket.put_data("exit".to_ascii_buffer())
			send_exit_packet()
			socket.disconnect_from_host()
			socket = null
		get_tree().quit() # default behavior

func send_player_join_packet() -> void:
	var player_data := PackedByteArray()
	player_data.resize(14)
	player_data.encode_u8(0, PACKET_TYPE.PLAYER_JOIN)
	player_data.encode_u8(1, 12 + mainPlayer.name.length())
	player_data.encode_s64(2, mainPlayer.id)
	player_data.encode_u8(10, mainPlayer.color.r8)
	player_data.encode_u8(11, mainPlayer.color.g8)
	player_data.encode_u8(12, mainPlayer.color.b8)
	
	player_data.encode_u8(13, mainPlayer.name.length())
	player_data.append_array(mainPlayer.name.to_ascii_buffer())
	#player_data.resize(256)
	
	socket.put_data(player_data)

func send_exit_packet() -> void:
	var packet := PackedByteArray()
	packet.resize(2)
	packet.encode_u8(0, PACKET_TYPE.EXIT)
	packet.encode_u8(1, 0)

	socket.put_data(packet)

func send_inital_setup_packet(pieceParent: Node2D) -> void:
	var init_setup_data := PackedByteArray()
	init_setup_data.resize(8 + GlobalNames.NR_PIECES * 3 + 2)
	init_setup_data.encode_u8(0, Network.PACKET_TYPE.INITIAL_SETUP)
	init_setup_data.encode_u8(1, 8 + GlobalNames.NR_PIECES * 3)
	init_setup_data.encode_s64(2, mainPlayer.id)


	var i := 0
	for p in pieceParent.get_children():
		var piece: Piece = p
		init_setup_data.encode_u8(10 + i * 3, piece.pieceType);
		init_setup_data.encode_u8(10 + i * 3 + 1, piece.positionOnBoard.x);
		init_setup_data.encode_u8(10 + i * 3 + 2, piece.positionOnBoard.y);

		i += 1
	
	print(init_setup_data)

	socket.put_data(init_setup_data)