extends Node2D
class_name Piece

@export
var piece_type: GlobalNames.PIECE_TYPE = GlobalNames.PIECE_TYPE.NONE:
	set(newType):
		if is_node_ready():
			%Sprite.texture = GlobalNames.piece_textures[newType]
		piece_type = newType

var position_on_board: Vector2i

var id: int = -1
var owner_player: int

func _ready() -> void:
	%Sprite.texture = GlobalNames.piece_textures[piece_type]

func set_position_on_board(newPos: Vector2i, board: Board) -> void:
	position_on_board = newPos
	global_position = board.index_to_position(newPos)
