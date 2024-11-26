package main

import "core:fmt"
import "core:math/rand"
import "core:math/linalg"
import "core:os"
import "core:strings"

import "core:thread"
import "core:net"
import "core:sync"

Player :: struct {
	connected: bool,
	id: i64,
	name: string,
	color: [3]u8,

	pieces: [NR_PIECES]Piece,
	dice: [6]int,

	ready: bool,

	socket: net.TCP_Socket,
}

NR_PIECES :: 14;
BOARD_SIZE :: 9;

App_State :: struct {
	mutex: sync.Mutex,
	accepting_connection: sync.Mutex,

	client_packets: Client_Packet_Queue,

	current_player: u8,
	current_throw: int,
	board: [BOARD_SIZE][BOARD_SIZE]^Piece,

	p1: Player,
	p2: Player,

	// p1.dice: [6]int,
	// p2.dice: [6]int,

}

reset_dice :: proc(dice: ^[6]int) {
	dice^ = {1, 2, 3, 4, 5, 6};
	// dice^ = {6, 6, 6, 6, 6, 6};
	rand.shuffle(dice[:]);
	fmt.println("[main] New dice bag: ", dice);
}

init_app_state :: proc(state: ^App_State) {
	reset_dice(&state.p1.dice);
	reset_dice(&state.p2.dice);

	state.client_packets = make_client_packet_queue();

	state.current_player = 1;
}

get_current_player :: proc(state: ^App_State) -> Player {
	if state.current_player == 0 {
		return state.p1;
	} else {
		return state.p2;
	}
}

get_player_with_id :: proc(state: ^App_State, id: i64) -> ^Player {
	if id == state.p1.id {
		return &state.p1;
	} else if id == state.p2.id {
		return &state.p2;
	}
	panic("[main] Invalid player id");
}
get_opposing_player :: proc(state: ^App_State, id: i64) -> ^Player {
	if id == state.p1.id {
		return &state.p2;
	} else if id == state.p2.id {
		return &state.p1;
	}
	panic("[main] Invalid player id");
}

get_next_dice_throw :: proc(state: ^App_State) -> int {
	throw: int = -1;

	if state.p1.dice[5] == -1 do reset_dice(&state.p1.dice);
	if state.p2.dice[5] == -1 do reset_dice(&state.p2.dice);

	for i in 0..<6 {
		if state.current_player == 0 {
			if state.p1.dice[i] != -1 {
				throw = state.p1.dice[i];
				state.p1.dice[i] = -1;
				return throw;
			}
		} else {
			if state.p2.dice[i] != -1 {
				throw = state.p2.dice[i];
				state.p2.dice[i] = -1;
				return throw;
			}
		}
	}
	return -1;
}

add_pieces :: proc(state: ^App_State, data: Init_Player_Setup_Data) {
	player_id := data.player_id;
	pieces := data.pieces;

	if player_id == state.p1.id {
		for &piece in pieces {
			piece.position.y = piece.position.y + BOARD_SIZE - 2;
			state.p1.pieces[piece.id] = piece;
			state.board[piece.position.y][piece.position.x] = &state.p1.pieces[piece.id];
		}
		state.p1.ready = true;
	} else if player_id == state.p2.id {
		for &piece in pieces {
			piece.position.y = 1 - piece.position.y;
			piece.position.x = BOARD_SIZE - piece.position.x - 1;
			state.p2.pieces[piece.id] = piece;
			state.board[piece.position.y][piece.position.x] = &state.p2.pieces[piece.id];
		}
		state.p2.ready = true;
	} else {
		panic("[main] invalid player id!");
	}
}

set_player_data :: proc(state: ^App_State, data: Player_Join_Data) {
	player: Player;
	player.id = data.id;
	player.color = data.color;
	player.name = data.name;
	player.socket = data.socket;

	if !state.p1.connected {
		player.dice = state.p1.dice;
		state.p1 = player;
		state.p1.connected = true;
	} else if !state.p2.connected {
		player.dice = state.p2.dice;
		state.p2 = player;
		state.p2.connected = true;
	}
}

print_board :: proc(state: App_State) {
	builder: strings.Builder; 
	strings.builder_init(&builder);

	// fmt.println() // separate for clarity
	strings.write_string(&builder, "\n");
	for col in state.board {
		for tile in col {
			// fmt.print("|");
			strings.write_string(&builder, "|");
			if tile == nil {
				// fmt.print(" ");
				strings.write_string(&builder, "     ")     
			} else {
				// fmt.print(get_piece_icon(tile^))
				strings.write_string(&builder, get_piece_icon(tile^));
			}
		}
		// fmt.println("|")
		strings.write_string(&builder, "|\n");

		for i in 0..<(5 * BOARD_SIZE + 10) {
			// fmt.print("-")
			strings.write_string(&builder, "-");
		}
		// fmt.println()
		strings.write_string(&builder, "\n");

	}
	fmt.println(strings.to_string(builder));
}

