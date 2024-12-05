extends Node
# class_name Network

# region Player Data

# var PLAYER_ID: int = -1
# var PLAYER_NAME: String = ""
# var PLAYER_COLOR: Color = Color.WHITE



var main_player: GlobalNames.Player = GlobalNames.Player.new()

var p1_id: int
var p2_id: int


# enum PACKET_TYPE {
# 	EMPTY_PACKET,
# 	EXIT,
# 	PLAYER_JOIN,
# 	INITIAL_SETUP,
# 	INIT_BOARD_STATE,
# 	AVAILABLE_ACTIONS_REQUEST,
# 	AVAILABLE_ACTIONS,
# 	MOVE_PIECE,
# 	PIECE_MOVED,
# 	ROUND_START,
# }

# aka from server -> to client packets
enum SERVER_PACKET_TYPE {
	EMPTY_PACKET, #this is here to handle empty data, should never happen
	INIT_BOARD_STATE,
	AVAILABLE_ACTIONS,
	PIECE_MOVED,
	PIECE_ATTACKED,
	ROUND_START,
	USED_ABILITY,
}

# aka from server -> to client packets
enum CLIENT_PACKET_TYPE {
	EMPTY_PACKET, #this is here to handle empty data, should never happen
	EXIT,
	PLAYER_JOIN,
	INIT_PLAYER_SETUP,
	AVAILABLE_ACTIONS_REQUEST,
	MOVE_PIECE,
	ATTACK,
	USE_ABILITY,
}

var socket: StreamPeerTCP = null

# endregion

# region Signals

signal initial_board_state_received(state: Array)
signal available_actions_received(moves: Array[Vector2i], attacks: Array[Vector2i], can_use_ability: bool)
signal piece_moved(player_id: int, piece_id: int, target_tile: Vector2i)
signal piece_attacked(player_id: int, piece_id: int, target_piece_id: int, new_hp: int, landing_tile: Vector2i)
signal round_started(player: int, throw: int)
signal ability_used(player_id: int, piece_id: int, ability_data: Dictionary)

var incoming_thread: Thread

func _ready() -> void:
	# TODO: proper player handling and ID
	main_player.id = randi()
	main_player.color = Color(randf(), randf(), randf())
	print("[Network.gd] Global script loaded")

func _process(_delta: float) -> void:
	if GlobalNames.initial_board_data.size() > 0:
		get_tree().change_scene_to_file("res://GameScene.tscn")
	

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

		incoming_thread = Thread.new()
		incoming_thread.start(handle_incoming_packets)

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
	player_data.encode_u8(0, CLIENT_PACKET_TYPE.PLAYER_JOIN)
	player_data.encode_u8(1, 12 + main_player.name.length())
	player_data.encode_s64(2, main_player.id)
	player_data.encode_u8(10, main_player.color.r8)
	player_data.encode_u8(11, main_player.color.g8)
	player_data.encode_u8(12, main_player.color.b8)
	
	player_data.encode_u8(13, main_player.name.length())
	player_data.append_array(main_player.name.to_ascii_buffer())
	#player_data.resize(256)
	
	socket.put_data(player_data)

func send_exit_packet() -> void:
	var packet := PackedByteArray()
	packet.resize(2)
	packet.encode_u8(0, CLIENT_PACKET_TYPE.EXIT)
	packet.encode_u8(1, 0)

	socket.put_data(packet)

func send_inital_setup_packet(pieceParent: Node2D) -> void:
	var init_setup_data := PackedByteArray()
	init_setup_data.resize(8 + GlobalNames.NR_PIECES * 3 + 2)
	init_setup_data.encode_u8(0, CLIENT_PACKET_TYPE.INIT_PLAYER_SETUP)
	init_setup_data.encode_u8(1, 8 + GlobalNames.NR_PIECES * 3)
	init_setup_data.encode_s64(2, main_player.id)


	var i := 0
	for p in pieceParent.get_children():
		var piece: Piece = p
		init_setup_data.encode_u8(10 + i * 3, piece.piece_type);
		init_setup_data.encode_u8(10 + i * 3 + 1, piece.position_on_board.x);
		init_setup_data.encode_u8(10 + i * 3 + 2, piece.position_on_board.y);

		i += 1
	
	# print(init_setup_data)

	socket.put_data(init_setup_data)

func send_move_piece_packet(piece_id: int, target: Vector2i) -> void:
	var packet_data := PackedByteArray()
	packet_data.resize(2 + 8 + 1 + 2)

	packet_data.encode_u8(0, CLIENT_PACKET_TYPE.MOVE_PIECE)
	packet_data.encode_u8(1, 8 + 1 + 2)

	packet_data.encode_s64(2, main_player.id)
	packet_data.encode_u8(10, piece_id)

	packet_data.encode_u8(11, target.x)
	packet_data.encode_u8(12, target.y)

	socket.put_data(packet_data)

	# receive_packet()

