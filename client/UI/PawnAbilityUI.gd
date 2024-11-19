extends Control
class_name PawnAbilityUI

@onready var buttonContainer: VBoxContainer = %ButtonContainer

signal piece_type_selected(type: GlobalNames.PIECE_TYPE)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# var types: Array[String] = GlobalNames.PIECE_TYPE.keys()

	for i in GlobalNames.PIECE_TYPE.size() - 1:
		var button: Button = Button.new()

		button.text = GlobalNames.PIECE_TYPE.keys()[i].capitalize()
		button.focus_mode = Control.FOCUS_NONE

		button.pressed.connect(func() -> void:
			visible = false

			piece_type_selected.emit(i as GlobalNames.PIECE_TYPE)	

			print(GlobalNames.PIECE_TYPE.keys()[i])
		)

		buttonContainer.add_child(button)






# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
