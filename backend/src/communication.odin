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

	AVAILABLE_MOVE_REQUEST:
	packet_type: 4 (1 byte)
	packet_data_size: 8 + 1 (1 byte)
	player_id: i64 (8 bytes)
	piece_id: u8 (1 byte)

	AVAILABLE_MOVES:
	packet_type: 4 (1 byte)
	packet_data_size: 1 + n * 2 (1 byte)
	moves_len: u8 (1 byte)
	moves: u8 * 2 * n (n * 2 bytes)

	MOVE_PIECE:
	packet_type: 4 (1 byte)
	packet_data_size: 8 + 1 + 2 (1 byte)
	player_id: i64 (8 bytes)
	piece_id: u8 (1 byte)
	target: u8 * 2 (2 byte)

	PIECE_MOVED:
	packet_type: 4 (1 byte)
	packet_data_size: 8 + 1 + 2 (1 byte)
	player_id: i64 (8 bytes)
	piece_id: u8 (1 byte)
	target: u8 * 2 (2 byte)

	ROUND_START:
	packet_type: 4 (1 byte)
	packet_data_size: 8 + 1 + 2 (1 byte)
	current_player: u8 (1 byte)
	current_throw: u8 (1 byte)
*/

// SERVER_PACKET_TYPE :: enum {
// 	EMPTY_PACKET, // this is here to handle empty data, should never happen
// 	EXIT,
// 	PLAYER_JOIN,
// 	INIT_PLAYER_SETUP,
// 	INIT_BOARD_STATE,
// 	AVAILABLE_MOVE_REQUEST,
// 	AVAILABLE_MOVES,
// 	MOVE_PIECE,
// 	PIECE_MOVED,
// 	ROUND_START,
// }

// aka from server -> to client packets
SERVER_PACKET_TYPE :: enum {
	EMPTY_PACKET, // this is here to handle empty data, should never happen
	INIT_BOARD_STATE,
	AVAILABLE_MOVES,
	PIECE_MOVED,
	ROUND_START,
}

// aka from server -> to client packets
CLIENT_PACKET_TYPE :: enum {
	EMPTY_PACKET, // this is here to handle empty data, should never happen
	EXIT,
	PLAYER_JOIN,
	INIT_PLAYER_SETUP,
	AVAILABLE_MOVE_REQUEST,
	MOVE_PIECE,
}

Empty_Packet_Data :: struct {}
Exit_Data :: struct {}
Player_Join_Data :: struct {
	id: i64,
	color: [3]u8,
	name: string,
	socket: net.TCP_Socket,
}
Init_Player_Setup_Data :: struct {
	player_id: i64,
	pieces: [NR_PIECES]Piece, // u8 + 2 x u8 (NR_PIECES * 3 bytes)
}
Available_Move_Request_Data :: struct {
	player_id: i64,
	piece_id: u8,
}
Move_Piece_Data :: struct {
	player_id: i64,
	piece_id: u8,
	target_tile: v2i,
}

Decoded_Packet :: union #no_nil {
	Empty_Packet_Data,
	Exit_Data,
	Player_Join_Data,
	Init_Player_Setup_Data,
	Available_Move_Request_Data,
	Move_Piece_Data,
}



// Available_Move_Data :: struct {
// 	player_id: i64,
// 	piece_id: u8
// }

// Piece_Moved_Data :: struct {
// 	player_id: i64,
// 	piece_id: u8,
// 	target_tile: v2i,
// }

// Round_Start_Data :: struct {
// 	using shared: Packet_Shared,
// 	player: u8,
// 	current_throw: u8,
// 	asd: struct {
// 		a, b, c
// 	}
// }

// Packet_Shared :: struct {
// 	id: int, 
// }

// Decoded_Packet :: union {
// 	Piece_Moved_Data,
// 	Round_Start_Data,
// }

// Decoded2 :: struct {
// 	// kind: CLIENT_PACKET_TYPE,
// 	kind: typeid,
// 	value: struct #raw_union {
		
// 		Piece_Moved_Data,
// 		Round_Start_Data,
// 	}
// }

// hugy :: proc () {
	
// 	asdasd: Decoded_Packet;
// 	switch a in asdasd {
// 		case Piece_Moved_Data:
// 			asd := &a;
// 		}

