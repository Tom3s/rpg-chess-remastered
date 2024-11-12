extends Node2D
class_name Piece

@onready var hp_label: Label = %HPLabel

@export
var piece_type: GlobalNames.PIECE_TYPE = GlobalNames.PIECE_TYPE.NONE:
	set(newType):
		if is_node_ready():
			%Sprite.texture = GlobalNames.piece_textures[newType]
		piece_type = newType

var position_on_board: Vector2i

var id: int = -1
var owner_player: int

var health: int = 0
var max_health: int = 0
var damage: int = 0


func init_piece(
	type: GlobalNames.PIECE_TYPE, 
	pos: Vector2i, 
	board: Board,
	init_id: int,
	init_owner: int,
) -> void:
	piece_type = type
	set_position_on_board(pos, board)
	id = init_id
	owner_player = init_owner

	if owner_player == Network.main_player.id:
		%Sprite.modulate = Network.main_player.color

	init_stats()

func init_stats() -> void:
	match piece_type:
		GlobalNames.PIECE_TYPE.PAWN:
			health = 5
			damage = 3
		GlobalNames.PIECE_TYPE.ROOK:
			health = 9
			damage = 4
		GlobalNames.PIECE_TYPE.BISHOP:
			health = 8
			damage = 5
		GlobalNames.PIECE_TYPE.KNIGHT:
			health = 5
			damage = 8
		GlobalNames.PIECE_TYPE.QUEEN:
			health = 15
			damage = 2

	max_health = health
	set_hp(health)

func _ready() -> void:
	%Sprite.texture = GlobalNames.piece_textures[piece_type]

func set_position_on_board(newPos: Vector2i, board: Board) -> void:
	position_on_board = newPos
	global_position = board.index_to_position(newPos)

func set_hp(new_hp: int) -> void:
	print("[Piece.gd] Setting hp of ", id, " to ", new_hp)
	health = new_hp

	if health <= 0:
		visible = false

	hp_label.text = "\nHP: " + str(health) + "/" + str(max_health)