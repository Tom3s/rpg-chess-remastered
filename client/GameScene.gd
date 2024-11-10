extends Node2D
class_name GameScene

@onready var pieceScene: PackedScene = preload("res://Piece.tscn")

@onready var board: Board = %Board
@onready var p1Pieces: Node2D = %P1Pieces
@onready var p2Pieces: Node2D = %P2Pieces

class BoardData:
	var boardData: Array[Piece] = []

	static func init() -> BoardData:
		var data := BoardData.new()
		data.boardData.resize(GlobalNames.BOARD_SIZE * GlobalNames.BOARD_SIZE)

		return data
	
	func setTile(pos: Vector2i, piece: Piece) -> void:
		boardData[pos.x + GlobalNames.BOARD_SIZE * pos.y] = piece
	
	func getTile(pos: Vector2i) -> Piece:
		var piece: Piece = boardData[pos.x + GlobalNames.BOARD_SIZE * pos.y]
		print("[GameScene.gd] Board data index: ", pos.x + GlobalNames.BOARD_SIZE * pos.y)
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

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("left_click"):
		var tile: Vector2i = board.getClosestTile(get_local_mouse_position())
		print("[GameScene] Clicked on tile ", tile)
		if boardData.getTile(tile) != null:
			Network.request_available_moves(boardData.getTile(tile).id)
		else:
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
		boardData.setTile(piece.positionOnBoard, piece)
		index += 1


