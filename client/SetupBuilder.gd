extends Node2D
class_name SetupBuilder

@onready var piece_scene: PackedScene = preload("res://Piece.tscn")

@onready var floating_preview: Sprite2D = %FloatingPreview
@onready var transparent_review: Sprite2D = %TransparentPreview
@onready var camera: Camera2D = %Camera
@onready var board: Board = %Board

@onready var piece_buttons: VBoxContainer = %PieceButtons
@onready var placed_pieces_label: Label = %PlacedPiecesLabel
@onready var reset_button: Button = %ResetButton
@onready var random_button: Button = %RandomButton
@onready var ready_button: Button = %ReadyButton

@onready var pieces: Node2D = %Pieces

# var showPlacementPreview: bool = false
var selected_piece: GlobalNames.PIECE_TYPE = GlobalNames.PIECE_TYPE.NONE
var available: int = GlobalNames.NR_PIECES:
	set(new_available):
		if new_available <= 0:
			selected_piece = GlobalNames.PIECE_TYPE.NONE
			floating_preview.visible = false
			transparent_review.visible = false

			for button in piece_buttons.get_children():
				button.disabled = true
		else:
			for button in piece_buttons.get_children():
				button.disabled = button.available <= 0
		available = new_available

		ready_button.disabled = available != 0

		set_placed_pieces_label()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	floating_preview.visible = false
	for child in piece_buttons.get_children():
		var button: PieceSelectorButton = child
		button.button_down.connect(func() -> void:
			floating_preview.visible = true
			selected_piece = button.piece_type
			floating_preview.texture = GlobalNames.piece_textures[selected_piece]
			transparent_review.texture = GlobalNames.piece_textures[selected_piece]
		)
		button.button_up.connect(func() -> void:
			floating_preview.visible = false

			place_piece()

			if !button.button_pressed:
				selected_piece = GlobalNames.PIECE_TYPE.NONE
			
		)
		button.toggled.connect(func(toggled_on: bool) -> void:
			if toggled_on:
				for otherButton in piece_buttons.get_children():
					if otherButton != button:
						otherButton.button_pressed = false
			elif selected_piece == button.piece_type:
				selected_piece = GlobalNames.PIECE_TYPE.NONE
		)

	reset_button.pressed.connect(reset_board)
	random_button.pressed.connect(randomize_board)

	ready_button.pressed.connect(player_ready)

	set_placed_pieces_label()
	
func set_placed_pieces_label() -> void:
	placed_pieces_label.text = "Pieces: " + str(GlobalNames.NR_PIECES - available) + "/" + str(GlobalNames.NR_PIECES)
				


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mosue_pos := get_local_mouse_position() 
	floating_preview.global_position = mosue_pos

	var closest_tile := board.get_closest_tile(mosue_pos)
	transparent_review.visible = closest_tile != Vector2i.MAX \
		&& (floating_preview.visible || selected_piece != GlobalNames.PIECE_TYPE.NONE)
	transparent_review.global_position = board.index_to_position(closest_tile)

	if selected_piece != GlobalNames.PIECE_TYPE.NONE:
		if Input.is_action_just_released("left_click"):
			place_piece()

	if !floating_preview.visible && selected_piece == GlobalNames.PIECE_TYPE.NONE:
		if Input.is_action_just_pressed("left_click"):
			grab_piece()

func place_piece() -> void:
	floating_preview.visible = false
	if !piece_buttons.get_child(selected_piece).button_pressed:
		transparent_review.visible = false
	var closest_tile := board.get_closest_tile(get_local_mouse_position())
	if closest_tile == Vector2i.MAX:
		if !piece_buttons.get_child(selected_piece).button_pressed: 
			selected_piece = GlobalNames.PIECE_TYPE.NONE
		return

	if piece_buttons.get_child(selected_piece).available <= 0: return



	for piece in pieces.get_children():
		if piece.position_on_board == closest_tile:
			piece_buttons.get_child(piece.piece_type).available += 1
			piece_buttons.get_child(selected_piece).available -= 1
			piece.piece_type = selected_piece
			if piece_buttons.get_child(selected_piece).available <= 0:
				selected_piece = GlobalNames.PIECE_TYPE.NONE
			if !piece_buttons.get_child(selected_piece).button_pressed: 
				selected_piece = GlobalNames.PIECE_TYPE.NONE




			return

	var piece: Piece = piece_scene.instantiate()
	pieces.add_child(piece)
	piece.position_on_board = closest_tile
	piece.global_position = board.index_to_position(closest_tile)
	piece.piece_type = selected_piece
	piece_buttons.get_child(selected_piece).available -= 1
	available -= 1
	if piece_buttons.get_child(selected_piece).available <= 0:
		selected_piece = GlobalNames.PIECE_TYPE.NONE
	if !piece_buttons.get_child(selected_piece).button_pressed: 
		selected_piece = GlobalNames.PIECE_TYPE.NONE

func grab_piece() -> void:
	print("Grabbing")
	var closest_tile := board.get_closest_tile(get_local_mouse_position())
	if closest_tile == Vector2i.MAX: return

	for piece in pieces.get_children():
		if piece.position_on_board == closest_tile:
			piece_buttons.get_child(piece.piece_type).available += 1
			available += 1
			# piece_buttons.get_child(piece.piece_type).button_pressed = true
			selected_piece = piece.piece_type
			floating_preview.texture = GlobalNames.piece_textures[selected_piece]
			transparent_review.texture = GlobalNames.piece_textures[selected_piece]
			floating_preview.visible = true
			transparent_review.visible = true


			piece.queue_free()

			break

func reset_board() -> void:
	for piece in pieces.get_children():
		piece.queue_free()
	
	for button in piece_buttons.get_children():
		button.available = button.max_available
	
	available = GlobalNames.NR_PIECES

func randomize_board() -> void:
	reset_board()

	var tiles: Array[Vector2i]
	for i in GlobalNames.BOARD_SIZE:
		tiles.push_back(Vector2i(i, 0))
		tiles.push_back(Vector2i(i, 1))
	
	var piece_types: Array[GlobalNames.PIECE_TYPE]
	for b in piece_buttons.get_children():
		var button: PieceSelectorButton = b 
		for i in button.available:
			piece_types.push_back(button.piece_type)
	
	for i in GlobalNames.NR_PIECES:
		var tile: Vector2i = tiles.pick_random()
		tiles.erase(tile)

		var type: GlobalNames.PIECE_TYPE = piece_types.pick_random()
		piece_types.erase(type)

		var piece: Piece = piece_scene.instantiate()
		pieces.add_child(piece)
		# piece.position_on_board = tile
		# piece.global_position = board.index_to_position(tile)
		piece.set_position_on_board_no_anim(tile, board)
		piece.piece_type = type
		piece_buttons.get_child(type).available -= 1
	
	# transparent_review.visible = false
	selected_piece = GlobalNames.PIECE_TYPE.NONE


	available = 0


func player_ready() -> void:
	get_tree().change_scene_to_file("res://GameScene.tscn")
	
	Network.send_inital_setup_packet(pieces)


	# Network.receive_packet()