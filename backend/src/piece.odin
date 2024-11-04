package main

PIECE_TYPE :: enum {
	PAWN, 
	BISHOP,
	ROOK,
	KNIGHT,
	QUEEN,
	// KING, // might change later
}

Piece :: struct {
	position: v2i,

	health: int,
	damage: int,
	
	type: PIECE_TYPE,

	effects: [dynamic]Effect,

	
}