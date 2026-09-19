extends Control

# Caminhos para as telas secundárias
@export_file("*.tscn") var match_setup_scene_path: String = "res://Scenes/UI/match_setup.tscn"
@export_file("*.tscn") var options_scene_path: String = "res://Scenes/UI/options_menu.tscn"
@export_file("*.tscn") var credits_scene_path: String = "res://Scenes/UI/credits.tscn"

# Referências aos nós
@onready var btn_play: Button = %BtnPlay
@onready var btn_rules: Button = %BtnRules
@onready var btn_options: Button = %BtnOptions
@onready var btn_credits: Button = %BtnCredits
@onready var btn_quit: Button = %BtnQuit



func _connect_signals() -> void:
	btn_play.pressed.connect(_on_play_pressed)
	btn_rules.pressed.connect(_on_rules_pressed)
	btn_options.pressed.connect(_on_options_pressed)
	btn_credits.pressed.connect(_on_credits_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	if ResourceLoader.exists(match_setup_scene_path):
		get_tree().change_scene_to_file(match_setup_scene_path)
	else:
		print("Mudança de cena: Indo para Configuração da Partida ")

func _on_rules_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/rules_screen.tscn")
func _ready() -> void:
	_connect_signals()
	
func _on_options_pressed() -> void:
	if ResourceLoader.exists(options_scene_path):
		get_tree().change_scene_to_file(options_scene_path)
	else:
		print("Mudança de cena: Indo para Opções ")

func _on_credits_pressed() -> void:
	if ResourceLoader.exists(credits_scene_path):
		get_tree().change_scene_to_file(credits_scene_path)
	else:
		print("Mudança de cena: Indo para Créditos")

func _on_quit_pressed() -> void:
	get_tree().quit()