// 	is_type(Round_Start_Data, asdasd);
// }

// is_type :: proc ($T: typeid, packet: Decoded_Packet) -> bool {
// 	_, ok := packet.(T);

// 	return ok;
// }

Client_Packet :: struct {
	// type: CLIENT_PACKET_TYPE,
	// socket: net.TCP_Socket,
	data: Decoded_Packet,
}

Client_Packet_Queue :: struct {
	queue: [dynamic]Client_Packet,
	mutex: sync.Mutex,
}

make_client_packet_queue :: proc() -> Client_Packet_Queue{
	return {
		queue = make([dynamic]Client_Packet),
	};
}

client_packet_queue_push :: proc(q: ^Client_Packet_Queue, packet: Client_Packet){
    sync.lock(&q.mutex);
    defer sync.unlock(&q.mutex);
    
    append(&q.queue, packet);
}

client_packet_queue_has :: proc(q: ^Client_Packet_Queue) -> bool{
    sync.lock(&q.mutex);
    defer sync.unlock(&q.mutex);

    return len(q.queue) > 0;
}

client_packet_queue_pop :: proc(q: ^Client_Packet_Queue) -> Client_Packet{
    sync.lock(&q.mutex);
    defer sync.unlock(&q.mutex);

    // value := q.queue[len(q.queue) - 1];
	// value := q.queue[0];
    // // pop(&q.queue);
	// pop_front()
    // return value;
	return pop_front(&q.queue);
}

Server_Client_Data :: struct{
    socket: net.TCP_Socket,
	player_id: i64,
	state: ^App_State,
};

handle_incoming_packets :: proc(client_data: rawptr){
	scd := (cast(^Server_Client_Data) client_data)^;
	state := scd.state;
	free(client_data);

	// // verify player identity
	// player_join_header: [2]byte;
	// _ ,err := net.recv_tcp(scd.socket, player_join_header[:]);
	
	// fmt.println("[communication] Received join packet");

	// packet_type: SERVER_PACKET_TYPE = cast(SERVER_PACKET_TYPE) player_join_header[0];
	// if packet_type != .PLAYER_JOIN {
	// 	fmt.println("[communication] Invalid player join packet type (expected: 1, got: ", packet_type, ")");
	// 	sync.unlock(&state.accepting_connection);
	// 	return;
	// }

	// player_join_data_len: u8 = player_join_header[1];
	// player_join_packet: []byte = make([]byte, player_join_data_len);
	// _ ,err = net.recv_tcp(scd.socket, player_join_packet[:])

	// player_data := decode_player_join_packet(player_join_packet);
	// player_data.socket = scd.socket;
	// set_player_data(state, player_data);
	
	// This loops till our client wants to disconnect
	for {
		// get header
		packet_header: [2]byte;
		_ ,err := net.recv_tcp(scd.socket, packet_header[:]);
		if err != nil {
			fmt.panicf("error while recieving data %s", err);
		}

		
		// get data
		packet_type: CLIENT_PACKET_TYPE = cast(CLIENT_PACKET_TYPE) packet_header[0];
		packet_data_len: u8 = packet_header[1];
		packet_data: []byte = make([]byte, packet_data_len);
		fmt.println("[communication] Received packet: ", packet_type, "(len: ", packet_data_len, ")");
		if packet_type == .EXIT {
			fmt.println("[communication] connection ended");
			break; // TODO: handle setting player state to disconnected
		} else if packet_type == .PLAYER_JOIN {
			sync.unlock(&state.accepting_connection);
		}
		_ ,err = net.recv_tcp(scd.socket, packet_data[:])
		
		client_packet_queue_push(&state.client_packets, {
			data = decode_packet(state, packet_type, packet_data, scd.socket),
		});
	}
}

// handle_outgoing_packets :: proc(client_data: rawptr) {
// 	scd := (cast(^Server_Client_Data) client_data)^;
// 	state := scd.state;
// 	free(client_data); 

// 	request_queue: ^Outbound_Packet_Queue;
// 	socket: net.TCP_Socket;

