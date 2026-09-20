extends Control

@export_file("*.tscn") var main_menu_scene_path: String = "res://Scenes/UI/main_menu.tscn"

@onready var btn_back: Button = %BtnBack

func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	if ResourceLoader.exists(main_menu_scene_path):
		get_tree().change_scene_to_file(main_menu_scene_path)