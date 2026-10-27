extends Node3D

enum MPCONFIG { HOST, CLIENT, LOCAL }

var logicinstance  : LogicInstance
var visualinstance : VisualInstance

func _ready() -> void:
	# 2. Recupera a partida configurada no GameManager ou gera uma partida padrão de depuração 
	if GameManager.active_logic == null:
		print("[Game] Nenhuma partida ativa no GameManager. Inicializando partida de teste...")
		_create_default_match()

	logicinstance = GameManager.active_logic

	if logicinstance == null:
		push_error("[Game] Erro: Não foi possível obter a LogicInstance do GameManager!")
		return

	var view_mode : VisualInstance.VIEW_MODE
	view_mode = GameManager.active_config.view_mode
	visualinstance = VisualInstance.new(logicinstance.players, view_mode)
	add_child(visualinstance)

	# 4. Inicia a partida no orquestrador global
	GameManager.start_match()


## Cria uma configuração de teste via GameManager caso a cena seja executada isoladamente 
func _create_default_match() -> void:
	var config := MatchConfig.new()
	config.turn_time_limit = 60
	config.total_tiles = 72

	config.add_player_data(PlayerData.new("1", "Player 1", Color.BLUE, false))
	config.add_player_data(PlayerData.new("2", "Player 2", Color.RED, false))

	GameManager.setup_match(config)


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_P) and logicinstance:
		print("[Game Debug] Estado do Tabuleiro: ", logicinstance._board)
