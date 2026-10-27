extends Node

## Gerencia estados globais (ex: Modo Daltônico) e orquestra a inicialização das partidas integrando com o domínio.

# ---------------------------------------------------------------------------
# SINAIS GLOBAIS
# ---------------------------------------------------------------------------
signal colorblind_mode_changed(enabled: bool)
signal match_started()
signal turn_changed(current_player: Player)
signal match_ended(final_scores: Dictionary)

# ---------------------------------------------------------------------------
# ESTADO GLOBAL DA APLICAÇÃO
# ---------------------------------------------------------------------------
var colorblind_mode: bool = false:
	set(value):
		if colorblind_mode != value:
			colorblind_mode = value
			colorblind_mode_changed.emit(value)

# ---------------------------------------------------------------------------
# ESTADO E REFERÊNCIAS DA PARTIDA ATIVA
# ---------------------------------------------------------------------------
var active_config: MatchConfig = null
var active_logic: LogicInstance = null


# ---------------------------------------------------------------------------
# CONFIGURAÇÃO E INICIALIZAÇÃO DA PARTIDA
# ---------------------------------------------------------------------------

## Configura a partida a partir de um DTO MatchConfig ou de um Dicionário de UI
func setup_match(config_input: Variant) -> void:
	# 1. Normaliza a entrada para o DTO MatchConfig
	if config_input is MatchConfig:
		active_config = config_input
	elif config_input is Dictionary:
		active_config = _parse_dictionary_to_match_config(config_input)
	else:
		push_error("[GameManager] Formato de configuração inválido fornecido para setup_match!")
		return

	if not active_config.is_valid():
		push_error("[GameManager] Configuração de partida inválida.")
		return

	# 2. Fabrica os jogadores concretos (Player / AIPlayer) via GoF Factory
	var players: Array[Player] = PlayerFactory.create_players(active_config)

	# 3. Instancia o orquestrador do domínio (LogicInstance)
	active_logic = LogicInstance.new(
		players,
		active_config.initial_card_id,
		active_config.total_tiles,
		active_config.turn_time_limit
	)

	# 4. Conecta os sinais de evento do domínio para sinalizar a UI da Aplicação
	active_logic.turn_passed.connect(_on_domain_turn_passed)
	active_logic.game_finished.connect(_on_domain_game_finished)

	print("[GameManager] Partida configurada com sucesso com %d jogadores." % players.size())


## Dispara o início efetivo do loop de jogo
func start_match() -> void:
	if active_logic == null:
		push_error("[GameManager] Erro: Tentativa de iniciar partida sem configuração previa!")
		return

	print("\n==========================================")
	print("          --- PARTIDA INICIADA ---        ")
	print("==========================================")
	for p in active_logic.players:
		print("Jogador [%s] | ID: %s | Meeples: %d | Cor: %s" % [
			p.player_name, p.id, p.available_meeples, p.color
		])
	print("==========================================\n")

	match_started.emit()
	
	# Inicia o fluxo de jogo na LogicInstance (que acionará o primeiro turno)
	active_logic.start_game()


# ---------------------------------------------------------------------------
# CONSULTAS DE ESTADO
# ---------------------------------------------------------------------------

## Retorna o jogador do turno atual consultando a máquina de estados do domínio
func get_current_player() -> Player:
	if active_logic and active_logic._state_machine:
		return active_logic._state_machine.get_current_player()
	return null


## Retorna se há uma partida ativa em execução
func is_match_in_progress() -> bool:
	return active_logic != null


# ---------------------------------------------------------------------------
# TRATAMENTO DE EVENTOS DO DOMÍNIO
# ---------------------------------------------------------------------------

func _on_domain_turn_passed(player: Player, _card_id: int, _valid_positions: Dictionary) -> void:
	print("------------------------------------------")
	print(">>> [RF9] VEZ ATUAL: %s (ID: %s) <<<" % [player.player_name, player.id])
	print("------------------------------------------")
	turn_changed.emit(player)


func _on_domain_game_finished(final_scores: Dictionary) -> void:
	print("==========================================")
	print("          --- PARTIDA FINALIZADA ---      ")
	print("==========================================")
	print("Placar Final: ", final_scores)
	match_ended.emit(final_scores)


# ---------------------------------------------------------------------------
# CONVERSOR AUXILIAR DE COMPATIBILIDADE (Dictionary -> MatchConfig)
# ---------------------------------------------------------------------------

func _parse_dictionary_to_match_config(dict: Dictionary) -> MatchConfig:
	var config := MatchConfig.new()
	var raw_players: Array = dict.get("players", [])

	for i in range(raw_players.size()):
		var p_info: Dictionary = raw_players[i]
		var p_id: String = str(i + 1)
		var p_name: String = p_info.get("name", "Jogador %s" % p_id)
		var p_color: Color = p_info.get("color", Color.WHITE)
		var is_ai: bool = p_info.get("is_ai", false)
		
		var ai_diff: PlayerData.Difficulty = PlayerData.Difficulty.BASIC
		if is_ai and p_info.has("ai_difficulty"):
			ai_diff = p_info["ai_difficulty"]

		var player_data := PlayerData.new(p_id, p_name, p_color, is_ai, ai_diff)
		config.add_player_data(player_data)

	if dict.has("total_tiles"):
		config.total_tiles = dict["total_tiles"]
	if dict.has("turn_time"):
		config.turn_time_limit = dict["turn_time"]
	elif dict.has("turn_time_limit"):
		config.turn_time_limit = dict["turn_time_limit"]

	return config
