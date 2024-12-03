extends Control
class_name QueenAbilityUI

@onready var accept_button: Button = %Accept
@onready var cancel_button: Button = %Cancel

signal confirmed_heal(confirmed: bool)

func _ready() -> void:
	accept_button.pressed.connect(func() -> void:
		visible = false
		confirmed_heal.emit(true)
	)
	
	cancel_button.pressed.connect(func() -> void:
		visible = false
		confirmed_heal.emit(false)
	)


