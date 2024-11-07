extends Node
# class_name GlobalNames

enum PIECE_TYPE {
	PAWN, 
	BISHOP,
	ROOK,
	KNIGHT,
	QUEEN,
	# KING, # might change later
	NONE = -1,
}

const NR_PIECES := 14
const BOARD_SIZE := 9

var pieceTextures := [
	preload("res://Assets/Pawn_icon.png"),
	preload("res://Assets/Bishop_icon.png"),
	preload("res://Assets/Rook_icon.png"),
	preload("res://Assets/Knight_icon.png"),
	preload("res://Assets/Queen_icon.png"),
]

class Player:
	var id: int = -1
	var name: String = ""
	var color: Color = Color.WHITE