all_players_initialized :: proc(state: App_State) -> bool {
	return state.p1.connected && state.p2.connected;
}

all_players_ready :: proc(state: App_State) -> bool {
	return state.p1.ready && state.p2.ready;
}

move_piece :: proc(state: ^App_State, data: Move_Piece_Data, forced: bool = false) -> bool {
	player := get_player_with_id(state, data.player_id);

	piece_id := data.piece_id;
	target_tile := data.target_tile;
	piece := &player.pieces[piece_id];

	moves := get_available_actions(state^, piece^, state.current_throw);

	found := forced;
	for move in moves {
		if move.type == .MOVE && move.target_tile == target_tile {
			found = true;
			break;
		}
	}

	if !found do return false;

	state.board[piece.position.y][piece.position.x] = nil;
	piece.position = target_tile;
	state.board[piece.position.y][piece.position.x] = piece;

	return true;
}

attack_with_piece :: proc(state: ^App_State, data: Attack_Data) -> bool {
	player := get_player_with_id(state, data.player_id);

	piece_id := data.piece_id;
	target_tile := data.target_tile;
	piece := &player.pieces[piece_id];

	moves := get_available_actions(state^, piece^, state.current_throw);

	found := false
	for move in moves {
		if move.type == .ATTACK && move.target_tile == target_tile {
			found = true;
			break;
		}
	}

	if !found do return false;

	landing_tile := damage_piece(state, state.board[target_tile.y][target_tile.x], &player.pieces[piece_id]);

	fmt.println("[main] target tile: ", target_tile, ", landing tile: ", landing_tile);

	move_piece(state, Move_Piece_Data{
		player_id = data.player_id,
		piece_id = piece_id,
		target_tile = landing_tile,
	}, true)

	return true;
}

use_ability :: proc(state: ^App_State, data: Ability_Data) -> bool {
	player := get_player_with_id(state, data.player_id);
	piece_id := data.piece_id;
	piece := &player.pieces[piece_id];

	can_use_ability := check_ability_eligibility(state^, piece^, state.current_throw);

	if !can_use_ability do return false;

	switch ability_data in data.data {
		case Pawn_Ability_Data:
			piece.type = ability_data.type;
			piece.damage = get_type_dmg(ability_data.type) + 2;

			// fmt.println("[main] ", piece);
			piece.has_ability = false;
			return true;
		
		case Bishop_Ability_Data:
			if state.board[ability_data.tile.y][ability_data.tile.x] != nil {
				return false;
			}

			if length(piece.position - ability_data.tile) != 1.0 {
				return false;
			}

			move_piece(state, Move_Piece_Data{
				player_id = data.player_id,
				piece_id = piece_id,
				target_tile = ability_data.tile,
			}, true)

			piece.has_ability = false;

			return true;
		
		case Rook_Ability_Data:
			dir := ability_data.direction;

			affected_tiles := make([dynamic]v2i, 0);
			defer delete(affected_tiles);

			found_piece := false;
			last_safe_tile := piece.position;
			for i in 1..=BOARD_SIZE {
				current_tile := piece.position + i * dir;

				if !valid_board_place(current_tile) {
					break;
				}

				if state.board[current_tile.y][current_tile.x] == nil {
					last_safe_tile = current_tile;
					if found_piece {
						break;
					} else {
						continue;
					}
				}

				append(&affected_tiles, current_tile);
				found_piece = true;
			}

			// apply damages

			for tile in affected_tiles {
				damage_piece(state, state.board[tile.y][tile.x], piece, 2);
			}

			// move rook to final position
			move_piece(state, Move_Piece_Data{
				player_id = data.player_id,
				piece_id = piece_id,
				target_tile = last_safe_tile,
			}, true)

			piece.has_ability = false;

			print_board(state^);

			return true;
	}

	return false;
}

start_round :: proc(state: ^App_State) {
	state.current_player = (state.current_player + 1) % 2;
	state.current_throw = get_next_dice_throw(state);
}

ENDPOINT := net.Endpoint{address = net.IP4_Address{0, 0, 0, 0}, port = 4000};

