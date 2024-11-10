extends Node2D
class_name GameScene

@onready var pieceScene: PackedScene = preload("res://Piece.tscn")

@onready var board: Board = %Board
@onready var p1Pieces: Node2D = %P1Pieces
@onready var p2Pieces: Node2D = %P2Pieces

var current_player: int
var current_throw: int

var availableMoves: Array[Vector2i]
var selectedPiece: Piece = null

class BoardData:
	var boardData: Array[Piece] = []

	static func init() -> BoardData:
		var data := BoardData.new()
		data.boardData.resize(GlobalNames.BOARD_SIZE * GlobalNames.BOARD_SIZE)

		return data
	
	func setTile(pos: Vector2i, piece: Piece) -> void:
		var index := pos.x + GlobalNames.BOARD_SIZE * pos.y
		if index >= boardData.size():
			return

		boardData[index] = piece
	
	func getTile(pos: Vector2i) -> Piece:
		var index := pos.x + GlobalNames.BOARD_SIZE * pos.y
		if index >= boardData.size():
			return null

		var piece: Piece = boardData[index]
		print("[GameScene.gd] Board data index: ", index)
		print("[GameScene.gd] Selected piece: ", piece)

		return piece

var boardData: BoardData = BoardData.init()

func _ready() -> void:
	# if initialData.size() == 0:
	# 	print("[GameScene.gd] Piece data not initialized!")
	# else:
	# 	print("[GameScene.gd] Piece data successfully initialized")
	# 	print(initialData)
	initialize_board()

	Network.available_moves_received.connect(func(moves: Array[Vector2i]) -> void:
		availableMoves = moves
	)

	Network.piece_moved.connect(move_piece)
	Network.round_started.connect(start_round)


func _process(_delta: float) -> void:
	if !is_current_player():
		return

	var hoveringTile := board.getClosestTile(get_local_mouse_position())
	board.setHoveringSquare(hoveringTile)

	if Input.is_action_just_pressed("left_click"):
		print("[GameScene] Clicked on tile ", hoveringTile)
		if boardData.getTile(hoveringTile) != null:
			selectedPiece = boardData.getTile(hoveringTile)
			if selectedPiece.owner_player != Network.mainPlayer.id:
				board.setReachableTiles([])
				return
			Network.request_available_moves(selectedPiece.id)
		else:
			if selectedPiece != null:
				if availableMoves.has(hoveringTile):
					Network.send_move_piece_packet(selectedPiece.id, hoveringTile)
			selectedPiece = null
			board.setReachableTiles([])

func initialize_board() -> void:
	if GlobalNames.initialBoardData.size() == 0:
		assert(false, "[GameScene.gd] Board data is empty; Exiting...")
	
	var p1PieceData: Array[Piece] = GlobalNames.initialBoardData[0]
	
	var index: int = 0
	for p in p1PieceData:
		var piece: Piece = pieceScene.instantiate()
		p1Pieces.add_child(piece)
		piece.pieceType = p.pieceType
		piece.setPosition(p.positionOnBoard, board)
		piece.id = index
		piece.owner_player = p.owner_player
		boardData.setTile(piece.positionOnBoard, piece)
		index += 1
	
	var p2PieceData: Array[Piece] = GlobalNames.initialBoardData[1]
	
	index = 0
	for p in p2PieceData:
		var piece: Piece = pieceScene.instantiate()
		p2Pieces.add_child(piece)
		piece.pieceType = p.pieceType
		piece.setPosition(p.positionOnBoard, board)
		piece.id = index
		piece.owner_player = p.owner_player
		boardData.setTile(piece.positionOnBoard, piece)
		index += 1
	
	GlobalNames.initialBoardData = []


func move_piece(player_id: int, piece_id: int, target_tile: Vector2i) -> void:
	var piece_parent: Node2D = null

	if player_id == Network.p1_id:
		piece_parent = p1Pieces
	else:
		piece_parent = p2Pieces
	
	var piece: Piece = piece_parent.get_child(piece_id)

	boardData.setTile(piece.positionOnBoard, null)
	# piece.positionOnBoard = target_tile
	piece.setPosition(target_tile, board)

	boardData.setTile(piece.positionOnBoard, piece)

func start_round(player: int, throw: int) -> void:
	current_player = player
	current_throw = throw

func is_current_player() -> bool:
	var current_player_id := Network.p1_id
	if current_player == 1:
		current_player_id = Network.p2_id
	
	return Network.mainPlayer.id == current_player_id
