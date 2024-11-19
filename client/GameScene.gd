extends Node2D
class_name GameScene

@onready var piece_scene: PackedScene = preload("res://Piece.tscn")

@onready var board: Board = %Board
@onready var p1_pieces: Node2D = %P1Pieces
@onready var p2_pieces: Node2D = %P2Pieces
@onready var current_throw_label: Label = %CurrentThrowLabel
@onready var ability_button: Button = %AbilityButton

# ability UIs
@onready var pawn_ability_ui: PawnAbilityUI = %PawnAbilityUI

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
	# initialize_board()

	ability_button.disabled = true

	ability_button.pressed.connect(use_ability)
	# ability_button.mouse_entered.connect(func() -> void:
	# 	mouse_over_button = true
	# )
	# ability_button.mouse_exited.connect(func() -> void:
	# 	mouse_over_button = false
	# )

	Network.initial_board_state_received.connect(initialize_board)

	Network.available_actions_received.connect(func(moves: Array[Vector2i], attacks: Array[Vector2i], can_use_ability: bool) -> void:
		available_moves = moves
		available_attacks = attacks
		ability_button.disabled = !can_use_ability
	)

	Network.piece_moved.connect(move_piece)
	Network.piece_attacked.connect(resolve_attack)
	Network.round_started.connect(start_round)

	Network.ability_used.connect(resolve_used_ability)


func _process(_delta: float) -> void:
	if !is_current_player():
		board.set_hovering_square(Vector2i.MAX)
		return


func _unhandled_input(event: InputEvent) -> void:
	var hovering_tile := board.get_closest_tile(get_local_mouse_position())
	board.set_hovering_square(hovering_tile)

	if Input.is_action_just_pressed("left_click"):
		print("[GameScene] Clicked on tile ", hovering_tile)
		if board_data.get_tile(hovering_tile) != null:
			# tile is occupied
			var piece_on_tile := board_data.get_tile(hovering_tile)

			if piece_on_tile.owner_player != Network.main_player.id:
				# enemy piece on tile
				board.clear_interactable_tiles()
				if selected_piece != null && available_attacks.has(hovering_tile):
					# attack if possible
					Network.send_attack_packet(selected_piece.id, hovering_tile)
			else:
				# friendly piece on tile
				selected_piece = piece_on_tile
				Network.request_available_moves(selected_piece.id)
			# selected_piece = board_data.get_tile(hovering_tile)
		else:
			# tile is empty
			if selected_piece != null:
				if available_moves.has(hovering_tile):
					# move currently selected piece if possible
					Network.send_move_piece_packet(selected_piece.id, hovering_tile)
			
			selected_piece = null
			board.clear_interactable_tiles()


func initialize_board(state: Array) -> void:
	# if GlobalNames.initial_board_data.size() == 0:
	# 	assert(false, "[GameScene.gd] Board data is empty; Exiting...")
	
	var p1_piece_data: Array[Piece] = state[0]
	
	var index: int = 0
	for p in p1_piece_data:
		var piece: Piece = piece_scene.instantiate()
		p1_pieces.add_child(piece)
		# piece.piece_type = p.piece_type
		# piece.set_position_on_board(p.position_on_board, board)
		# piece.id = index
		# piece.owner_player = p.owner_player
		piece.init_piece(
			p.piece_type,
			p.position_on_board,
			board,
			index,
			p.owner_player
		)
		board_data.set_tile(piece.position_on_board, piece)
		index += 1
	
	var p2_piece_data: Array[Piece] = state[1]
	
	index = 0
	for p in p2_piece_data:
		var piece: Piece = piece_scene.instantiate()
		p2_pieces.add_child(piece)
		# piece.piece_type = p.piece_type
		# piece.set_position_on_board(p.position_on_board, board)
		# piece.id = index
		# piece.owner_player = p.owner_player
		piece.init_piece(
			p.piece_type,
			p.position_on_board,
			board,
			index,
			p.owner_player
		)
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

	selected_piece = null

func resolve_attack(player_id: int, piece_id: int, target_piece_id: int, new_hp: int, landing_tile: Vector2i) -> void:
	var piece_parent: Node2D = null
	var target_piece_parent: Node2D = null

	if player_id == Network.p1_id:
		piece_parent = p1_pieces
		target_piece_parent = p2_pieces
	else:
		piece_parent = p2_pieces
		target_piece_parent = p1_pieces

	var attacking_piece: Piece = piece_parent.get_child(piece_id)
	var target_piece: Piece = target_piece_parent.get_child(target_piece_id)

	board_data.set_tile(attacking_piece.position_on_board, null)
	attacking_piece.set_position_on_board(landing_tile, board)

	board_data.set_tile(attacking_piece.position_on_board, attacking_piece)

	target_piece.set_hp(new_hp)

	selected_piece = null

func start_round(player: int, throw: int) -> void:
	current_player = player
	current_throw = throw

	current_throw_label.text = "Current Throw: " + str(throw)

	board.clear_interactable_tiles()

func is_current_player() -> bool:
	var current_player_id := Network.p1_id
	if current_player == 1:
		current_player_id = Network.p2_id
	
	return Network.main_player.id == current_player_id

func use_ability() -> void:
	if selected_piece == null:
		# failsafe
		ability_button.disabled = true
		return

	print("[GameScene.gd] ", selected_piece, "wants to use ability") 

	match selected_piece.piece_type:
		GlobalNames.PIECE_TYPE.PAWN:
			var vals := {"type": GlobalNames.PIECE_TYPE.NONE}
			pawn_ability_ui.piece_type_selected.connect(func(type: GlobalNames.PIECE_TYPE) -> void:
				vals.type = type
			)
			pawn_ability_ui.visible = true

			await pawn_ability_ui.piece_type_selected
			print("[GameScene.gd] Ability use sequence over; Selected: ", GlobalNames.PIECE_TYPE.keys()[vals.type])

			Network.send_use_ability_packet(
				selected_piece,
				{
					"selected_type": vals.type
				}
			)

		GlobalNames.PIECE_TYPE.ROOK:
			pass
		GlobalNames.PIECE_TYPE.BISHOP:
			pass
		GlobalNames.PIECE_TYPE.KNIGHT:
			pass
		GlobalNames.PIECE_TYPE.QUEEN:
			pass

func resolve_used_ability(player_id: int, piece_id: int, ability_data: Dictionary) -> void:
	var piece_parent: Node2D = null

	if player_id == Network.p1_id:
		piece_parent = p1_pieces
	else:
		piece_parent = p2_pieces

	var piece: Piece = piece_parent.get_child(piece_id)

	match piece.piece_type:
		GlobalNames.PIECE_TYPE.PAWN:
			piece.piece_type = ability_data.new_type
			piece.damage = ability_data.new_dmg
		_:
			pass