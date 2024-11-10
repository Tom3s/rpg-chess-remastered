extends Node2D
class_name GameScene

@onready var pieceScene: PackedScene = preload("res://Piece.tscn")

@onready var board: Board = %Board
@onready var p1Pieces: Node2D = %P1Pieces
@onready var p2Pieces: Node2D = %P2Pieces

func _ready() -> void:
	# if initialData.size() == 0:
	# 	print("[GameScene.gd] Piece data not initialized!")
	# else:
	# 	print("[GameScene.gd] Piece data successfully initialized")
	# 	print(initialData)
	initialize_board()

func initialize_board() -> void:
	if GlobalNames.initialBoardData.size() == 0:
		assert(false, "[GameScene.gd] Board data is empty; Exiting...")
	
	var p1PieceData: Array[Piece] = GlobalNames.initialBoardData[0]
	
	for p in p1PieceData:
		var piece: Piece = pieceScene.instantiate()
		p1Pieces.add_child(piece)
		piece.pieceType = p.pieceType
		piece.setPosition(p.positionOnBoard, board)
	
	var p2PieceData: Array[Piece] = GlobalNames.initialBoardData[1]
	
	for p in p2PieceData:
		var piece: Piece = pieceScene.instantiate()
		p2Pieces.add_child(piece)
		piece.pieceType = p.pieceType
		piece.setPosition(p.positionOnBoard, board)


