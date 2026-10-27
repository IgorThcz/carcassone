extends Node

## Executa a bateria de testes do domínio do Carcassonne exclusivamente via Terminal,
## acionada obrigatoriamente a partir dos dados configurados no MatchupSetup.

var _total_assertions: int = 0
var _passed_assertions: int = 0
var _failed_assertions: int = 0

var _is_running_dynamic_suite: bool = false


func _ready() -> void:
	# Aguarda um frame para confirmar se o MatchupSetup chamou run_suite_with_config()
	await get_tree().process_frame
	if not _is_running_dynamic_suite:
		print_rich("[bold][color=red]✘ [ERRO] TestRunner deve ser executado exclusivamente através do MatchupSetup enviando os dados de configuração.[/color][/bold]")
		get_tree().quit()


## Ponto de entrada público invocado obrigatoriamente pelo MatchupSetup
func run_suite_with_config(config: MatchConfig) -> void:
	if config == null or config.players_data.is_empty():
		push_error("[TestRunner] Configurações de partida inválidas ou sem jogadores.")
		get_tree().quit()
		return

	_is_running_dynamic_suite = true
	_total_assertions = 0
	_passed_assertions = 0
	_failed_assertions = 0

	print_rich("\n[bold][color=cyan]==================================================[/color][/bold]")
	print_rich("[bold][color=cyan]       INICIANDO BATERIA DE TESTES DO DOMÍNIO      [/color][/bold]")
	print_rich("[bold][color=cyan]==================================================[/color][/bold]\n")

	# -----------------------------------------------------------------------
	# FASE 1: SUÍTE DE TESTES UNITÁRIOS DE REGRA PURA
	# -----------------------------------------------------------------------
	print_rich("[bold][color=yellow]--- FASE 1: TESTES UNITÁRIOS E REGRAS DE DOMÍNIO ---[/color][/bold]\n")

	_run_test_wrapper("TEST 1: Validação de Meeples e Grafos", _run_test_1)
	_run_test_wrapper("TEST 2: PlayerFactory e Injeção", _run_test_2)
	_run_test_wrapper("TEST 3: Tomada de Decisão da IA", _run_test_3)
	_run_test_wrapper("TEST 4: Integração da LogicInstance", _run_test_4)
	_run_test_wrapper("TEST 5: Ciclo de Vida do Turno (TurnStateMachine)", _run_test_5)
	_run_test_wrapper("TEST 6: Validação de Tabuleiro, Rotações e Fronteiras", _run_test_6)
	_run_test_wrapper("TEST 7: Sistema de Descarte Automático (Deck + LogicInstance)", _run_test_7)
	_run_test_wrapper("TEST 8: Fechamento de Estruturas, Multiplicadores e Maioria", _run_test_8)
	_run_test_wrapper("TEST 9: Encerramento de Partida e Pontuação Residual Final", _run_test_9)
	_run_test_wrapper("TEST 10: Validação e Carregamento do Catálogo (Catalogue & Deck)", _run_test_10)

	# -----------------------------------------------------------------------
	# FASE 2: SIMULAÇÃO DINÂMICA COM OS DADOS DO MATCHUP SETUP
	# -----------------------------------------------------------------------
	await _run_phase_2_dynamic_simulation(config)

	_print_final_summary()

	await get_tree().process_frame
	get_tree().quit()


# ---------------------------------------------------------------------------
# FASE 2: SIMULAÇÃO DINÂMICA DE PARTIDA COM DADOS REAIS
# ---------------------------------------------------------------------------

