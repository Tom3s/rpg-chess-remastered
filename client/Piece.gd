extends Node2D
class_name Piece

@export
var pieceType: GlobalNames.PIECE_TYPE = GlobalNames.PIECE_TYPE.NONE:
	set(newType):
		if is_node_ready():
			%Sprite.texture = GlobalNames.pieceTextures[newType]
		pieceType = newType

var positionOnBoard: Vector2i

func _ready() -> void:
	%Sprite.texture = GlobalNames.pieceTextures[pieceType]

func setPosition(newPos: Vector2i, board: Board) -> void:
	positionOnBoard = newPos
	global_position = board.indexToPosition(newPos)

