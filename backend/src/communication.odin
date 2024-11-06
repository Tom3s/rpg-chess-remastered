package main

import "core:fmt"
import "core:thread"
import "core:net"
import "core:sync"
import "core:strings"
import "core:slice"


/*
	PLAYER_JOIN:
	packet_type: 0 (1 byte)
	packet_data_size: u8 (1 byte)
	player_id: i64 (8 bytes)
	color: 3 x u8 (3 bytes)
	player_name_len: u8 (1 byte)
	player_name: variable bytes

	INITIAL_SETUP: 
	packet_type: 0 (1 byte)
	packet_data_size: 8 + 12 * 3 (1 byte)
	player_id: i64 (8 bytes)
	pieces: u8 + 2 x u8 (12 * 3 bytes)

*/

PACKET_TYPE :: enum {
	EMPTY_PACKET, // this is here to handle empty data, should never happen
	PLAYER_JOIN,
	INITIAL_SETUP,
}


Initial_Setup :: struct {
	piece_types: [12]PIECE_TYPE,
	positions: [12]v2i,
}

Packet_Data :: union {
	Initial_Setup,
	
}

Packet :: struct {
	type: PACKET_TYPE,

	data: Packet_Data,
}

Server_Client_Data :: struct{
    socket: net.TCP_Socket,
	state: ^App_State,
};

handle_client_connection :: proc(client_data: rawptr){
	scd := (cast(^Server_Client_Data) client_data)^;
	state := scd.state;
	free(client_data);

	// verify player identity
	player_join_header: [2]byte;
	_ ,err := net.recv_tcp(scd.socket, player_join_header[:]);
	
	fmt.println("[communication] Received join packet");

	packet_type: PACKET_TYPE = cast(PACKET_TYPE) player_join_header[0];
	if packet_type != .PLAYER_JOIN {
		fmt.println("[communication] Invalid player join packet type (expected: 1, got: ", packet_type, ")");
		sync.unlock(&state.accepting_connection);
		return;
	}

	player_join_data_len: u8 = player_join_header[1];
	player_join_packet: []byte = make([]byte, player_join_data_len);
	_ ,err = net.recv_tcp(scd.socket, player_join_packet[:])

	player_data := decode_player_join_packet(player_join_packet);
	set_player_data(state, player_data);
	// sync.unlock(&state.accepting_connection);
	
	// This loops till our client wants to disconnect
	for {
		// allocating memory for our data
		// data_in_bytes: [32]byte;
		packet_header: [2]byte;
		// receving some data from client
		_ ,err := net.recv_tcp(scd.socket, packet_header[:]);
		if err != nil {
			fmt.panicf("error while recieving data %s", err);
		}

		packet_type: PACKET_TYPE = cast(PACKET_TYPE) packet_header[0];
		packet_data_len: u8 = packet_header[1];
		packet_data: []byte = make([]byte, packet_data_len);
		_ ,err = net.recv_tcp(scd.socket, packet_data[:])

		decode_packet(state, packet_type, packet_data);

		// exit_code := [32]byte{
		// 	0, 0, 0, 0, 0, 0, 0, 0,
		// 	0, 0, 0, 0, 0, 0, 0, 0,
		// 	0, 0, 0, 0, 0, 0, 0, 0,
		// 	0, 0, 0, 0, 0, 0, 0, 0,
		// }
		// if data_in_bytes == exit_code{
		// 	fmt.println("connection ended");
		// 	break; // TODO: handle setting player state to disconnected
		// }
		// converting bytes data to string
		// data, e := strings.clone_from_bytes(data_in_bytes[:], context.allocator)
		// if data != "" {
		// 	if strings.starts_with(data, "exit") {
		// 		fmt.println("connection ended");
		// 		break; // TODO: handle setting player state to disconnected
		// 	}
		// 	fmt.println("client said :",data)
		// }
	}
}

decode_player_join_packet :: proc(data: []byte) -> Player {
	data := data;
	player: Player;
	player.id = slice.reinterpret([]i64, data[:8])[0];
	player.color.r = cast(u8) data[8];
	player.color.g = cast(u8) data[9];
	player.color.b = cast(u8) data[10];
	name_len := cast(u8) data[11];

	player.name = strings.clone_from_bytes(data[12:][:name_len], context.allocator);

	return player;
}

decode_packet :: proc(state: ^App_State, type: PACKET_TYPE, data: []byte) {
	data := data;
	switch (type) {
		case .EMPTY_PACKET:
			// TODO: handle worng packets
		case .PLAYER_JOIN:
			panic("[communication] Player join packet should be handled earlier");
		case .INITIAL_SETUP:
			player_id := slice.reinterpret([]i64, data[:8])[0];
			pieces: [12]Piece;
			for i in 0..<12 {
				piece_type := cast(PIECE_TYPE) data[8 + i * 3];
				position: v2i;
				position.x = cast(int) cast(u8) data[8 + i * 3 + 1];
				position.y = cast(int) cast(u8) data[8 + i * 3 + 2];
				pieces[i] = init_piece(
					piece_type,
					player_id,
					position,
					i,
				)
			}
			// fmt.println(pieces);
			for piece in pieces {
				fmt.println(piece);
			}
	}
}