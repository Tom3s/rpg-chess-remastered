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
var target_positions: PackedVector2Array

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
	set_position_on_board_no_anim(pos, board)
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

const EPSILON = 0.01

@export
var MOVE_SPEED: float = 15

func _process(delta: float) -> void:
	if !target_positions.is_empty():
		var e_multiplier := 1.0
		var s_multiplier := 1.0
		if target_positions.size() > 1:
			e_multiplier = 1000.0
			s_multiplier = 2.4

		var target_global_pos := target_positions[0]
		global_position = lerp(global_position, target_global_pos, MOVE_SPEED * delta * s_multiplier)


		if (target_global_pos - global_position).length() <= EPSILON * e_multiplier:
			target_positions.remove_at(0)


func set_position_on_board(newPos: Vector2i, board: Board) -> void:
	position_on_board = newPos
	# target_global_pos = board.index_to_position(newPos)
	target_positions.push_back(board.index_to_position(newPos))



func set_position_on_board_no_anim(newPos: Vector2i, board: Board) -> void:
	position_on_board = newPos
	global_position = board.index_to_position(newPos)
	# target_global_pos = global_position
	target_positions.push_back(board.index_to_position(newPos))


func set_hp(new_hp: int) -> void:
	print("[Piece.gd] Setting hp of ", id, " to ", new_hp)
	health = new_hp

	if health <= 0:
		visible = false

	refresh_health_label()

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	refresh_health_label()

func refresh_health_label() -> void:
	hp_label.text = "\nHP: " + str(health) + "/" + str(max_health)

func _to_string() -> String:
	return "{" + GlobalNames.PIECE_TYPE.keys()[piece_type] + "(id: " + str(id) + "): " + hp_label.text.replace("\n", "") + "}"