extends Node2D
class_name SetupBuilder

@onready var pieceScene: PackedScene = preload("res://Piece.tscn")

@onready var floatingPreview: Sprite2D = %FloatingPreview
@onready var transparentPreview: Sprite2D = %TransparentPreview
@onready var camera: Camera2D = %Camera
@onready var board: Board = %Board

@onready var pieceButtons: VBoxContainer = %PieceButtons
@onready var placedPiecesLabel: Label = %PlacedPiecesLabel
@onready var resetButton: Button = %ResetButton
@onready var randomButton: Button = %RandomButton
@onready var readyButton: Button = %ReadyButton

@onready var pieces: Node2D = %Pieces

# var showPlacementPreview: bool = false
var selectedPiece: GlobalNames.PIECE_TYPE = GlobalNames.PIECE_TYPE.NONE
var available: int = GlobalNames.NR_PIECES:
	set(newAvailable):
		if newAvailable <= 0:
			selectedPiece = GlobalNames.PIECE_TYPE.NONE
			floatingPreview.visible = false
			transparentPreview.visible = false

			for button in pieceButtons.get_children():
				button.disabled = true
		else:
			for button in pieceButtons.get_children():
				button.disabled = button.available <= 0
		available = newAvailable

		readyButton.disabled = available != 0

		setPlacedPiecesLabel()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	floatingPreview.visible = false
	for child in pieceButtons.get_children():
		var button: PieceSelectorButton = child
		button.button_down.connect(func() -> void:
			floatingPreview.visible = true
			selectedPiece = button.pieceType
			floatingPreview.texture = GlobalNames.pieceTextures[selectedPiece]
			transparentPreview.texture = GlobalNames.pieceTextures[selectedPiece]
		)
		button.button_up.connect(func() -> void:
			floatingPreview.visible = false

			placePiece()

			if !button.button_pressed:
				selectedPiece = GlobalNames.PIECE_TYPE.NONE
			
		)
		button.toggled.connect(func(toggled_on: bool) -> void:
			if toggled_on:
				for otherButton in pieceButtons.get_children():
					if otherButton != button:
						otherButton.button_pressed = false
			elif selectedPiece == button.pieceType:
				selectedPiece = GlobalNames.PIECE_TYPE.NONE
		)

	resetButton.pressed.connect(resetBoard)
	randomButton.pressed.connect(randomizeBoard)

	readyButton.pressed.connect(playerReady)

	setPlacedPiecesLabel()
	
func setPlacedPiecesLabel() -> void:
	placedPiecesLabel.text = "Pieces: " + str(GlobalNames.NR_PIECES - available) + "/" + str(GlobalNames.NR_PIECES)
				


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mosue_pos := get_local_mouse_position() 
	floatingPreview.global_position = mosue_pos

	var closestTile := board.getClosestTile(mosue_pos)
	transparentPreview.visible = closestTile != Vector2i.MAX \
		&& (floatingPreview.visible || selectedPiece != GlobalNames.PIECE_TYPE.NONE)
	transparentPreview.global_position = board.indexToPosition(closestTile)

	if selectedPiece != GlobalNames.PIECE_TYPE.NONE:
		if Input.is_action_just_released("left_click"):
			placePiece()

	if !floatingPreview.visible && selectedPiece == GlobalNames.PIECE_TYPE.NONE:
		if Input.is_action_just_pressed("left_click"):
			grabPiece()

func placePiece() -> void:
	floatingPreview.visible = false
	if !pieceButtons.get_child(selectedPiece).button_pressed:
		transparentPreview.visible = false
	var closestTile := board.getClosestTile(get_local_mouse_position())
	if closestTile == Vector2i.MAX:
		if !pieceButtons.get_child(selectedPiece).button_pressed: 
			selectedPiece = GlobalNames.PIECE_TYPE.NONE
		return

	if pieceButtons.get_child(selectedPiece).available <= 0: return



	for piece in pieces.get_children():
		if piece.positionOnBoard == closestTile:
			pieceButtons.get_child(piece.pieceType).available += 1
			pieceButtons.get_child(selectedPiece).available -= 1
			piece.pieceType = selectedPiece
			if pieceButtons.get_child(selectedPiece).available <= 0:
				selectedPiece = GlobalNames.PIECE_TYPE.NONE
			if !pieceButtons.get_child(selectedPiece).button_pressed: 
				selectedPiece = GlobalNames.PIECE_TYPE.NONE




			return

	var piece: Piece = pieceScene.instantiate()
	pieces.add_child(piece)
	piece.positionOnBoard = closestTile
	piece.global_position = board.indexToPosition(closestTile)
	piece.pieceType = selectedPiece
	pieceButtons.get_child(selectedPiece).available -= 1
	available -= 1
	if pieceButtons.get_child(selectedPiece).available <= 0:
		selectedPiece = GlobalNames.PIECE_TYPE.NONE
	if !pieceButtons.get_child(selectedPiece).button_pressed: 
		selectedPiece = GlobalNames.PIECE_TYPE.NONE

func grabPiece() -> void:
	print("Grabbing")
	var closestTile := board.getClosestTile(get_local_mouse_position())
	if closestTile == Vector2i.MAX: return

	for piece in pieces.get_children():
		if piece.positionOnBoard == closestTile:
			pieceButtons.get_child(piece.pieceType).available += 1
			available += 1
			# pieceButtons.get_child(piece.pieceType).button_pressed = true
			selectedPiece = piece.pieceType
			floatingPreview.texture = GlobalNames.pieceTextures[selectedPiece]
			transparentPreview.texture = GlobalNames.pieceTextures[selectedPiece]
			floatingPreview.visible = true
			transparentPreview.visible = true


			piece.queue_free()

			break

func resetBoard() -> void:
	for piece in pieces.get_children():
		piece.queue_free()
	
	for button in pieceButtons.get_children():
		button.available = button.maxAvailable
	
	available = GlobalNames.NR_PIECES

func randomizeBoard() -> void:
	resetBoard()

	var tiles: Array[Vector2i]
	for i in GlobalNames.BOARD_SIZE:
		tiles.push_back(Vector2i(i, 0))
		tiles.push_back(Vector2i(i, 1))
	
	var pieceTypes: Array[GlobalNames.PIECE_TYPE]
	for b in pieceButtons.get_children():
		var button: PieceSelectorButton = b 
		for i in button.available:
			pieceTypes.push_back(button.pieceType)
	
	for i in GlobalNames.NR_PIECES:
		var tile: Vector2i = tiles.pick_random()
		tiles.erase(tile)

		var type: GlobalNames.PIECE_TYPE = pieceTypes.pick_random()
		pieceTypes.erase(type)

		var piece: Piece = pieceScene.instantiate()
		pieces.add_child(piece)
		piece.positionOnBoard = tile
		piece.global_position = board.indexToPosition(tile)
		piece.pieceType = type
		pieceButtons.get_child(type).available -= 1
	
	# transparentPreview.visible = false
	selectedPiece = GlobalNames.PIECE_TYPE.NONE


	available = 0


func playerReady() -> void:
	Network.send_inital_setup_packet(pieces)

	# Network.receive_packet()