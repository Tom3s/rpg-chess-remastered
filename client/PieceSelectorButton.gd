@tool
extends Button
class_name PieceSelectorButton

@export
var pieceType: GlobalNames.PIECE_TYPE = GlobalNames.PIECE_TYPE.NONE:
	set(newType):
		setText()
		pieceType = newType

@export
var available: int = 1:
	set(newAvailable):
		disabled = newAvailable <= 0
		if disabled: button_pressed = false
		available = newAvailable
		setText()

var maxAvailable: int = available


func _ready() -> void:
	icon = GlobalNames.pieceTextures[pieceType]
	maxAvailable = available
	setText()


func setText() -> void:
	text = GlobalNames.PIECE_TYPE.keys()[pieceType].capitalize() + ": " + str(available) + "/" + str(maxAvailable)
	

