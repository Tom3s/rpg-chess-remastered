extends Control
class_name TileSelectUI

var board: Board = null
var camera: Camera2D = null

signal tile_clicked(tile: Vector2i)

func _input(event: InputEvent) -> void:
	if board == null:
		return



	# var hovering_tile := board.get_closest_tile(get_local_mouse_position())
	var hovering_tile := board.get_closest_tile(camera.get_global_mouse_position())

	board.set_hovering_square(hovering_tile)

	if Input.is_action_just_pressed("left_click"):

		tile_clicked.emit(hovering_tile)

		visible = false