func send_attack_packet(piece_id: int, target: Vector2i) -> void:
	var packet_data := PackedByteArray()
	packet_data.resize(2 + 8 + 1 + 2)

	packet_data.encode_u8(0, CLIENT_PACKET_TYPE.ATTACK)
	packet_data.encode_u8(1, 8 + 1 + 2)

	packet_data.encode_s64(2, main_player.id)
	packet_data.encode_u8(10, piece_id)

	packet_data.encode_u8(11, target.x)
	packet_data.encode_u8(12, target.y)

	socket.put_data(packet_data)


func request_available_moves(piece_id: int) -> void:
	var packet_data := PackedByteArray()
	packet_data.resize(2 + 8 + 1)

	packet_data.encode_u8(0, CLIENT_PACKET_TYPE.AVAILABLE_ACTIONS_REQUEST)
	packet_data.encode_u8(1, 8 + 1)

	packet_data.encode_s64(2, main_player.id)
	packet_data.encode_u8(10, piece_id)

	socket.put_data(packet_data)

	# receive_packet()

func send_use_ability_packet(piece: Piece, ability_data: Dictionary) -> void:
	var packet_data := PackedByteArray()
	packet_data.resize(2 + 8 + 1)

	packet_data.encode_u8(0, CLIENT_PACKET_TYPE.USE_ABILITY)
	# packet_data.encode_u8(1, 8 + 1) # data will be calculated at the end

	packet_data.encode_s64(2, main_player.id)
	packet_data.encode_u8(10, piece.id)

	match piece.piece_type:
		GlobalNames.PIECE_TYPE.PAWN:
			packet_data.resize(packet_data.size() + 1)
			packet_data.encode_u8(11, ability_data.selected_type)
			
		GlobalNames.PIECE_TYPE.ROOK:
			packet_data.resize(packet_data.size() + 2)
			packet_data.encode_s8(11, ability_data.direction.x)
			packet_data.encode_s8(12, ability_data.direction.y)
			
		GlobalNames.PIECE_TYPE.BISHOP:
			packet_data.resize(packet_data.size() + 2)
			packet_data.encode_u8(11, ability_data.selected_tile.x)
			packet_data.encode_u8(12, ability_data.selected_tile.y)
			
		GlobalNames.PIECE_TYPE.KNIGHT:
			packet_data.resize(packet_data.size() + 2)
			packet_data.encode_u8(11, ability_data.selected_tile.x)
			packet_data.encode_u8(12, ability_data.selected_tile.y)

		GlobalNames.PIECE_TYPE.QUEEN:
			# no extra data needed
			pass

	packet_data.encode_u8(1, packet_data.size() - 2)

	socket.put_data(packet_data)


func handle_incoming_packets() -> void:
	while true:
		receive_packet()

func receive_packet() -> void:
	var result: Array = socket.get_data(2)

	
	var _error: Error = result[0]
	var header: PackedByteArray = result[1]
	# this is fucking stupid
	# if you cast this result array to ByteArray, you get [0, 0]
	# Also there is no nice way to unpack multiple return values
	# this is a bad solution from godot's part
	# i know it's explained in the docs, but it wasn't clear until i printed the generic Array

	var packet_type: SERVER_PACKET_TYPE = header[0] as SERVER_PACKET_TYPE
	var packet_len: int = header[1]

	print("[Network.gd] Received ", SERVER_PACKET_TYPE.keys()[packet_type], " packet (", packet_len, " bytes)")

	result = socket.get_data(packet_len)
	_error = result[0]

	var data: Array = result[1]

	decode_packet(packet_type, data)

