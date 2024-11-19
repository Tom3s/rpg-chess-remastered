package main

import "core:fmt"
import "core:strings"
import "core:slice"
import "core:math/linalg"

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
	max_health: int,
	damage: int,
	// armor: int,
	
	type: PIECE_TYPE,

	effects: [dynamic]Effect,

	
}

ACTION_TYPE :: enum {
	MOVE,
	ATTACK,
	// ABILITY, 
	// CAST, // for attacks that doesn't move the piece
}

Action :: struct {
	type: ACTION_TYPE,
	target_tile: v2i,
	cost: int,
}

get_type_hp :: proc(type: PIECE_TYPE) -> int{
	switch (type) {
		case .PAWN:
			return 5;
			
		case .ROOK:
			return 9;
			
		case .BISHOP:
			return 8;
			
		case .KNIGHT:
			return 5;
			
		case .QUEEN:
			return 15;
	}

	return -1;
}

get_type_dmg :: proc(type: PIECE_TYPE) -> int{
	switch (type) {
		case .PAWN:
			return 3;

		case .ROOK:
			return 4;

		case .BISHOP:
			return 5;

		case .KNIGHT:
			return 8;

		case .QUEEN:
			return 2;
	}

	return 0;
}

init_piece :: proc(type: PIECE_TYPE, owner: i64, position: v2i = {0, 0}, id: int = 0) -> Piece {
	piece: Piece;

	piece.owner = owner;
	piece.position = position;
	piece.id = id;
	piece.type = type;

	piece.health = get_type_hp(type);
	piece.damage = get_type_dmg(type);

	piece.max_health = piece.health;

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

get_available_actions :: proc(state: App_State, piece: Piece, cost: int) -> []Action {
	moves := make([dynamic]Action);
	// defer delete(moves);
	
	up: v2i = {0, 1};
	down: v2i = {0, -1};
	left: v2i = {-1, 0};
	right: v2i = {1, 0};
	
	up_left: v2i = {-1, 1};
	down_left: v2i = {-1, -1};
	up_right: v2i = {1, 1};
	down_right: v2i = {1, -1};
	
	// fmt.println("current move cost limit: ", cost);

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
				}  else do break;
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
			pawn_attacks: [4]v2i = {
				{1, 1},
				{1, -1},
				{-1, 1},
				{-1, -1},
			}
			for attack in pawn_attacks {
				move := piece.position + attack;
				if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = 4,
					})
				}
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = 4,
					})
				} 
				
				move = piece.position - knight_moves[i];
				if valid_move(state, move) {
					append(&moves, Action{
						type = .MOVE,
						target_tile = move,
						cost = 1,
					});
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = 4,
					})
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
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
				} else if valid_attack(state, move, piece.owner, cost) {
					append(&moves, Action{
						type = .ATTACK,
						target_tile = move,
						cost = i,
					})
					break;
				} else do break;
			}
	} 

	// fmt.println("[piece] Moves for ", piece.owner, ", piece ", piece.id, moves);

	return slice.reinterpret([]Action, moves[:]);
}

@private
valid_move :: proc(state: App_State, move: v2i) -> bool {
	if move.x < 0 || move.x >= BOARD_SIZE do return false;
	if move.y < 0 || move.y >= BOARD_SIZE do return false;

	if state.board[move.y][move.x] != nil do return false;

	return true;
}

@private
valid_attack :: proc(state: App_State, move: v2i, piece_owner: i64, cost: int) -> bool {
	if cost < 4 do return false;
	if move.x < 0 || move.x >= BOARD_SIZE do return false;
	if move.y < 0 || move.y >= BOARD_SIZE do return false;

	if state.board[move.y][move.x] == nil do return false;

	return state.board[move.y][move.x].owner != piece_owner;
}

damage_piece :: proc(state: ^App_State, target_piece, attacking_piece: ^Piece) -> v2i {
	fmt.println("[piece] ", attacking_piece, " is attacking ", target_piece);
	target_piece.health -= attacking_piece.damage;

	landing_tile := get_landing_tile(state, target_piece^, attacking_piece^);
	if target_piece.health <= 0 {
		kill_piece(state, target_piece);
		landing_tile = target_piece.position;
	}

	// TODO: special case for KNIGHT

	fmt.println("[piece] Calculated landing tile: ", landing_tile);

	return landing_tile;
}

kill_piece :: proc(state: ^App_State, target_piece: ^Piece) {
	state.board[target_piece.position.y][target_piece.position.x] = nil;
}

get_landing_tile :: proc(state: ^App_State, target_piece, attacking_piece: Piece) -> v2i {
	if attacking_piece.type != .KNIGHT {
		return target_piece.position + normalize_int(attacking_piece.position - target_piece.position);
	}

	// diagonal to target
	normalized_dir := normalize_int(attacking_piece.position - target_piece.position);
	potential_landing_tile := target_piece.position + normalized_dir
	if state.board[potential_landing_tile.y][potential_landing_tile.x] == nil {
		return potential_landing_tile;
	}
	
	// horizontal to target
	potential_landing_tile = target_piece.position + v2i{normalized_dir.x, 0};
	if state.board[potential_landing_tile.y][potential_landing_tile.x] == nil {
		return potential_landing_tile;
	}

	// vertical to target
	potential_landing_tile = target_piece.position + v2i{0, normalized_dir.y};
	if state.board[potential_landing_tile.y][potential_landing_tile.x] == nil {
		return potential_landing_tile;
	}

	relative_pos := target_piece.position - attacking_piece.position
	relative_last_tile := (relative_pos + normalized_dir) * -2;
	// next to local
	potential_landing_tile = target_piece.position + relative_last_tile;
	if state.board[potential_landing_tile.y][potential_landing_tile.x] == nil {
		return potential_landing_tile;
	}

	// stay in place if no other option
	return attacking_piece.position;
}

check_ability_eligibility :: proc(state: App_State, piece: Piece, throw: int) -> bool {
	switch (piece.type) {
		case .PAWN:
			location_reached := false;
			if piece.owner == state.p1.id {
				// piece must be at the top of the board
				location_reached = piece.position.y == 0;
			} else if piece.owner == state.p2.id {
				// piece must be at the bottom of the board
				location_reached = piece.position.y == (BOARD_SIZE - 1);
			}

			// TODO: maybe move ability costs to a different place
			return throw >= 3 && location_reached;
			
		case .BISHOP:
			return false;

		case .KNIGHT:
			return false;

		case .QUEEN:
			return false;

		case .ROOK:
			return false;
	}

	return false;
}