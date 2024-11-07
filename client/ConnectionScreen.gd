extends Node2D

@onready var button: Button = %Button
@onready var say_button: Button = %SaySomething
@onready var exit_button: Button = %Exit

# enum Network.PACKET_TYPE {
# 	EMPTY_PACKET,
# 	PLAYER_JOIN,
# 	INITIAL_SETUP,
# }



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(connect_pressed)
	say_button.pressed.connect(say_pressed)
	exit_button.pressed.connect(exit_pressed)
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

var peer: StreamPeerTCP = null



func connect_pressed() -> void:
	print("Connect Button pressed")
	
	if peer == null: 
		peer = StreamPeerTCP.new()
	
		var error := peer.connect_to_host("127.0.0.1", 4000)
		
		if error != OK:
			print("Error while connecting: ", error_string(error))
			peer.disconnect_from_host()
			peer = null
			return
		else:
			print("Connection Succesful: ", error_string(error))
			
			var initial_time := Time.get_ticks_msec()
			
			while peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
				peer.poll()
				var time_difference := Time.get_ticks_msec() - initial_time
				if time_difference >= 3 * 1000:
					peer.disconnect_from_host()
					peer = null
					print("Connection timed out")
					return
			print(peer.get_status())
		
		#peer.put_data("Hello from godot".to_ascii_buffer())
		var names: PackedStringArray = [
			"mogyoro",
			"lekvar",
			"aztapicsakurvamindensegit",
		]
		var player_name := names[randi() % names.size()]
		var player_data := PackedByteArray()
		player_data.resize(14)
		player_data.encode_u8(0, Network.PACKET_TYPE.PLAYER_JOIN)
		player_data.encode_u8(1, 12 + player_name.length())
		player_data.encode_s64(2, 34673)
		player_data.encode_u8(10, 110)
		player_data.encode_u8(11, 230)
		player_data.encode_u8(12, 78)
		
		player_data.encode_u8(13, player_name.length())
		#player_data.encode_var(13, player_name)
		player_data.append_array(player_name.to_ascii_buffer())
		#player_data.resize(256)
		
		peer.put_data(player_data)
		
		
		print("sent data to server")

func say_pressed() -> void:
	if peer != null:
		#peer.put_data("Something".to_ascii_buffer())
		var init_setup_data := PackedByteArray()
		init_setup_data.resize(8 + 12 * 3 + 2)
		init_setup_data.encode_u8(0, Network.PACKET_TYPE.INITIAL_SETUP)
		init_setup_data.encode_u8(1, 8 + 12 * 3)
		init_setup_data.encode_s64(2, 34673)
		for i in 9:
			init_setup_data.encode_u8(10 + i * 3, GlobalNames.PIECE_TYPE.PAWN);
			init_setup_data.encode_u8(10 + i * 3 + 1, i);
			init_setup_data.encode_u8(10 + i * 3 + 2, 0);
		
		for i in range(9, 12):
			init_setup_data.encode_u8(10 + i * 3, GlobalNames.PIECE_TYPE.BISHOP);
			init_setup_data.encode_u8(10 + i * 3 + 1, i - 9);
			init_setup_data.encode_u8(10 + i * 3 + 2, 1);
		
		peer.put_data(init_setup_data)
			

func exit_pressed() -> void:
	if peer != null:
		peer.put_data("exit".to_ascii_buffer())
		peer.disconnect_from_host()
		peer = null
