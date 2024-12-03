@tool
extends Node2D

@onready var board: Board = %Board

@export
var ref_tile: Vector2i = Vector2i(4, 4):
	set(val):
		ref_tile = val
		distance = distance

@export_range(0.0, 13, 0.1)
var distance: float = 1.0:
	set(val):
		var tiles: Array[Vector2i]
		for x in GlobalNames.BOARD_SIZE:
			for y in GlobalNames.BOARD_SIZE:
				if ref_tile.distance_to(Vector2i(x, y)) < val:
					tiles.push_back(Vector2i(x, y))
		
		board.set_reachable_tiles(tiles)
		distance = val

# Nice Values:
# 1.5
# 2.4
# 3.3
# 4.4
# 5.2
# 6.1
