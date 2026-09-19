extends Control

const PLAYER_SLOT_SCENE = preload("res://Scenes/UI/player_slot.tscn")

@export_file("*.tscn") var main_menu_scene_path: String = "res://Scenes/UI/main_menu.tscn"

# Configuração de cores dos 6 slots
const PLAYER_CONFIGS = [
	{"name": "AMARELO", "color": Color("#E6B843")},
	{"name": "AZUL", "color": Color("#4A90E2")},
	{"name": "ROXO", "color": Color("#9013FE")},
	{"name": "VERDE", "color": Color("#7ED321")},
	{"name": "VERMELHO", "color": Color("#D0021B")},
	{"name": "PRETO", "color": Color("#4A4A4A")}
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
	_instantiate_player_slots()

func _instantiate_player_slots() -> void:
	for i in range(PLAYER_CONFIGS.size()):
		var slot: PlayerSlot = PLAYER_SLOT_SCENE.instantiate()
		slot.slot_color = PLAYER_CONFIGS[i]["color"]
		slot.default_name = PLAYER_CONFIGS[i]["name"]
		players_grid.add_child(slot)
		slots.append(slot)
		
		# Define os dois primeiros como Ativos por padrão (Humano vs IA)
		if i == 0:
			slot.set_mode(PlayerSlot.SlotMode.HUMAN)
		elif i == 1:
			slot.set_mode(PlayerSlot.SlotMode.AI)
		else:
			slot.set_mode(PlayerSlot.SlotMode.DISABLED)

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
	# Futuro: Carregar a cena do Tabuleiro do Carcassonne passando `match_config`

func _on_back_pressed() -> void:
	if ResourceLoader.exists(main_menu_scene_path):
		get_tree().change_scene_to_file(main_menu_scene_path)