func _run_phase_2_dynamic_simulation(config: MatchConfig) -> void:
	print_rich("[bold][color=yellow]--- FASE 2: SIMULAÇÃO DINÂMICA DE PARTIDA (MATCHUP SETUP) ---[/color][/bold]\n")

	var sim_players: Array[Player] = _convert_config_players_to_ai(config)
	
	var deck_size: int = 72
	if "deck_size" in config:
		deck_size = config.deck_size
	elif "target_deck_size" in config:
		deck_size = config.target_deck_size
	elif "total_tiles" in config:
		deck_size = config.total_tiles

	var time_limit: int = 60
	if "turn_time_limit" in config:
		time_limit = config.turn_time_limit

	print_rich("[bold]Parâmetros Recebidos do MatchupSetup:[/bold]")
	print_rich("  • Total de Jogadores: %d" % sim_players.size())
	for p in sim_players:
		print_rich("    - [%s] %s (Cor: %s)" % [p.id, p.player_name, p.color])
	print_rich("  • Tamanho do Baralho: %d peças" % deck_size)
	print_rich("  • Limite de Tempo por Turno: %ds" % time_limit)
	print("")

	var logic := LogicInstance.new(sim_players, 1, deck_size, time_limit)
	GameManager.active_logic = logic

	var simulation_data := {
		"completed": false,
		"final_scores": {},
		"cards_placed": 0,
		"cards_discarded": 0
	}

	logic.game_finished.connect(func(scores: Dictionary):
		simulation_data.completed = true
		simulation_data.final_scores = scores
	)

	logic.card_placed.connect(func(_p, _coords, _rot, _slots, _id):
		simulation_data.cards_placed += 1
	)

	logic.card_discarded.connect(func(_id):
		simulation_data.cards_discarded += 1
	)

	logic.start_game()

	var safety_counter: int = 0
	var max_safety_frames: int = 20000

	while not simulation_data.completed and safety_counter < max_safety_frames:
		safety_counter += 1
		await get_tree().process_frame

	_assert(simulation_data.completed == true, "Partida simulada até o encerramento sem travamentos")
	
	var total_processed: int = simulation_data.cards_placed + simulation_data.cards_discarded
	var expected_total: int = deck_size

	_assert(total_processed == expected_total, 
		"Regra Oficial: Todas as %d peças da partida foram processadas (%d jogadas, %d descartadas)" % [
			expected_total, simulation_data.cards_placed, simulation_data.cards_discarded
		]
	)

	if simulation_data.completed:
		print_rich("\n[bold][color=green]Placar Final da Simulação Dinâmica:[/color][/bold]")
		for player in simulation_data.final_scores.keys():
			var score_val: int = simulation_data.final_scores[player]
			print_rich("  • %s (ID: %s): %d pontos" % [player.player_name, player.id, score_val])
	
	_teardown()
	print("")


func _convert_config_players_to_ai(config: MatchConfig) -> Array[Player]:
	var converted_players: Array[Player] = []
	var raw_data_list: Array = config.players_data if "players_data" in config else []

	for data in raw_data_list:
		var target_data: PlayerData = data
		if not data.is_ai:
			target_data = PlayerData.new(
				data.id,
				data.name,
				data.color,
				true,
				PlayerData.Difficulty.BASIC
			)
		var player_obj: Player = PlayerFactory.create_player(target_data)
		converted_players.append(player_obj)

	return converted_players


# ---------------------------------------------------------------------------
# INFRAESTRUTURA DE RUNNER E ASSERÇÕES
# ---------------------------------------------------------------------------

func _run_test_wrapper(test_name: String, test_callable: Callable) -> void:
	print_rich("[bold]▶ %s[/bold]" % test_name)
	test_callable.call()
	_teardown()
	print("")


func _teardown() -> void:
	LogicInstance.instance = null


func _assert(condition: bool, message: String) -> void:
	_total_assertions += 1
	if condition:
		_passed_assertions += 1
		print_rich("   [color=green]✔ [PASS][/color] %s" % message)
	else:
		_failed_assertions += 1
		print_rich("   [color=red]✘ [FAIL][/color] %s" % message)


