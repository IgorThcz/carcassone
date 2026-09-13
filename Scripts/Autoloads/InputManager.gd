class_name InputManager extends Node # autoload

signal mouse_motion_event(event : InputEventMouseMotion)
signal mouse_button_event(event : InputEventMouseButton)

func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion_event.emit(event)
	elif event is InputEventMouseButton:
		mouse_button_event.emit(event)
