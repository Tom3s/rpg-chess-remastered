extends Node2D
class_name GameScene

@onready var piece_scene: PackedScene = preload("res://Piece.tscn")

@onready var board: Board = %Board
@onready var p1_pieces: Node2D = %P1Pieces
@onready var p2_pieces: Node2D = %P2Pieces

var current_player: int
var current_throw: int

var available_moves: Array[Vector2i]
var available_attacks: Array[Vector2i]
var selected_piece: Piece = null

class BoardData:
	var board_data: Array[Piece] = []

	static func init() -> BoardData:
		var data := BoardData.new()
		data.board_data.resize(GlobalNames.BOARD_SIZE * GlobalNames.BOARD_SIZE)

		return data
	
	func set_tile(pos: Vector2i, piece: Piece) -> void:
		var index := pos.x + GlobalNames.BOARD_SIZE * pos.y
		if index >= board_data.size():
			return

		board_data[index] = piece
	
	func get_tile(pos: Vector2i) -> Piece:
		var index := pos.x + GlobalNames.BOARD_SIZE * pos.y
		if index >= board_data.size():
			return null

		var piece: Piece = board_data[index]
		print("[GameScene.gd] Board data index: ", index)
		print("[GameScene.gd] Selected piece: ", piece)

		return piece

var board_data: BoardData = BoardData.init()

func _ready() -> void:
	# if initialData.size() == 0:
	# 	print("[GameScene.gd] Piece data not initialized!")
	# else:
	# 	print("[GameScene.gd] Piece data successfully initialized")
	# 	print(initialData)
	initialize_board()

	Network.available_actions_received.connect(func(moves: Array[Vector2i], attacks: Array[Vector2i]) -> void:
		available_moves = moves
		available_attacks = attacks
	)

	Network.piece_moved.connect(move_piece)
	Network.round_started.connect(start_round)


func _process(_delta: float) -> void:
	if !is_current_player():
		return

	var hovering_tile := board.get_closest_tile(get_local_mouse_position())
	board.set_hovering_square(hovering_tile)

	if Input.is_action_just_pressed("left_click"):
		print("[GameScene] Clicked on tile ", hovering_tile)
		if board_data.get_tile(hovering_tile) != null:
			selected_piece = board_data.get_tile(hovering_tile)
			if selected_piece.owner_player != Network.main_player.id:
				board.clear_interactable_tiles()
				board.set_hovering_square(Vector2i.MAX)
				return
			Network.request_available_moves(selected_piece.id)
		else:
			if selected_piece != null:
				if available_moves.has(hovering_tile):
					Network.send_move_piece_packet(selected_piece.id, hovering_tile)
			selected_piece = null
			board.clear_interactable_tiles()
			board.set_hovering_square(Vector2i.MAX)


func initialize_board() -> void:
	if GlobalNames.initial_board_data.size() == 0:
		assert(false, "[GameScene.gd] Board data is empty; Exiting...")
	
	var p1_piece_data: Array[Piece] = GlobalNames.initial_board_data[0]
	
	var index: int = 0
	for p in p1_piece_data:
		var piece: Piece = piece_scene.instantiate()
		p1_pieces.add_child(piece)
		piece.piece_type = p.piece_type
		piece.set_position_on_board(p.position_on_board, board)
		piece.id = index
		piece.owner_player = p.owner_player
		board_data.set_tile(piece.position_on_board, piece)
		index += 1
	
	var p2_piece_data: Array[Piece] = GlobalNames.initial_board_data[1]
	
	index = 0
	for p in p2_piece_data:
		var piece: Piece = piece_scene.instantiate()
		p2_pieces.add_child(piece)
		piece.piece_type = p.piece_type
		piece.set_position_on_board(p.position_on_board, board)
		piece.id = index
		piece.owner_player = p.owner_player
		board_data.set_tile(piece.position_on_board, piece)
		index += 1
	
	GlobalNames.initial_board_data = []


func move_piece(player_id: int, piece_id: int, target_tile: Vector2i) -> void:
	var piece_parent: Node2D = null

	if player_id == Network.p1_id:
		piece_parent = p1_pieces
	else:
		piece_parent = p2_pieces
	
	var piece: Piece = piece_parent.get_child(piece_id)

	board_data.set_tile(piece.position_on_board, null)
	# piece.position_on_board = target_tile
	piece.set_position_on_board(target_tile, board)

	board_data.set_tile(piece.position_on_board, piece)

func start_round(player: int, throw: int) -> void:
	current_player = player
	current_throw = throw

func is_current_player() -> bool:
	var current_player_id := Network.p1_id
	if current_player == 1:
		current_player_id = Network.p2_id
	
	return Network.main_player.id == current_player_id
