extends Control

const PLAYER_SLOT_SCENE = preload("res://Scenes/UI/player_slot.tscn")

@export_file("*.tscn") var main_menu_scene_path: String = "res://Scenes/UI/main_menu.tscn"

const PLAYER_NAMES = ["AMARELO", "AZUL", "ROXO", "VERDE", "VERMELHO", "PRETO"]

# Paleta Padrão
const PALETTE_STANDARD = [
	Color("#E6B843"), # AMARELO
	Color("#4A90E2"), # AZUL
	Color("#9013FE"), # ROXO
	Color("#7ED321"), # VERDE
	Color("#D0021B"), # VERMELHO
	Color("#4A4A4A")  # PRETO
]

# Paleta Modo Daltonico 
const PALETTE_COLORBLIND = [
	Color("#F0E442"), # AMARELO
	Color("#0072B2"), # AZUL
	Color("#CC79A7"), # ROXO (Púrpura)
	Color("#009E73"), # VERDE (Verde-Azulado)
	Color("#D55E00"), # VERMELHO (Vermilion)
	Color("#1A1A1A")  # PRETO (Mantém o preto com contraste perfeito)
]

@onready var spin_box_time: SpinBox = %SpinBoxTime
@onready var spin_box_tiles: SpinBox = %SpinBoxTiles
@onready var players_grid: GridContainer = %PlayersGrid
@onready var btn_back: Button = %BtnBack
@onready var btn_start: Button = %BtnStart

var slots: Array[PlayerSlot] = []

func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_start.pressed.connect(_on_start_pressed)
	
	# Pega alterações do modo daltônico, vindas do GameManager
	GameManager.colorblind_mode_changed.connect(_on_colorblind_mode_changed)
	
	_instantiate_player_slots()

func _instantiate_player_slots() -> void:
	var palette = _get_current_palette()
	
	for i in range(PLAYER_NAMES.size()):
		var slot: PlayerSlot = PLAYER_SLOT_SCENE.instantiate()
		slot.default_name = PLAYER_NAMES[i]
		slot.slot_color = palette[i]
		
		players_grid.add_child(slot)
		slots.append(slot)
		
		# Define os dois primeiros como Ativos por padrão (Humano vs IA)
		if i == 0:
			slot.set_mode(PlayerSlot.SlotMode.HUMAN)
		elif i == 1:
			slot.set_mode(PlayerSlot.SlotMode.AI)
		else:
			slot.set_mode(PlayerSlot.SlotMode.DISABLED)

func _get_current_palette() -> Array:
	return PALETTE_COLORBLIND if GameManager.colorblind_mode else PALETTE_STANDARD

func _on_colorblind_mode_changed(_enabled: bool) -> void:
	_update_slot_colors()

func _update_slot_colors() -> void:
	var palette = _get_current_palette()
	for i in range(slots.size()):
		if i < palette.size():
			slots[i].set_color(palette[i])

func _get_active_players_count() -> int:
	var active_count = 0
	for slot in slots:
		if slot.current_mode != PlayerSlot.SlotMode.DISABLED:
			active_count += 1
	return active_count

func _on_start_pressed() -> void:
	if _get_active_players_count() < 2:
		print("Erro: É necessário ter pelo menos 2 jogadores ativos (Humano ou CPU)!")
		return
		
	var match_config = {
		"turn_time": spin_box_time.value,
		"total_tiles": spin_box_tiles.value,
		"players": []
	}
	
	for slot in slots:
		if slot.current_mode != PlayerSlot.SlotMode.DISABLED:
			match_config["players"].append({
				"name": slot.default_name,
				"color": slot.slot_color,
				"is_ai": slot.current_mode == PlayerSlot.SlotMode.AI
			})
			
	print("Iniciando jogo com as configurações: ", match_config)

func _on_back_pressed() -> void:
	if ResourceLoader.exists(main_menu_scene_path):
		get_tree().change_scene_to_file(main_menu_scene_path)