func _print_final_summary() -> void:
	print_rich("[bold][color=cyan]==================================================[/color][/bold]")
	print_rich("[bold]RESUMO DA EXECUÇÃO DA SUÍTE DE TESTES:[/bold]")
	print_rich("  • Total de Asserções Evaluadas: %d" % _total_assertions)
	print_rich("  • Aprovadas: [color=green]%d[/color]" % _passed_assertions)
	print_rich("  • Falhadas: [color=red]%d[/color]" % _failed_assertions)
	
	if _failed_assertions == 0:
		print_rich("\n[bold][color=green]✔ TODOS OS TESTES E A SIMULAÇÃO FORAM EXECUTADOS COM SUCESSO![/color][/bold]")
	else:
		print_rich("\n[bold][color=red]✘ ALGUNS TESTES FALHARAM. VERIFIQUE OS LOGS ACIMA.[/color][/bold]")
	print_rich("[bold][color=cyan]==================================================[/color][/bold]\n")


# ---------------------------------------------------------------------------
# FASE 1: SUÍTE DE TESTES UNITÁRIOS DE REGRAS ISOLADAS (TESTES 1 A 10)
# ---------------------------------------------------------------------------

func _run_test_1() -> void:
	var json_card_1: Array = [
		["P0", "P0", "P0"], ["P0", "R0", "P0"],
		["P0", "P0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var json_card_2: Array = [
		["P0", "P0", "P0"], ["P0", "P0", "P0"],
		["P0", "P0", "P0"], ["P0", "R0", "P0"], "E"
	]
	
	var card_a := CardStructure.new()
	card_a.build(json_card_1)
	
	var card_b := CardStructure.new()
	card_b.build(json_card_2)

	var player_1 := IOPlayer.new("p1", "Player A", Color.RED)
	var player_2 := IOPlayer.new("p2", "Player B", Color.BLUE)

	card_a.connect_side(card_b, Vector2i(1, 0))

	_assert(card_a.can_receive_meeple_at(4) == true, "card_a pode receber meeple no slot 4")
	_assert(card_b.can_receive_meeple_at(10) == true, "card_b pode receber meeple no slot 10 antes da ocupação")

	var success_a: bool = card_a.place_meeple(4, player_1)
	_assert(success_a == true, "Sucesso ao alocar meeple do player_1 no slot 4 do card_a")

	var can_b_receive: bool = card_b.can_receive_meeple_at(10)
	_assert(can_b_receive == false, "card_b bloqueado para meeple no slot 10 devido à conexão do grafo")


func _run_test_2() -> void:
	var data_human := PlayerData.new("1", "Humano Teste", Color.GREEN, false)
	var data_ai_basic := PlayerData.new("2", "Bot Básico", Color.RED, true, PlayerData.Difficulty.BASIC)
	var data_ai_adv := PlayerData.new("3", "Bot Avançado", Color.BLACK, true, PlayerData.Difficulty.ADVANCED)

	var p_human: Player = PlayerFactory.create_player(data_human)
	var p_ai_basic: Player = PlayerFactory.create_player(data_ai_basic)
	var p_ai_adv: Player = PlayerFactory.create_player(data_ai_adv)

	_assert(p_human is IOPlayer, "PlayerFactory criou IOPlayer para dados humanos")
	_assert(p_ai_basic is AIPlayer, "PlayerFactory criou AIPlayer para bot básico")
	_assert(p_ai_adv is AIPlayer, "PlayerFactory criou AIPlayer para bot avançado")

	var ai_basic := p_ai_basic as AIPlayer
	var ai_adv := p_ai_adv as AIPlayer

	_assert(ai_basic.strategy is BasicAIStrategy, "Estratégia injetada é BasicAIStrategy")
	_assert(ai_adv.strategy is AdvancedAIStrategy, "Estratégia injetada é AdvancedAIStrategy")


func _run_test_3() -> void:
	var strategy := AdvancedAIStrategy.new()
	var ai_player := AIPlayer.new("ai_1", "Bot Teste", Color.YELLOW, strategy)

	var json_card: Array = [
		["P0", "P0", "P0"], ["P0", "P0", "P0"],
		["P0", "P0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var card := CardStructure.new()
	card.build(json_card)

	var valid_slots: Array[int] = [CardStructure.SKIP_SLOT_INDEX, 0, 1, 2]
	var chosen_slot: int = strategy.choose_meeple_placement(ai_player, card, valid_slots, null)
	_assert(chosen_slot != CardStructure.SKIP_SLOT_INDEX, "IA escolhe slot válido quando possui meeples")

	ai_player.available_meeples = 0
	var chosen_slot_empty: int = strategy.choose_meeple_placement(ai_player, card, valid_slots, null)
	_assert(chosen_slot_empty == CardStructure.SKIP_SLOT_INDEX, "IA força SKIP_SLOT_INDEX quando reserva de meeples é 0")


func _run_test_4() -> void:
	var data_1 := PlayerData.new("1", "P1", Color.RED, false)
	var data_2 := PlayerData.new("2", "P2", Color.BLUE, false)
	
	var match_config := MatchConfig.new()
	match_config.players_data = [data_1, data_2]

	var players: Array[Player] = PlayerFactory.create_players(match_config)
	var logic := LogicInstance.new(players, 1, 10, 60)

	logic.start_game()
	
	var current_p: Player = logic._state_machine.get_current_player()
	_assert(current_p != null, "LogicInstance inicializa e define o jogador do primeiro turno")


func _run_test_5() -> void:
	var p1 := IOPlayer.new("1", "P1", Color.GREEN)
	var p2 := IOPlayer.new("2", "P2", Color.RED)
	var p3 := IOPlayer.new("3", "P3", Color.BLUE)
	var initial_players: Array[Player] = [p1, p2, p3]

	var tsm := TurnStateMachine.new(initial_players, 30.0)
	tsm.start_game()

	var sorted_players: Array[Player] = tsm.players.duplicate()
	_assert(sorted_players.size() == 3, "TurnStateMachine mantém os 3 jogadores na lista")
	_assert(tsm.get_current_player() == sorted_players[0], "O primeiro turno pertence ao primeiro jogador da ordem sorteada")

	tsm.pass_turn()
	_assert(tsm.get_current_player() == sorted_players[1], "Avanço de turno 1 -> 2 correto")

	tsm.pass_turn()
	_assert(tsm.get_current_player() == sorted_players[2], "Avanço de turno 2 -> 3 correto")

	tsm.pass_turn()
	_assert(tsm.get_current_player() == sorted_players[0], "Avanço cíclico (wrap-around) retornou ao jogador 1")
	_assert(tsm.players == sorted_players, "A ordem sorteada permaneceu estritamente fiel durante toda a rodada")

	var timeout_data := {
		"emitted": false,
		"player": null
	}

	tsm.turn_timeout.connect(func(p: Player): 
		timeout_data.emitted = true
		timeout_data.player = p
	)

	_assert(tsm.is_timer_running == true, "Temporizador está ativo para o IOPlayer atual")
	
	tsm.process_timer(31.0)

	_assert(timeout_data.emitted == true, "Sinal turn_timeout foi emitido após estourar o tempo")
	_assert(timeout_data.player == sorted_players[0], "Sinal identificou corretamente o jogador que estourou o tempo")
	_assert(tsm.is_timer_running == false, "Temporizador foi interrompido após o timeout")


func _run_test_6() -> void:
	var board := Board.new()

	var json_card_a: Array = [
		["C0", "C0", "C0"], ["P0", "P0", "P0"],
		["P0", "P0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var card_a := CardStructure.new()
	card_a.build(json_card_a)

	var json_card_d: Array = [
		["P0", "P0", "P0"], ["C0", "C0", "C0"],
		["P0", "P0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var card_d := CardStructure.new()
	card_d.build(json_card_d)

	var placed_a: bool = board.place_card(Vector2i.ZERO, card_a, CardStructure.CARDROTATION.UP)
	_assert(placed_a == true, "Carta A colocada no centro (0, 0)")

	var invalid_placement: bool = board.can_place_card(Vector2i(0, -1), card_d, CardStructure.CARDROTATION.UP)
	_assert(invalid_placement == false, "Recusa encaixe incompatível (Pasto com Cidade em 0, -1)")

	var rot_right_valid: bool = board.can_place_card(Vector2i(0, -1), card_d, CardStructure.CARDROTATION.RIGHT)
	_assert(rot_right_valid == false, "Rotação RIGHT (90°) permanece incompatível em (0, -1)")

	var rot_down_valid: bool = board.can_place_card(Vector2i(0, -1), card_d, CardStructure.CARDROTATION.DOWN)
	_assert(rot_down_valid == false, "Rotação DOWN (180°) permanece incompatível em (0, -1)")

	var rot_left_valid: bool = board.can_place_card(Vector2i(0, -1), card_d, CardStructure.CARDROTATION.LEFT)
	_assert(rot_left_valid == true, "Rotação LEFT (270°) alinha perfeitamente as bordas de Cidade")

	var valids_initial: Dictionary = board.get_valid_card_positions(card_d)
	_assert(valids_initial.has(Vector2i(0, -1)), "Posição (0, -1) está contida no mapa inicial de fronteiras")
	_assert(valids_initial.keys().size() == 4, "Apenas as 4 posições ortogonais do centro (0,0) estão na fronteira inicial")

	var placed_d: bool = board.place_card(Vector2i(0, -1), card_d, CardStructure.CARDROTATION.LEFT)
	_assert(placed_d == true, "Carta D encaixada com sucesso em (0, -1) com rotação LEFT")

	var valids_after: Dictionary = board.get_valid_card_positions(card_d)
	_assert(not board.get_valid_card_positions(card_d).has(Vector2i(0, -1)), "Posição (0, -1) foi ocupada e removida das fronteiras")
	_assert(valids_after.has(Vector2i(0, -2)), "Nova fronteira (0, -2) gerada após encaixar peça em (0, -1)")
	_assert(valids_after.keys().size() > 4, "Mapa de posições válidas expandiu com o crescimento do tabuleiro")


func _run_test_7() -> void:
	var p1 := IOPlayer.new("1", "P1", Color.GREEN)
	var p2 := IOPlayer.new("2", "P2", Color.RED)
	var players: Array[Player] = [p1, p2]

	var logic := LogicInstance.new(players, 1, 10, 60)

	var discard_data := { "emitted": false, "card_id": -1 }
	var draw_data := { "emitted": false, "card_id": -1 }

	logic.card_discarded.connect(func(c_id: int):
		discard_data.emitted = true
		discard_data.card_id = c_id
	)

	logic.card_drawn.connect(func(_p: Player, c_id: int):
		draw_data.emitted = true
		draw_data.card_id = c_id
	)

	logic._board.place_initial_tile(logic.initial_card_id)

	var unplaceable_id: int = -1
	var valid_id: int = -1

	for card_id in range(25):
		var card: CardStructure = Catalogue.get_structure(card_id)
		if card == null:
			continue
		var valids: Dictionary = logic._board.get_valid_card_positions(card)
		if valids.is_empty() and unplaceable_id == -1:
			unplaceable_id = card_id
		elif not valids.is_empty() and valid_id == -1:
			valid_id = card_id

		if unplaceable_id != -1 and valid_id != -1:
			break

	if unplaceable_id == -1:
		for card_id in range(25):
			var extra_card: CardStructure = Catalogue.get_structure(card_id)
			if extra_card and logic._board.can_place_card(Vector2i(0, 1), extra_card, CardStructure.CARDROTATION.UP):
				logic._board.place_card(Vector2i(0, 1), extra_card, CardStructure.CARDROTATION.UP)
				break

		for card_id in range(25):
			var card: CardStructure = Catalogue.get_structure(card_id)
			if card == null:
				continue
			var valids: Dictionary = logic._board.get_valid_card_positions(card)
			if valids.is_empty() and unplaceable_id == -1:
				unplaceable_id = card_id
			elif not valids.is_empty() and valid_id == -1:
				valid_id = card_id

	_assert(unplaceable_id != -1, "Identificada peça incompatível (sem posições válidas no tabuleiro)")
	_assert(valid_id != -1, "Identificada peça válida (com posições disponíveis no tabuleiro)")

	logic._deck._cards = [valid_id, unplaceable_id]

	logic.start_game()

	_assert(discard_data.emitted == true, "Sinal card_discarded foi emitido para a peça incompatível")
	_assert(discard_data.card_id == unplaceable_id, "O ID descartado corresponde exatamente à peça sem posições válidas")
	_assert(draw_data.emitted == true, "Uma nova peça foi sacada automaticamente após o descarte")
	_assert(draw_data.card_id == valid_id, "A nova peça sacada é a próxima disponível na pilha do baralho")
	_assert(logic.current_card_id == valid_id, "LogicInstance atualizou current_card_id para a nova peça válida")


func _run_test_8() -> void:
	var board1 := Board.new()
	var p1 := IOPlayer.new("p1", "P1", Color.RED)
	var p2 := IOPlayer.new("p2", "P2", Color.BLUE)

	# --- 1. Pontuação de Estrada Concluída ---
	var json_road_a: Array = [
		["P0", "P0", "P0"], ["P0", "P0", "P0"],
		["P0", "R0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var card_road_a := CardStructure.new()
	card_road_a.build(json_road_a)

	var json_road_b: Array = [
		["P0", "R0", "P0"], ["P0", "P0", "P0"],
		["P0", "P0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var card_road_b := CardStructure.new()
	card_road_b.build(json_road_b)

	board1.place_card(Vector2i.ZERO, card_road_a, CardStructure.CARDROTATION.UP)
	var meeple_ok: bool = card_road_a.place_meeple(7, p1)
	_assert(meeple_ok == true, "Player 1 alocou meeple na estrada da Carta A")
	_assert(p1.available_meeples == 6, "Reserva do Player 1 reduzida para 6 meeples")

	board1.place_card(Vector2i(0, 1), card_road_b, CardStructure.CARDROTATION.UP)

	_assert(p1.score == 2, "Player 1 recebeu 2 pontos pela estrada concluída (2 cartas)")
	_assert(p1.available_meeples == 7, "Meeple do Player 1 foi devolvido para a reserva após o fecho")

	# --- 2. Pontuação de Cidade Concluída com Brasão ---
	var board2 := Board.new()
	p1.score = 0
	p2.score = 0

	var json_city_a: Array = [
		["P0", "P0", "P0"], ["P0", "P0", "P0"],
		["C0+", "C0", "C0"], ["P0", "P0", "P0"], "E"
	]
	var card_city_a := CardStructure.new()
	card_city_a.build(json_city_a)

	var json_city_b: Array = [
		["C0", "C0", "C0"], ["P0", "P0", "P0"],
		["P0", "P0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var card_city_b := CardStructure.new()
	card_city_b.build(json_city_b)

	board2.place_card(Vector2i.ZERO, card_city_a, CardStructure.CARDROTATION.UP)
	card_city_a.place_meeple(7, p2)

	board2.place_card(Vector2i(0, 1), card_city_b, CardStructure.CARDROTATION.UP)

	_assert(p2.score == 6, "Player 2 recebeu 6 pontos pela cidade concluída com brasão (2 cartas x 2 + 1 brasão x 2)")
	_assert(p2.available_meeples == 7, "Meeple do Player 2 foi devolvido para a reserva após o fecho")

	# --- 3. Pontuação de Mosteiro Concluído (9 pontos) ---
	var board_monastery := Board.new()
	p1.score = 0

	var json_monastery: Array = [
		["P0", "P0", "P0"], ["P0", "P0", "P0"],
		["P0", "P0", "P0"], ["P0", "P0", "P0"], "M1"
	]
	var card_monastery := CardStructure.new()
	card_monastery.build(json_monastery)
	board_monastery.place_card(Vector2i.ZERO, card_monastery, CardStructure.CARDROTATION.UP)
	card_monastery.place_meeple(12, p1) # Slot central (12)

	# As 4 ortogonais primeiro, seguidas pelas 4 diagonais (garante validade de conexão no tabuleiro)
	var surrounding_offsets: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)
	]
	var json_filler: Array = [
		["P0", "P0", "P0"], ["P0", "P0", "P0"],
		["P0", "P0", "P0"], ["P0", "P0", "P0"], "E"
	]
	for pos in surrounding_offsets:
		var filler := CardStructure.new()
		filler.build(json_filler)
		board_monastery.place_card(pos, filler, CardStructure.CARDROTATION.UP)

	var monastery_part: CardPart = card_monastery.middle
	_assert(monastery_part.is_closed() == true, "Mosteiro completamente cercado por 8 vizinhos é reconhecido como concluído")
	_assert(monastery_part.calculate_points() == 9, "Mosteiro concluído calcula exatamente 9 pontos (1 base + 8 vizinhos)")

	# --- 4. Empate na Maioria de Estruturas ---
	var board3 := Board.new()
	p1.score = 0
	p2.score = 0

	var json_anchor: Array = [
		["P0", "P0", "P0"], ["P0", "P0", "P0"],
		["P0", "P0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var card_anchor := CardStructure.new()
	card_anchor.build(json_anchor)
	board3.place_card(Vector2i.ZERO, card_anchor, CardStructure.CARDROTATION.UP)

	var json_f1: Array = [
		["P0", "P0", "P0"], ["P0", "P0", "P0"],
		["P0", "R0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var card_f1 := CardStructure.new()
	card_f1.build(json_f1)
	board3.place_card(Vector2i(-1, 0), card_f1, CardStructure.CARDROTATION.UP)
	card_f1.place_meeple(7, p1)

	var json_f2: Array = [
		["P0", "P0", "P0"], ["P0", "P0", "P0"],
		["P0", "P0", "P0"], ["P0", "R0", "P0"], "E"
	]
	var card_f2 := CardStructure.new()
	card_f2.build(json_f2)
	board3.place_card(Vector2i(0, 1), card_f2, CardStructure.CARDROTATION.UP)
	card_f2.place_meeple(10, p2)

	var json_join: Array = [
		["P0", "R0", "P0"], ["P0", "R0", "P0"],
		["P0", "P0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var card_join := CardStructure.new()
	card_join.build(json_join)
	board3.place_card(Vector2i(-1, 1), card_join, CardStructure.CARDROTATION.UP)

	_assert(p1.score == 3, "Em caso de empate na maioria, Player 1 recebe pontuação total da estrada fundida")
	_assert(p2.score == 3, "Em caso de empate na maioria, Player 2 recebe pontuação total da estrada fundida")
	_assert(p1.available_meeples == 7, "Meeple do Player 1 devolvido após fusão e fecho")
	_assert(p2.available_meeples == 7, "Meeple do Player 2 devolvido após fusão e fecho")


func _run_test_9() -> void:
	var p1 := IOPlayer.new("1", "P1", Color.GREEN)
	var p2 := IOPlayer.new("2", "P2", Color.RED)
	var players: Array[Player] = [p1, p2]

	var logic := LogicInstance.new(players, 1, 1, 60)

	var finished_data := { "emitted": false, "scores": {} }
	logic.game_finished.connect(func(scores: Dictionary):
		finished_data.emitted = true
		finished_data.scores = scores
	)

	logic.start_game()
	logic.pass_turn()

	_assert(finished_data.emitted == true, "Sinal game_finished emitido ao esvaziar o baralho")
	_assert(finished_data.scores.has(p1), "Dicionário de placar final contém o Player 1")
	_assert(finished_data.scores.has(p2), "Dicionário de placar final contém o Player 2")

	# --- Testes de Pontuação Residual Incompleta (Final do Jogo) ---
	var board := Board.new()
	var player_a := IOPlayer.new("a", "PA", Color.RED)
	var player_b := IOPlayer.new("b", "PB", Color.BLUE)

	var json_base: Array = [
		["P0", "P0", "P0"], ["P0", "P0", "P0"],
		["P0", "P0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var card_base := CardStructure.new()
	card_base.build(json_base)
	board.place_card(Vector2i.ZERO, card_base, CardStructure.CARDROTATION.UP)

	# 1. Estrada Incompleta (2 cartas = 2 pts)
	var json_r1: Array = [
		["P0", "P0", "P0"], ["P0", "P0", "P0"],
		["P0", "R0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var card_r1 := CardStructure.new()
	card_r1.build(json_r1)
	board.place_card(Vector2i(0, 1), card_r1, CardStructure.CARDROTATION.UP)
	card_r1.place_meeple(7, player_a)

	var json_r2: Array = [
		["P0", "R0", "P0"], ["P0", "P0", "P0"],
		["P0", "R0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var card_r2 := CardStructure.new()
	card_r2.build(json_r2)
	board.place_card(Vector2i(0, 2), card_r2, CardStructure.CARDROTATION.UP)

	# 2. Cidade Incompleta com Brasão (1 carta + 1 brasão = 2 pts)
	var json_city_emblem: Array = [
		["C0+", "C0", "C0"], ["P0", "P0", "P0"],
		["P0", "P0", "P0"], ["P0", "P0", "P0"], "E"
	]
	var card_c1 := CardStructure.new()
	card_c1.build(json_city_emblem)
	board.place_card(Vector2i(1, 0), card_c1, CardStructure.CARDROTATION.UP)
	card_c1.place_meeple(1, player_b)

	# 3. Mosteiro Incompleto acoplado em (-1, 0) -> possui 2 vizinhos em (0,0) e (0,1) = 3 pts
	var json_monastery_inc: Array = [
		["P0", "P0", "P0"], ["P0", "P0", "P0"],
		["P0", "P0", "P0"], ["P0", "P0", "P0"], "M1"
	]
	var card_mon_inc := CardStructure.new()
	card_mon_inc.build(json_monastery_inc)
	board.place_card(Vector2i(-1, 0), card_mon_inc, CardStructure.CARDROTATION.UP)
	card_mon_inc.place_meeple(12, player_a)

	var mon_part_inc: CardPart = card_mon_inc.middle
	_assert(mon_part_inc.is_closed() == false, "Mosteiro com apenas 2 vizinhos permanece incompleto")
	_assert(mon_part_inc.calculate_points() == 3, "Mosteiro incompleto calcula 3 pontos residuais (1 base + 2 vizinhos)")

	var final_scores: Dictionary = board.calculate_final_scores([player_a, player_b])

	_assert(player_a.score == 5, "Player A recebeu 5 pontos (2 por estrada incompleta + 3 por mosteiro incompleto)")
	_assert(player_b.score == 2, "Player B recebeu 2 pontos por cidade incompleta com brasão (1 carta x 1 + 1 brasão x 1)")
	_assert(final_scores[player_a] == 5, "Placar final reflete os 5 pontos totais do Player A")
	_assert(final_scores[player_b] == 2, "Placar final reflete os 2 pontos totais do Player B")


func _run_test_10() -> void:
	var total_models: int = Catalogue.models.size()
	_assert(total_models > 0, "Catalogue carregou os modelos do arquivo JSON com sucesso")

	var all_structures_valid: bool = true
	var invalid_structure_id: int = -1

	for i in range(1, total_models + 1):
		var struct: CardStructure = Catalogue.get_structure(i)
		
		if struct == null or struct.sides.size() != 12:
			all_structures_valid = false
			invalid_structure_id = i
			break

		for part in struct.sides:
			if part == null:
				all_structures_valid = false
				invalid_structure_id = i
				break

		if not all_structures_valid:
			break

	_assert(all_structures_valid == true, "Todas as %d estruturas de carta do catálogo foram construídas e validadas sem erros" % total_models)

	var deck := Deck.new(72)
	_assert(deck.get_remaining_count() == 72, "Baralho foi inicializado com a contagem esperada de 72 peças")

	var drawn_count: int = 0
	var all_ids_valid: bool = true

	while not deck.is_empty():
		var card_id: int = deck.draw_card_id()
		drawn_count += 1
		
		if not Deck.BASE_CARD_COUNTS.has(card_id):
			all_ids_valid = false

	_assert(drawn_count == 72, "Todas as 72 cartas foram sacadas sequencialmente sem falhas")
	_assert(all_ids_valid == true, "Todos os IDs sacados pertencem às definições válidas do catálogo")
	_assert(deck.is_empty() == true, "Baralho transicionou corretamente para o estado vazio (is_empty == true)")
