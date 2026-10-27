extends CanvasLayer

const TEMP_MESSAGE : PackedScene = preload("uid://chjj24d7oiu5b")

@onready var v_box_container = $HBoxContainer/VBoxContainer

func error(text : String) -> void:
	_add_message(TempMessage.TEMP_MESSAGE_TYPE.ERROR, text)
	
func warning(text : String) -> void:
	_add_message(TempMessage.TEMP_MESSAGE_TYPE.WARNING, text)
	
func sucess(text : String) -> void:
	_add_message(TempMessage.TEMP_MESSAGE_TYPE.SUCESS, text)

func _add_message(type : TempMessage.TEMP_MESSAGE_TYPE, text : String) -> void:
	var message : TempMessage = TEMP_MESSAGE.instantiate()
	v_box_container.add_child(message)
	message.configure(type, text)
	
	
