package main

import "core:fmt"
import "core:thread"
import "core:net"
import "core:sync"
import "core:strings"
import "core:slice"


/*
	PLAYER_JOIN:
	packet_type: 2 (1 byte)
	packet_data_size: u8 (1 byte)
	player_id: i64 (8 bytes)
	color: 3 x u8 (3 bytes)
	player_name_len: u8 (1 byte)
	player_name: variable bytes

	INIT_PLAYER_SETUP: 
	packet_type: 3 (1 byte)
	packet_data_size: 8 + NR_PIECES * 3 (1 byte)
	player_id: i64 (8 bytes)
	pieces: u8 + 2 x u8 (NR_PIECES * 3 bytes)

	INIT_BOARD_STATE:
	packet_type: 4 (1 byte)
	packet_data_size: 16 + NR_PIECES * 3 * 2 (1 byte)
	player_id: i64 (8 bytes)
	pieces: u8 + 2 x u8 (NR_PIECES * 3 bytes)
	player_id: i64 (8 bytes)
	pieces: u8 + 2 x u8 (NR_PIECES * 3 bytes)


*/

PACKET_TYPE :: enum {
	EMPTY_PACKET, // this is here to handle empty data, should never happen
	EXIT,
	PLAYER_JOIN,
	INIT_PLAYER_SETUP,
	INIT_BOARD_STATE,
}


// Initial_Setup :: struct {
// 	piece_types: [NR_PIECES]PIECE_TYPE,
// 	positions: [NR_PIECES]v2i,
// }

// Packet_Data :: union {
// 	Initial_Setup,
	
// }

// Packet :: struct {
// 	type: PACKET_TYPE,

// 	data: Packet_Data,
// }

Outbound_Packet :: struct {
	type: PACKET_TYPE,
	data: rawptr,
}

Outbound_Packet_Queue :: struct {
	queue: [dynamic]Outbound_Packet,
	mutex: sync.Mutex,
}

make_out_packet_queue :: proc() -> Outbound_Packet_Queue{
	return {
		queue = make([dynamic]Outbound_Packet),
	};
}

out_packet_queue_push :: proc(q: ^Outbound_Packet_Queue, packet: Outbound_Packet){
    sync.lock(&q.mutex);
    defer sync.unlock(&q.mutex);
    
    append(&q.queue, packet);
}

out_packet_queue_has :: proc(q: ^Outbound_Packet_Queue) -> bool{
    sync.lock(&q.mutex);
    defer sync.unlock(&q.mutex);

    return len(q.queue) > 0;
}

out_packet_queue_pop :: proc(q: ^Outbound_Packet_Queue) -> Outbound_Packet{
    sync.lock(&q.mutex);
    defer sync.unlock(&q.mutex);

    value := q.queue[len(q.queue) - 1];
    pop(&q.queue);
    return value;
}

Server_Client_Data :: struct{
    socket: net.TCP_Socket,
	player_id: i64,
	state: ^App_State,
};

handle_incoming_packets :: proc(client_data: rawptr){
	scd := (cast(^Server_Client_Data) client_data)^;
	state := scd.state;
	free(client_data); // needed by outgoing function

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
	player_data.socket = scd.socket;
	set_player_data(state, player_data);
	
	// This loops till our client wants to disconnect
	for {
		// get header
		packet_header: [2]byte;
		_ ,err := net.recv_tcp(scd.socket, packet_header[:]);
		if err != nil {
			fmt.panicf("error while recieving data %s", err);
		}

		// get data
		packet_type: PACKET_TYPE = cast(PACKET_TYPE) packet_header[0];
		packet_data_len: u8 = packet_header[1];
		packet_data: []byte = make([]byte, packet_data_len);
		if packet_type == .EXIT {
			fmt.println("[communication] connection ended");
			break; // TODO: handle setting player state to disconnected
		}
		_ ,err = net.recv_tcp(scd.socket, packet_data[:])
		
		decode_packet(state, packet_type, packet_data);
	}
}

