extends Control

@export_file("*.tscn") var main_menu_scene_path: String = "res://Scenes/UI/main_menu.tscn"

# Referências aos controles visuais
@onready var slider_music: HSlider = %SliderMusic
@onready var slider_sfx: HSlider = %SliderSFX
@onready var check_mute: CheckButton = %CheckMute
@onready var check_colorblind: CheckButton = %CheckColorblind
@onready var check_fullscreen: CheckButton = %CheckFullscreen
@onready var btn_back: Button = %BtnBack

func _ready() -> void:
	_connect_signals()
	_load_current_settings()

func _connect_signals() -> void:
	slider_music.value_changed.connect(_on_music_volume_changed)
	slider_sfx.value_changed.connect(_on_sfx_volume_changed)
	check_mute.toggled.connect(_on_mute_toggled)
	check_colorblind.toggled.connect(_on_colorblind_toggled)
	check_fullscreen.toggled.connect(_on_fullscreen_toggled)
	btn_back.pressed.connect(_on_back_pressed)

func _load_current_settings() -> void:
	# Sincroniza o checkbox com o estado atual da janela
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	check_fullscreen.button_pressed = is_fullscreen
	check_colorblind.button_pressed = GameManager.colorblind_mode

func _on_music_volume_changed(value: float) -> void:
	print("Volume da Música alterado para: ", value, "%")
	# Integração futura 

func _on_sfx_volume_changed(value: float) -> void:
	print("Volume dos Efeitos Sonoros alterado para: ", value, "%")
	# TBD

func _on_mute_toggled(toggled_on: bool) -> void:
	print("Estado Mute: ", toggled_on)
	# TBD

func _on_colorblind_toggled(toggled_on: bool) -> void:
	GameManager.colorblind_mode = toggled_on

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_pressed() -> void:
	if ResourceLoader.exists(main_menu_scene_path):
		get_tree().change_scene_to_file(main_menu_scene_path)
	else:
		print("Voltando para o Menu Principal")
