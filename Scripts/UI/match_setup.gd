extends Control

const GAME_SCENE : PackedScene = preload("uid://b5f6t1kuj1137")
const PLAYER_SLOT_SCENE = preload("res://Scenes/UI/player_slot.tscn")

@export_file("*.tscn") var main_menu_scene_path: String = "res://Scenes/UI/main_menu.tscn"
@export_file("*.tscn") var game_scene_path: String = "res://Tests/test_runner.tscn"

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

# Paleta Modo Daltônico (Okabe-Ito)
const PALETTE_COLORBLIND = [
	Color("#F0E442"), # AMARELO
	Color("#0072B2"), # AZUL
	Color("#CC79A7"), # ROXO 
	Color("#009E73"), # VERDE 
	Color("#D55E00"), # VERMELHO 
	Color("#1A1A1A")  # PRETO 
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
	
	# Sincroniza cores com o modo daltônico do GameManager
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
	var active_count = _get_active_players_count()
	
	# Validação de Regra de Negócio 
	if active_count < 2:
		print("[MatchSetup] Erro: É necessário ter pelo menos 2 jogadores ativos!")
		return
		
	if active_count > 5:
		print("[MatchSetup] Erro: O número máximo de jogadores permitidos é 5!")
		return
		
	# 1. Cria o DTO de Configuração da Partida 
	var config := MatchConfig.new()
	config.turn_time_limit = int(spin_box_time.value)
	config.total_tiles = int(spin_box_tiles.value)

	# 2. Converte os slots visuais em DTOs PlayerData
	for i in range(slots.size()):
		var slot: PlayerSlot = slots[i]
		if slot.current_mode != PlayerSlot.SlotMode.DISABLED:
			var player_id: String = str(i + 1)
			var is_ai: bool = (slot.current_mode == PlayerSlot.SlotMode.AI)
			
			# Lê nome personalizado caso exista no slot, senão usa default_name
			var player_name_val: String = slot.default_name
			if "player_name" in slot and not str(slot.player_name).is_empty():
				player_name_val = str(slot.player_name)

			# Lê a dificuldade da IA configurada
			var ai_diff: PlayerData.Difficulty = PlayerData.Difficulty.BASIC
			if is_ai and "ai_difficulty" in slot:
				ai_diff = slot.ai_difficulty

			var p_data := PlayerData.new(
				player_id,
				player_name_val,
				slot.slot_color,
				is_ai,
				ai_diff
			)
			
			if config.has_method("add_player_data"):
				config.add_player_data(p_data)
			else:
				config.players_data.append(p_data)
			
	print("[MatchSetup] Configuração gerada e enviada para o GameManager.")
	
	# 3. Inicializa o jogo no GameManager
	GameManager.setup_match(config)
	get_tree().change_scene_to_packed(GAME_SCENE)
	return
	
	# 4. Instancia o TestRunner e executa os testes com a configuração enviada
	if ResourceLoader.exists(game_scene_path):
		var test_runner_scene: PackedScene = load(game_scene_path)
		var test_runner_instance = test_runner_scene.instantiate()
		
		get_tree().root.add_child(test_runner_instance)
		
		if test_runner_instance.has_method("run_suite_with_config"):
			test_runner_instance.run_suite_with_config(config)
		
		queue_free()
	else:
		print("[MatchSetup] Aviso: Caminho da cena não encontrado: ", game_scene_path)


func _on_back_pressed() -> void:
	if ResourceLoader.exists(main_menu_scene_path):
		get_tree().change_scene_to_file(main_menu_scene_path)
