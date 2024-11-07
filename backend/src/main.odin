package main

import "core:fmt"
import "core:math/rand"
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

	ready: bool,
}

NR_PIECES :: 14;
BOARD_SIZE :: 9;

App_State :: struct {
	mutex: sync.Mutex,
	accepting_connection: sync.Mutex,

	current_player: u8,
	board: [BOARD_SIZE][BOARD_SIZE]^Piece,

	p1: Player,
	p2: Player,

	p1pieces: [NR_PIECES]Piece,
	p2pieces: [NR_PIECES]Piece,

	p1dice: [6]int,
	p2dice: [6]int,

}

reset_dice :: proc(dice: ^[6]int) {
	dice^ = {1, 2, 3, 4, 5, 6};
	rand.shuffle(dice[:]);
	fmt.println("[main] New dice bag: ", dice);
}

init_app_state :: proc(state: ^App_State) {
	reset_dice(&state.p1dice);
	reset_dice(&state.p2dice);
}

get_next_dice_throw :: proc(state: ^App_State) -> int {
	throw: int = -1;

	if state.p1dice[5] == -1 do reset_dice(&state.p1dice);
	if state.p2dice[5] == -1 do reset_dice(&state.p2dice);

	for i in 0..<6 {
		if state.current_player == 0 {
			if state.p1dice[i] != -1 {
				throw = state.p1dice[i];
				state.p1dice[i] = -1;
				return throw;
			}
		} else {
			if state.p2dice[i] != -1 {
				throw = state.p2dice[i];
				state.p2dice[i] = -1;
				return throw;
			}
		}
	}
	return -1;
}

add_pieces :: proc(state: ^App_State, playerid: i64, pieces: [NR_PIECES]Piece) {
	sync.lock(&state.mutex);
	defer sync.unlock(&state.mutex);

	pieces := pieces

	if playerid == state.p1.id {
		for &piece in pieces {
			piece.position.y = piece.position.y + BOARD_SIZE - 2;
			state.p1pieces[piece.id] = piece;
			state.board[piece.position.y][piece.position.x] = &state.p1pieces[piece.id];
		}
		state.p1.ready = true;
	} else if playerid == state.p2.id {
		for &piece in pieces {
			piece.position.y = 1 - piece.position.y;
			piece.position.x = BOARD_SIZE - piece.position.x - 1;
			state.p2pieces[piece.id] = piece;
			state.board[piece.position.y][piece.position.x] = &state.p2pieces[piece.id];
		}
		state.p2.ready = true;
	} else {
		panic("[main] invalid player id!");
	}
}

set_player_data :: proc(state: ^App_State, player: Player) {
	// sync.lock(&state.mutex);
    defer sync.unlock(&state.accepting_connection);

	if !state.p1.connected {
		state.p1 = player;
		state.p1.connected = true;
		fmt.println(state.p1);
	} else if !state.p2.connected {
		state.p2 = player;
		state.p2.connected = true;
		fmt.println(state.p2);
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

ENDPOINT := net.Endpoint{address = net.IP4_Address{0, 0, 0, 0}, port = 4000};

// odin run ./backend/src -out:main.exe
main :: proc() {
	// initialize game

	state: App_State;
	init_app_state(&state);

	listener, err := net.listen_tcp(ENDPOINT);
	if err != nil{
		fmt.println("Error at lisetner start", err);
		panic("");
	}

	for {
		sync.lock(&state.accepting_connection);
		if all_players_initialized(state) {
			break;
		}
		client_socket, endpoint, err := net.accept_tcp(listener);
		if err != nil{
			fmt.println("Error at accepting clients", err);
			panic("");
		}
		fmt.println("Got connection: ", endpoint);
		
		scd := new(Server_Client_Data);
		scd.socket = client_socket;
		scd.state = &state;
		thread.create_and_start_with_data(scd, handle_client_connection);
	}

	for {
		sync.lock(&state.mutex);
		defer sync.unlock(&state.mutex);

		if all_players_ready(state) do break;
	}

	// add_pieces(&state, 0);
	// add_pieces(&state, 1);


	print_board(state);


	// for i in 0..<24{
	// 	// get input

	// 	// buf: [256]byte
	// 	// fmt.println("Press enter:")
	// 	// n, err := os.read(os.stdin, buf[:])
	// 	// if err != nil {
	// 	// 	fmt.eprintln("Error reading: ", err)
	// 	// 	return
	// 	// }
	// 	// str := string(buf[:n])
		
	// 	// update game logic
	// 	current_throw := get_next_dice_throw(&state);
	// 	fmt.println("Player ", state.current_player+1, ": ", current_throw);

	// 	state.current_player = (state.current_player + 1) % 2;
	// 	// broadcast changes
	// }
}

