@tool
extends Button
class_name PieceSelectorButton

@export
var piece_type: GlobalNames.PIECE_TYPE = GlobalNames.PIECE_TYPE.NONE:
	set(new_type):
		setText()
		piece_type = new_type

@export
var available: int = 1:
	set(new_available):
		disabled = new_available <= 0
		if disabled: button_pressed = false
		available = new_available
		setText()

var max_available: int = available


func _ready() -> void:
	icon = GlobalNames.piece_textures[piece_type]
	max_available = available
	setText()


func setText() -> void:
	text = GlobalNames.PIECE_TYPE.keys()[piece_type].capitalize() + ": " + str(available) + "/" + str(max_available)
	