// 	if scd.player_id == state.p1.id {
// 		request_queue = &state.p1.requests;
// 		socket = state.p1.socket;
// 	} else if scd.player_id == state.p2.id {
// 		request_queue = &state.p2.requests;
// 		socket = state.p2.socket;
// 	} else {
// 		panic("[communication] Invalid player ID for outbound packets")
// 	}

// 	for {
// 		if !out_packet_queue_has(request_queue) {
// 			continue;
// 		}

// 		packet := out_packet_queue_pop(request_queue);
// 		packet_data: []byte = encode_packet(state, packet);

// 		_, err := net.send_tcp(socket, packet_data[:]);
		
// 		if err != nil {
// 			// fmt.panicf("error while recieving data %s", err);
// 			fmt.println("[communication] Error sending ", packet.type, " packet: ", err);
// 		}
// 	}
// }

send_packet :: proc(socket: net.TCP_Socket, data: []byte) {
	_, err := net.send_tcp(socket, data[:]);
		
	if err != nil {
		// fmt.panicf("error while recieving data %s", err);
		fmt.println("[communication] Error sending ", cast(SERVER_PACKET_TYPE) data[0], " packet: ", err);
	}
}

decode_player_join_packet :: proc(data: []byte) -> Player_Join_Data {
	data := data;

	color: [3]u8;
	color.r = cast(u8) data[8];
	color.g = cast(u8) data[9];
	color.b = cast(u8) data[10];
	name_len := cast(u8) data[11];

	name := strings.clone_from_bytes(data[12:][:name_len], context.allocator);

	return Player_Join_Data{
		id = slice.to_type(data[:8], i64),
		color = color,
		name = name,
	}
}

decode_init_player_setup :: proc(data: []byte) -> Init_Player_Setup_Data {
	data := data;

	player_id := slice.to_type(data[:8], i64);
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

	return Init_Player_Setup_Data{
		player_id = player_id,
		pieces = pieces,
	}
}

decode_available_move_request :: proc(data: []byte) -> Available_Move_Request_Data {
	data := data;

	player_id := slice.to_type(data[:8], i64);
	piece_id := cast(u8) data[8];

	return Available_Move_Request_Data{
		player_id = player_id,
		piece_id = piece_id,
	}
}

decode_move_piece :: proc(data: []byte) -> Move_Piece_Data {
	data := data;

	player_id := slice.to_type(data[:8], i64);
	piece_id := cast(u8) data[8];

	target_tile: v2i;
	target_tile.x = cast(int) cast(u8) data[9];
	target_tile.y = cast(int) cast(u8) data[10];

	return Move_Piece_Data{
		player_id = player_id,
		piece_id = piece_id,
		target_tile = target_tile,
	}
}

decode_packet :: proc(state: ^App_State, type: CLIENT_PACKET_TYPE, data: []byte, socket: net.TCP_Socket) -> Decoded_Packet {
	data := data;
	switch (type) {
		case .EMPTY_PACKET:
			// TODO: handle worng packets
		case .PLAYER_JOIN:
			player_data := decode_player_join_packet(data);
			player_data.socket = socket;
			return player_data;

		case .EXIT:
			panic("[communication] Exit packet should be handled earlier");
		case .INIT_PLAYER_SETUP:
			// TODO: slice.to_type(...)
			return decode_init_player_setup(data);
		
		case .AVAILABLE_MOVE_REQUEST:
			return decode_available_move_request(data);

		case .MOVE_PIECE:
			return decode_move_piece(data);
	}
	return {};
}

// encode_packet :: proc(state: ^App_State, packet: Outbound_Packet) -> []byte{
// 	switch (packet.type) {
// 		case .EMPTY_PACKET: fallthrough
// 		case .EXIT: fallthrough
// 		case .INIT_PLAYER_SETUP: fallthrough
// 		case .AVAILABLE_MOVE_REQUEST: fallthrough
// 		case .MOVE_PIECE: fallthrough
// 		case .PLAYER_JOIN: 
// 			fmt.println("[communication] Server shouldn't send ", packet.type, " packets!");
// 			panic("");
// 			// return []byte{};
// 		case .INIT_BOARD_STATE:
// 			return encode_init_board_state(state);
// 		case .AVAILABLE_MOVES:
// 			data := (cast(^Available_Move_Data) packet.data)^;
// 			piece_id := data.piece_id;
// 			player_id := data.player_id;
// 			free(packet.data);