// odin run ./backend/src -out:main.exe
main :: proc() {
	// initialize game

	state: App_State;
	init_app_state(&state);

	listener, err := net.listen_tcp(ENDPOINT);
	if err != nil{
		fmt.println("[main] Error at lisetner start", err);
		panic("");
	}

	for i in 0..<2{
		// sync.lock(&state.accepting_connection);
		// if all_players_initialized(state) {
		// 	break;
		// }
		client_socket, endpoint, err := net.accept_tcp(listener);
		if err != nil{
			fmt.println("[main] Error at accepting clients", err);
			panic("");
		}
		fmt.println("[main] Got connection: ", endpoint);
		
		scd := new(Server_Client_Data);
		scd.socket = client_socket;
		scd.state = &state;
		thread.create_and_start_with_data(scd, handle_incoming_packets);
		// thread.create_and_start_with_data(scd, handle_outgoing_packets);
	}

	fmt.println("[main] All Players connected (1/3)");

	for !all_players_initialized(state){
		if client_packet_queue_has(&state.client_packets) {
			packet := client_packet_queue_pop(&state.client_packets);
			decoded_packet := packet.data;

			#partial switch data in decoded_packet {
				case Player_Join_Data:
					set_player_data(&state, data);
				case Init_Player_Setup_Data:
					client_packet_queue_push(&state.client_packets, packet);
			}
		}
	}

	fmt.println("[main] All Players initialized (2/3)");


	for !all_players_ready(state) {
		if client_packet_queue_has(&state.client_packets) {
			packet := client_packet_queue_pop(&state.client_packets);
			decoded_packet := packet.data;

			#partial switch data in decoded_packet {
				case Init_Player_Setup_Data:
					add_pieces(&state, data);
			}
		}

	}

	fmt.println("[main] All Players ready (3/3)");

	print_board(state);

	
	init_board_packet := encode_init_board_state(&state);
	send_packet(state.p1.socket, init_board_packet);
	send_packet(state.p2.socket, init_board_packet);
	
	start_round(&state);

	init_round_start_packet := encode_round_start(state);

	send_packet(state.p1.socket, init_round_start_packet);
	send_packet(state.p2.socket, init_round_start_packet);
	
	// time.sleep(cast(time.Duration) seconds_to_sleep * time.Second);

	for {
		// TODO: "frame" allocator
		// handle inbound packets
		for client_packet_queue_has(&state.client_packets){
			packet := client_packet_queue_pop(&state.client_packets);
			decoded_packet := packet.data;
			// append(&decoded_packet_datas, decoded_packet);
			// update state	
			switch data in decoded_packet {
				case Player_Join_Data:
					fmt.println("[main] Player join should be handled earlier!")
					// set_player_data(&state, data);

				case Init_Player_Setup_Data:
					fmt.println("[main] Init setup should be handled earlier!")

					// add_pieces(&state, data);
				
				case Available_Move_Request_Data:
					if get_current_player(&state).id != data.player_id {
						break;
					}

					player := get_player_with_id(&state, data.player_id);
					moves_packet := encode_available_moves(&state, data.player_id, data.piece_id);

					send_packet(player.socket, moves_packet);
				
				case Move_Piece_Data:
					if get_current_player(&state).id != data.player_id {
						break;
					}

					ok := move_piece(&state, data);
					if !ok do break;

					piece_moved_packet := encode_piece_moved(state, data);

					send_packet(state.p1.socket, piece_moved_packet);
					send_packet(state.p2.socket, piece_moved_packet);

					start_round(&state);

					round_start_packet := encode_round_start(state);

					send_packet(state.p1.socket, round_start_packet);
					send_packet(state.p2.socket, round_start_packet);

				case Attack_Data:
					if get_current_player(&state).id != data.player_id {
						break;
					}

					m_data := data;
					m_data.target_piece_id = cast(u8) state.board[m_data.target_tile.y][m_data.target_tile.x].id
					ok := attack_with_piece(&state, m_data);
					if !ok do break;


					piece_attacked_packet := encode_piece_attacked(&state, m_data);
					
					send_packet(state.p1.socket, piece_attacked_packet);
					send_packet(state.p2.socket, piece_attacked_packet);

					start_round(&state);

					round_start_packet := encode_round_start(state);

					send_packet(state.p1.socket, round_start_packet);
					send_packet(state.p2.socket, round_start_packet);
				
				case Ability_Data:
					if get_current_player(&state).id != data.player_id {
						break;
					}

					ok := use_ability(&state, data);
					if !ok do break;


					used_ability_packet := encode_used_ability(&state, data);

					send_packet(state.p1.socket, used_ability_packet);
					send_packet(state.p2.socket, used_ability_packet);

					start_round(&state);

					round_start_packet := encode_round_start(state);

					send_packet(state.p1.socket, round_start_packet);
					send_packet(state.p2.socket, round_start_packet);


				case Empty_Packet_Data:
					fmt.println("[main] Empty packet huh?")
				case Exit_Data:
					fmt.println("[main] Player disconnected")

			}
		}
		// send new data to clients
	}
}

