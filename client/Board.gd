@tool
extends Node2D

class_name Board
const GRID_SIZE = 128
const BORDER_SIZE = 48

@export
var width: int = 9:
	set(newWidth): 
		width = newWidth
		offsetX = -width * GRID_SIZE / 2
		queue_redraw()

@export
var height: int = 9:
	set(newHeight): 
		height = newHeight
		offsetY = -height * GRID_SIZE / 2
		queue_redraw()

@export
var darkColor: Color = Color.DARK_CYAN:
	set(newColor):
		darkColor = newColor
		queue_redraw()
@export
var lightColor: Color = Color.LIGHT_SKY_BLUE:
	set(newColor):
		lightColor = newColor
		queue_redraw()

@export
var borderColor: Color = Color.BLACK:
	set(newColor):
		borderColor = newColor
		queue_redraw()

@export
var showTop: bool = true:
	set(top):
		showTop = top
		queue_redraw()

var offsetX: int = -width * GRID_SIZE / 2
var offsetY: int = -height * GRID_SIZE / 2

const padding = 5
var hoveringSquare: Vector2i = Vector2i(-1, -1)
var reachableTiles: Array[Vector2i] = []
var attackableTiles: Array[Vector2i] = []


func _draw() -> void:
	if showTop:
		draw_rect(
		Rect2(
			-BORDER_SIZE + offsetX, 
			-BORDER_SIZE + offsetY,
			width * GRID_SIZE + BORDER_SIZE * 2, 
			height * GRID_SIZE + BORDER_SIZE * 2
		), borderColor)
	else:
		draw_rect(
		Rect2(
			-BORDER_SIZE + offsetX, 
			offsetY,
			width * GRID_SIZE + BORDER_SIZE * 2, 
			height * GRID_SIZE + BORDER_SIZE
		), borderColor)


	for i in range(width):
		for j in range(height):
			var colorIndex := (i + j) % 2
			var currentColor := lightColor if colorIndex == 0 else darkColor
			var posX := i * GRID_SIZE + offsetX
			var posY := j * GRID_SIZE + offsetY
			
			draw_rect(Rect2(posX, posY, GRID_SIZE, GRID_SIZE), currentColor)
	
	
	for tile in reachableTiles:
		var posX := tile.x * GRID_SIZE + offsetX # + padding
		var posY := tile.y * GRID_SIZE + offsetY # + padding
		
		# draw_rect(Rect2(posX, posY, GRID_SIZE - padding*2, GRID_SIZE - padding*2), Color.DARK_OLIVE_GREEN, false, padding * 2)
		draw_rect(Rect2(posX, posY, GRID_SIZE, GRID_SIZE), Color(0.0, 0.8, 0.2, 0.5))
	
	
	for tile in attackableTiles:
		var posX := tile.x * GRID_SIZE + offsetX # + padding
		var posY := tile.y * GRID_SIZE + offsetY # + padding
		
		# draw_rect(Rect2(posX, posY, GRID_SIZE - padding*2, GRID_SIZE - padding*2), Color.DARK_OLIVE_GREEN, false, padding * 2)
		draw_rect(Rect2(posX, posY, GRID_SIZE, GRID_SIZE), Color(0.8, 0.1, 0.2, 0.5))
	
	if hoveringSquare != Vector2i(-1, -1):
		var posX := hoveringSquare.x * GRID_SIZE + offsetX + padding
		var posY := hoveringSquare.y * GRID_SIZE + offsetY + padding
		
		draw_rect(Rect2(posX, posY, GRID_SIZE - padding*2, GRID_SIZE - padding*2), Color.BLACK, false, padding * 2)
		

func isTilePositionValid(tilePos: Vector2i) -> bool:
	return tilePos.x >= 0 and tilePos.y >= 0 and tilePos.x < width and tilePos.y < height

func setHoveringSquare(pos: Vector2i) -> void:
	
	if isTilePositionValid(pos):
		hoveringSquare = pos
	else:
		hoveringSquare = Vector2i(-1, -1)
	
	queue_redraw()

func setReachableTiles(tiles: Array[Vector2i]) -> void:
	
	reachableTiles = tiles.filter(isTilePositionValid)
	queue_redraw()

func setAttackableTiles(tiles: Array[Vector2i]) -> void:
	
	attackableTiles = tiles.filter(isTilePositionValid)
	queue_redraw()

func clearInteractableTiles() -> void:
	reachableTiles.clear()
	attackableTiles.clear()
	queue_redraw()

func debugReachableTiles() -> String:
	return "Reachable tiles: " + str(reachableTiles)

func getClosestTile(pos: Vector2) -> Vector2i:
	pos -= Vector2(offsetX, offsetY)
	pos /= GRID_SIZE
	pos = pos.floor()
	if pos.x < 0 || pos.y < 0 || pos.x >= width || pos.y >= height:
		return Vector2i.MAX
	
	return pos

func indexToPosition(index: Vector2) -> Vector2:
	return index * GRID_SIZE + Vector2(offsetX, offsetY) + Vector2.ONE * GRID_SIZE / 2