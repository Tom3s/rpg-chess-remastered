@tool
extends Node2D

class_name Board
const GRID_SIZE = 128
const BORDER_SIZE = 48

@export
var width: int = 9:
	set(new_width): 
		width = new_width
		offset_x = -width * GRID_SIZE / 2
		queue_redraw()

@export
var height: int = 9:
	set(new_height): 
		height = new_height
		offset_y = -height * GRID_SIZE / 2
		queue_redraw()

@export
var dark_color: Color = Color.DARK_CYAN:
	set(new_color):
		dark_color = new_color
		queue_redraw()
@export
var light_color: Color = Color.LIGHT_SKY_BLUE:
	set(new_color):
		light_color = new_color
		queue_redraw()

@export
var border_color: Color = Color.BLACK:
	set(new_color):
		border_color = new_color
		queue_redraw()

@export
var show_top: bool = true:
	set(top):
		show_top = top
		queue_redraw()

var offset_x: int = -width * GRID_SIZE / 2
var offset_y: int = -height * GRID_SIZE / 2

const padding = 5
var hovering_square: Vector2i = Vector2i.MAX
var reachable_tiles: Array[Vector2i] = []
var attackable_tiles: Array[Vector2i] = []

func _ready() -> void:
	Network.available_actions_received.connect(func(moves: Array[Vector2i], attacks: Array[Vector2i], _can_use_ability: bool) -> void:
		set_reachable_tiles(moves)
		set_attackable_tiles(attacks)
	)

func _draw() -> void:
	if show_top:
		draw_rect(
		Rect2(
			-BORDER_SIZE + offset_x, 
			-BORDER_SIZE + offset_y,
			width * GRID_SIZE + BORDER_SIZE * 2, 
			height * GRID_SIZE + BORDER_SIZE * 2
		), border_color)
	else:
		draw_rect(
		Rect2(
			-BORDER_SIZE + offset_x, 
			offset_y,
			width * GRID_SIZE + BORDER_SIZE * 2, 
			height * GRID_SIZE + BORDER_SIZE
		), border_color)


	for i in range(width):
		for j in range(height):
			var colorIndex := (i + j) % 2
			var currentColor := light_color if colorIndex == 0 else dark_color
			var posX := i * GRID_SIZE + offset_x
			var posY := j * GRID_SIZE + offset_y
			
			draw_rect(Rect2(posX, posY, GRID_SIZE, GRID_SIZE), currentColor)
	
	
	for tile in reachable_tiles:
		var posX := tile.x * GRID_SIZE + offset_x # + padding
		var posY := tile.y * GRID_SIZE + offset_y # + padding
		
		# draw_rect(Rect2(posX, posY, GRID_SIZE - padding*2, GRID_SIZE - padding*2), Color.DARK_OLIVE_GREEN, false, padding * 2)
		draw_rect(Rect2(posX, posY, GRID_SIZE, GRID_SIZE), Color(0.0, 0.8, 0.2, 0.5))
	
	
	for tile in attackable_tiles:
		var posX := tile.x * GRID_SIZE + offset_x # + padding
		var posY := tile.y * GRID_SIZE + offset_y # + padding
		
		# draw_rect(Rect2(posX, posY, GRID_SIZE - padding*2, GRID_SIZE - padding*2), Color.DARK_OLIVE_GREEN, false, padding * 2)
		draw_rect(Rect2(posX, posY, GRID_SIZE, GRID_SIZE), Color(0.8, 0.1, 0.2, 0.5))
	
	if hovering_square != Vector2i.MAX:
		var posX := hovering_square.x * GRID_SIZE + offset_x + padding
		var posY := hovering_square.y * GRID_SIZE + offset_y + padding
		
		draw_rect(Rect2(posX, posY, GRID_SIZE - padding*2, GRID_SIZE - padding*2), Color.BLACK, false, padding * 2)
		

func is_tile_position_valid(tilePos: Vector2i) -> bool:
	return tilePos.x >= 0 and tilePos.y >= 0 and tilePos.x < width and tilePos.y < height

func set_hovering_square(pos: Vector2i) -> void:
	
	if is_tile_position_valid(pos):
		hovering_square = pos
	else:
		hovering_square = Vector2i.MAX
	
	queue_redraw()

func set_reachable_tiles(tiles: Array[Vector2i]) -> void:
	
	reachable_tiles = tiles.filter(is_tile_position_valid)
	queue_redraw()

func set_attackable_tiles(tiles: Array[Vector2i]) -> void:
	
	attackable_tiles = tiles.filter(is_tile_position_valid)
	queue_redraw()

func clear_interactable_tiles() -> void:
	reachable_tiles.clear()
	attackable_tiles.clear()
	queue_redraw()

func get_closest_tile(pos: Vector2) -> Vector2i:
	pos -= Vector2(offset_x, offset_y)
	pos /= GRID_SIZE
	pos = pos.floor()
	if pos.x < 0 || pos.y < 0 || pos.x >= width || pos.y >= height:
		return Vector2i.MAX
	
	return pos

func index_to_position(index: Vector2) -> Vector2:
	return index * GRID_SIZE + Vector2(offset_x, offset_y) + Vector2.ONE * GRID_SIZE / 2