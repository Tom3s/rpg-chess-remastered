package main

import "core:fmt"
import "core:strings"
import "core:slice"

PIECE_TYPE :: enum {
	PAWN, 
	BISHOP,
	ROOK,
	KNIGHT,
	QUEEN,
	// KING, // might change later
}

Piece :: struct {
	id: int,
	owner: i64,

	position: v2i,

	health: int,
	damage: int,
	// armor: int,
	
	type: PIECE_TYPE,

	effects: [dynamic]Effect,

	
}

ACTION_TYPE :: enum {
	MOVE,
	ATTACK,
	// CAST, // for attacks that doesn't move the piece
}

Action :: struct {
	type: ACTION_TYPE,
	target_tile: v2i,
	cost: int,
}

init_piece :: proc(type: PIECE_TYPE, owner: i64, position: v2i = {0, 0}, id: int = 0) -> Piece {
	piece: Piece;

	piece.owner = owner;
	piece.position = position;
	piece.id = id;
	piece.type = type;

	switch (type) {
		case .PAWN:
			piece.health = 5;
			piece.damage = 3;
		case .ROOK:
			piece.health = 9;
			piece.damage = 4;
		case .BISHOP:
			piece.health = 8;
			piece.damage = 5;
		case .KNIGHT:
			piece.health = 5;
			piece.damage = 8;
		case .QUEEN:
			piece.health = 15;
			piece.damage = 2;

	}

	return piece;
}

get_piece_icon :: proc(piece: Piece) -> string {
	builder: strings.Builder; 
	strings.builder_init(&builder);

	switch (piece.type) {
		case .PAWN:
			strings.write_string(&builder, "P: ");

		case .ROOK:
			strings.write_string(&builder, "R: ");
			
		case .BISHOP:
			strings.write_string(&builder, "B: ");
			
		case .KNIGHT:
			strings.write_string(&builder, "N: ");
			
		case .QUEEN:
			strings.write_string(&builder, "Q: ");
	} 
	
	if piece.id <= 9 do strings.write_string(&builder, " ");
	
	strings.write_int(&builder, piece.id);

	return strings.to_string(builder);
}

// switch (piece.type) {
// 	case .PAWN:
// 	case .ROOK:
// 	case .BISHOP:
// 	case .KNIGHT:
// 	case .QUEEN:
// } 

get_available_moves :: proc(state: App_State, piece: Piece, cost: int) -> []Action {
	moves := make([dynamic]Action);
	defer delete(moves);
	
	up: v2i = {0, 1};
	down: v2i = {0, -1};
	left: v2i = {-1, 0};
	right: v2i = {1, 0};
	
	up_left: v2i = {-1, 1};
	down_left: v2i = {-1, -1};
	up_right: v2i = {1, 1};
	down_right: v2i = {1, -1};
	
	fmt.println("current move cost limit: ", cost);

	switch (piece.type) {
		case .PAWN:
			for i in 1..=cost {
				move := piece.position + i * up;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}

			for i in 1..=cost {
				move := piece.position + i * down;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}

		case .ROOK:
			for i in 1..=cost {
				move := piece.position + i * up;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}

			for i in 1..=cost {
				move := piece.position + i * down;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}
			for i in 1..=cost {
				move := piece.position + i * left;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}

			for i in 1..=cost {
				move := piece.position + i * right;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}

		case .BISHOP:
			for i in 1..=cost {
				move := piece.position + i * up_left;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}

			for i in 1..=cost {
				move := piece.position + i * down_left;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}
			
			for i in 1..=cost {
				move := piece.position + i * up_right;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}

			for i in 1..=cost {
				move := piece.position + i * down_right;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}
		case .KNIGHT:
			knight_moves: [4]v2i = {
				{1, 2},
				{2, 1},
				{-1, 2},
				{-2, 1},
			}

			for i in 0..<4 {
				move := piece.position + knight_moves[i];
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = 1,
					});
				}
				
				move = piece.position - knight_moves[i];
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = 1,
					});
				}

			}
		case .QUEEN:
			for i in 1..=cost {
				move := piece.position + i * up;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}

			for i in 1..=cost {
				move := piece.position + i * down;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}
			for i in 1..=cost {
				move := piece.position + i * left;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}

			for i in 1..=cost {
				move := piece.position + i * right;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}
			
			for i in 1..=cost {
				move := piece.position + i * up_left;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}

			for i in 1..=cost {
				move := piece.position + i * down_left;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}
			
			for i in 1..=cost {
				move := piece.position + i * up_right;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}

			for i in 1..=cost {
				move := piece.position + i * down_right;
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = i,
					});
				} else do break;
			}
	} 
	return slice.reinterpret([]Action, moves[:]);
}

@private
valid_move :: proc(state: App_State, move: v2i) -> bool {
	if move.x < 0 || move.x >= 9 do return false;
	if move.y < 0 || move.y >= 9 do return false;

	if state.board[move.y][move.x] != nil do return false;

	return true;
}