// 			fmt.println("[communication] Player with ID ", player_id, " requested moves for piece ", piece_id);

// 			return encode_available_moves(state^, player_id, piece_id);
// 		case .PIECE_MOVED:
// 			data := (cast(^Piece_Moved_Data) packet.data)^;
// 			piece_id := data.piece_id;
// 			player_id := data.player_id;
// 			target_tile := data.target_tile;
// 			free(packet.data);

// 			return encode_piece_moved(state^, player_id, piece_id, target_tile);
// 		case .ROUND_START:
// 			data := (cast(^Round_Start_Data) packet.data)^;
// 			player := data.player;
// 			throw := data.current_throw;
// 			free(packet.data);

// 			return encode_round_start(player, throw);
// 	}
// 	panic("Illegal state")
// }

encode_init_board_state :: proc(state: ^App_State) -> []byte {
	// TODO: i have some wrong indexings
	// making the data with dynamic array works, and is the right length
	// also make sure the main thread keeps running until you send this data
	// closing that thread will create garbage in the memory
	// which is a FUCKING HELL to debug aaah 💀

	// packet_data: [16 + NR_PIECES * 3 * 2 + 2]byte;
	// packet_data: []byte = make([]byte, 16 + NR_PIECES * 3 * 2 + 2 + 100);
	packet_data := make([dynamic]byte, 2);

	// header
	packet_data[0] = cast(byte) SERVER_PACKET_TYPE.INIT_BOARD_STATE;
	// packet_data[1] = cast(byte) len(packet_data) - 2;

	// copy_slice(packet_data[2:2+8], bytes_of(&state.p1.id));
	append_elems(&packet_data, ..bytes_of(&state.p1.id))

	offset := 2 + 8 + 1;
	for &piece in state.p1.pieces {
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
	for &piece in state.p2.pieces {
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

encode_available_moves :: proc(state: App_State, player_id: i64, piece_id: u8) -> []byte {
	packet_data := make([dynamic]byte, 2);
	packet_data[0] = cast(byte) SERVER_PACKET_TYPE.AVAILABLE_MOVES;

	moves: []Action;
	if player_id == state.p1.id {
		moves = get_available_moves(state, state.p1.pieces[piece_id], state.current_throw);
	} else {
		moves = get_available_moves(state, state.p2.pieces[piece_id], state.current_throw);
	}

	append(&packet_data, cast(u8) len(moves));

	for action in moves {
		append(&packet_data, cast(u8) action.target_tile.x);
		append(&packet_data, cast(u8) action.target_tile.y);
	}

	packet_data[1] = cast(byte) len(packet_data) - 2;

	fmt.println("[communication] Moves for ", player_id, ", piece ", piece_id, moves);

	return slice.reinterpret([]byte, packet_data[:]);
}

encode_piece_moved :: proc(state: App_State, data: Move_Piece_Data) -> []byte {
	packet_data := make([dynamic]byte, 2);
	packet_data[0] = cast(byte) SERVER_PACKET_TYPE.PIECE_MOVED;

	// player_id := player_id;
	data := data;
	append_elems(&packet_data, ..bytes_of(&data.player_id));

	append(&packet_data, cast(u8) data.piece_id);
	append(&packet_data, cast(u8) data.target_tile.x);
	append(&packet_data, cast(u8) data.target_tile.y);

	packet_data[1] = cast(byte) len(packet_data) - 2;

	return slice.reinterpret([]byte, packet_data[:]);
}

encode_round_start :: proc(state: App_State) -> []byte {
	// player: u8, throw: u8
	player := cast(u8) state.current_player;
	throw := cast(u8) state.current_throw;

	packet_data := make([dynamic]byte, 2);
	packet_data[0] = cast(byte) SERVER_PACKET_TYPE.ROUND_START;

	append(&packet_data, player);
	append(&packet_data, throw);

	packet_data[1] = cast(byte) len(packet_data) - 2;

	return slice.reinterpret([]byte, packet_data[:]);
}

// Credit: Ferenc a fonok
bytes_of :: proc(data: ^$T) -> []byte{
    return slice.bytes_from_ptr(data, size_of(T));
}