handle_outgoing_packets :: proc(client_data: rawptr) {
	scd := (cast(^Server_Client_Data) client_data)^;
	state := scd.state;
	free(client_data); 

	request_queue: ^Outbound_Packet_Queue;
	socket: net.TCP_Socket;

	if scd.player_id == state.p1.id {
		request_queue = &state.p1requests;
		socket = state.p1.socket;
	} else if scd.player_id == state.p2.id {
		request_queue = &state.p2requests;
		socket = state.p2.socket;
	} else {
		panic("[communication] Invalid player ID for outbound packets")
	}

	for {
		if !out_packet_queue_has(request_queue) {
			continue;
		}

		packet := out_packet_queue_pop(request_queue);
		sync.lock(&test_mutex);
		fmt.println(packet);
		packet_data: []byte = encode_packet(state, packet);
		// fmt.println(packet_data);
		fmt.println(packet_data);
		sync.unlock(&test_mutex);


		_, err := net.send_tcp(socket, packet_data[:]);
		
		if err != nil {
			// fmt.panicf("error while recieving data %s", err);
			fmt.println("[communication] Error sending ", packet.type, " packet: ", err);
		}
	}
}

decode_player_join_packet :: proc(data: []byte) -> Player {
	data := data;
	player: Player;
	// TODO: slice.to_type(...)
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
		case .INIT_PLAYER_SETUP:
			// TODO: slice.to_type(...)
			player_id := slice.reinterpret([]i64, data[:8])[0];
			pieces: [NR_PIECES]Piece;
			for i in 0..<NR_PIECES {
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

			add_pieces(state, player_id, pieces);
		case .INIT_BOARD_STATE:
			panic("[communication] Server shouldn't receive init board state")
		case .EXIT:
			panic("[communication] Exit packet should be handled earlier");
	}

}

encode_packet :: proc(state: ^App_State, packet: Outbound_Packet) -> []byte{
	switch (packet.type) {
		case .EMPTY_PACKET: fallthrough
		case .EXIT: fallthrough
		case .INIT_PLAYER_SETUP: fallthrough
		case .PLAYER_JOIN: 
			fmt.println("[communication] Server shouldn't send ", packet.type, " packets!");
			panic("");
			// return []byte{};
		case .INIT_BOARD_STATE:
			return encode_init_board_state(state);

	}
	panic("Illegal state")
}

test_mutex: sync.Mutex;

encode_init_board_state :: proc(state: ^App_State) -> []byte {
	// packet_data: [16 + NR_PIECES * 3 * 2 + 2]byte;
	// packet_data: []byte = make([]byte, 16 + NR_PIECES * 3 * 2 + 2 + 100);
	packet_data := make([dynamic]byte, 2);

	// header
	packet_data[0] = cast(byte) PACKET_TYPE.INIT_BOARD_STATE;
	// packet_data[1] = cast(byte) len(packet_data) - 2;

	// copy_slice(packet_data[2:2+8], bytes_of(&state.p1.id));
	append_elems(&packet_data, ..bytes_of(&state.p1.id))

	offset := 2 + 8 + 1;
	for &piece in state.p1pieces {
		defer offset += 3;
		// packet_data[offset] = cast(u8) piece.type;
		// packet_data[offset + 1] = cast(u8) piece.position.x;
		// packet_data[offset + 2] = cast(u8) piece.position.y;
		append(&packet_data, cast(u8) piece.type)
		append(&packet_data, cast(u8) piece.position.x)
		append(&packet_data, cast(u8) piece.position.y)
	}
	
	// copy_slice(packet_data[offset:offset+8], bytes_of(&state.p2.id));
	append_elems(&packet_data, ..bytes_of(&state.p2.id))


	offset += 8 + 1;
	for &piece in state.p2pieces {
		defer offset += 3;
		// packet_data[offset] = cast(u8) piece.type;
		// packet_data[offset + 1] = cast(u8) piece.position.x;
		// packet_data[offset + 2] = cast(u8) piece.position.y;
		append(&packet_data, cast(u8) piece.type)
		append(&packet_data, cast(u8) piece.position.x)
		append(&packet_data, cast(u8) piece.position.y)
	}

	packet_data[1] = cast(byte) len(packet_data) - 2;

	return slice.reinterpret([]byte, packet_data[:]);
}


bytes_of :: proc(data: ^$T) -> []byte{
    return slice.bytes_from_ptr(data, size_of(T));
}