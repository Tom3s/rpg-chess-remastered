extends Node2D
class_name PlayerSelect

@onready var playerIdLabel: Label = %PlayerIdLabel
@onready var playerNameEdit: LineEdit = %PlayerNameEdit
@onready var playerColorPicker: ColorPickerButton = %PlayerColorPicker
@onready var joinButton: Button = %JoinButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	playerIdLabel.text = "Session ID: " + str(Network.main_player.id)

	playerColorPicker.color = Network.main_player.color

	playerNameEdit.text_changed.connect(func(text: String) -> void:
		Network.main_player.name = text
	)

	playerColorPicker.color_changed.connect(func(color: Color) -> void:
		Network.main_player.color = color
	)

	joinButton.pressed.connect(connect_with_handshake)

	# print("should print after global scripts")

func connect_with_handshake() -> void:
	var error := Network.connect_to_server()

	if error != OK:
		print("[PlayerSelect.gd] Aborted connection")
		return
	
	Network.send_player_join_packet()

	get_tree().change_scene_to_file("res://SetupBuilder.tscn")