func decode_packet(packet_type: SERVER_PACKET_TYPE, data: PackedByteArray) -> void:
	match packet_type:
		SERVER_PACKET_TYPE.INIT_BOARD_STATE:
			p1_id = data.decode_s64(0)
			var p1_pieces: Array[Piece]
			for i in GlobalNames.NR_PIECES:
				var piece: Piece = Piece.new()
				var piece_type: GlobalNames.PIECE_TYPE = data.decode_u8(8 + i *3) as GlobalNames.PIECE_TYPE
				var x: int = data.decode_u8(8 + i * 3 + 1)
				var y: int = data.decode_u8(8 + i * 3 + 2)
				piece.piece_type = piece_type
				piece.position_on_board = Vector2i(x, y)
				piece.owner_player = p1_id
				p1_pieces.push_back(piece)
			
			p2_id = data.decode_s64(8 + GlobalNames.NR_PIECES * 3)
			var offset: int = 8 + GlobalNames.NR_PIECES * 3 + 8
			var p2_pieces: Array[Piece]
			for i in GlobalNames.NR_PIECES:
				var piece: Piece = Piece.new()
				var piece_type: GlobalNames.PIECE_TYPE = data.decode_u8(offset + i *3) as GlobalNames.PIECE_TYPE
				var x: int = data.decode_u8(offset + i * 3 + 1)
				var y: int = data.decode_u8(offset + i * 3 + 2)
				piece.piece_type = piece_type
				piece.position_on_board = Vector2i(x, y)
				piece.owner_player = p2_id
				p2_pieces.push_back(piece)
			
			# GlobalNames.initial_board_data = [p1_pieces, p2_pieces]
			call_deferred("emit_signal", "initial_board_state_received", [p1_pieces, p2_pieces])
			# get_tree().change_scene_to_file("res://GameScene.tscn")
		
		SERVER_PACKET_TYPE.AVAILABLE_ACTIONS:
			var can_use_ability: bool = data.decode_u8(0) as bool 
			var nr_moves: int = data.decode_u8(1)

			var moves: Array[Vector2i] = []

			var byte_offset: int = 2

			for i in nr_moves:
				var x: int = data.decode_u8(byte_offset)
				var y: int = data.decode_u8(byte_offset + 1)

				moves.push_back(Vector2i(x, y))
				byte_offset += 2

			var nr_attacks: int = data.decode_u8(byte_offset)
			byte_offset += 1

			var attacks: Array[Vector2i] = []

			for i in nr_attacks:
				var x: int = data.decode_u8(byte_offset)
				var y: int = data.decode_u8(byte_offset + 1)

				attacks.push_back(Vector2i(x, y))
				byte_offset += 2

			# available_actions_received.emit(moves)
			# call_deferred(available_actions_received.emit.bind(moves))

			print("Moves: ", moves)
			print("Attacks: ", attacks)

			call_deferred("emit_signal", "available_actions_received", moves, attacks, can_use_ability)

		SERVER_PACKET_TYPE.PIECE_MOVED:
			var player_id: int = data.decode_s64(0)
			var piece_id: int = data.decode_u8(8)

			var target_tile: Vector2i;
			target_tile.x = data.decode_u8(9)
			target_tile.y = data.decode_u8(10)

			# piece_moved.emit(player_id, piece_id, target_tile)
			call_deferred("emit_signal", "piece_moved", player_id, piece_id, target_tile)
		SERVER_PACKET_TYPE.PIECE_ATTACKED:
			var player_id: int = data.decode_s64(0)
			var piece_id: int = data.decode_u8(8)
			var target_piece_id: int = data.decode_u8(9)
			var new_hp: int = data.decode_s8(10)
			print("[Network.gd] Health byte: ", data[10])


			var landing_tile: Vector2i;
			landing_tile.x = data.decode_u8(11)
			landing_tile.y = data.decode_u8(12)
			call_deferred("emit_signal", "piece_attacked", player_id, piece_id, target_piece_id, new_hp, landing_tile)
			
		

		SERVER_PACKET_TYPE.ROUND_START:
			var player: int = data.decode_u8(0)
			var throw: int = data.decode_u8(1)

			call_deferred("emit_signal", "round_started", player, throw)
		
		SERVER_PACKET_TYPE.USED_ABILITY:
			var player_id: int = data.decode_s64(0)
			var piece_id: int = data.decode_u8(8)

			var ability_type: GlobalNames.PIECE_TYPE = data.decode_u8(9) as GlobalNames.PIECE_TYPE

			match ability_type:
				GlobalNames.PIECE_TYPE.PAWN:
					var new_type: GlobalNames.PIECE_TYPE = data.decode_u8(10) as GlobalNames.PIECE_TYPE
					var new_damage: int = data.decode_u8(11)

					call_deferred("emit_signal", "ability_used", 
						player_id, piece_id,
						{
							"new_type": new_type,
							"new_dmg": new_damage,
						}
					)
				GlobalNames.PIECE_TYPE.BISHOP:
					var new_position: Vector2i

					new_position.x = data.decode_u8(10)
					new_position.y = data.decode_u8(11)

					call_deferred("emit_signal", "ability_used", 
						player_id, piece_id,
						{
							"new_position": new_position,
						}
					)
				GlobalNames.PIECE_TYPE.ROOK:
					var landing_tile: Vector2i

					landing_tile.x = data.decode_u8(10)
					landing_tile.y = data.decode_u8(11)

					var tiles: Array[Vector2i]
					var new_hps: Array[int]

					var index := 12

					while index < data.size():
						var tile: Vector2i
						tile.x = data.decode_u8(index)
						tile.y = data.decode_u8(index + 1)
						
						var hp := data.decode_s8(index + 2)

						tiles.push_back(tile)
						new_hps.push_back(hp)

						index += 3
					
					call_deferred("emit_signal", "ability_used", 
						player_id, piece_id,
						{
							"landing_tile": landing_tile,
							"tiles": tiles,
							"new_hps": new_hps,
						}
					)


				GlobalNames.PIECE_TYPE.QUEEN:
					var healed_pieces: Array[int]

					var heal_amount := data.decode_u8(10)


					var index := 11

					while index < data.size():
						var healed_piece := data.decode_u8(index)
						healed_pieces.push_back(healed_piece)
						index += 1

					call_deferred("emit_signal", "ability_used", 
						player_id, piece_id,
						{
							"heal_amount": heal_amount,
							"healed_pieces": healed_pieces, 
						}
					)

				GlobalNames.PIECE_TYPE.KNIGHT:
					var new_position: Vector2i

					new_position.x = data.decode_u8(10)
					new_position.y = data.decode_u8(11)

					call_deferred("emit_signal", "ability_used", 
						player_id, piece_id,
						{
							"new_position": new_position,
						}
					)

				_:
					pass


		# _:
			# default
