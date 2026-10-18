class_name LogicInstance
extends RefCounted

## Orquestrador do Domínio do Jogo.
## Gerencia exclusivamente o ciclo de vida das entidades do jogo (Tabuleiro, Baralho, Jogadores, Turnos).

static var instance: LogicInstance = null

signal turn_passed(player: Player, card_id: int, valid_positions: Dictionary)
signal card_drawn(player: Player, card_id: int)
signal card_placed(player: Player, coords: Vector2i, rotation: CardStructure.CARDROTATION, meeple_valids: Array[int], card_id: int)
signal meeple_placed(player: Player, slot_index: int)
signal card_discarded(card_id: int)
signal game_finished(final_scores: Dictionary)

var players: Array[Player] = []
var initial_card_id: int = 1
var total_tiles: int = 72
var turn_time_limit: int = 60

var current_drawn_card: CardStructure = null
var current_card_id: int = -1

var _board: Board = null
var _deck: Deck = null
var _state_machine: TurnStateMachine = null
var _game_started: bool = false


func _init(
	p_players: Array[Player], 
	p_initial_card_id: int = 1, 
	target_deck_size: int = 72,
	p_turn_time_limit: int = 60
) -> void:
	LogicInstance.instance = self
	
	self.players = p_players
	self.initial_card_id = p_initial_card_id
	self.total_tiles = target_deck_size
	self.turn_time_limit = max(30, p_turn_time_limit)

	_board = Board.new()
	
	# 1 peça é reservada para o centro (start_card)
	# e as peças restantes (total_tiles - 1) compõem a pilha de compras.
	var deck_size: int = max(1, self.total_tiles - 1)
	_deck = Deck.new(deck_size)
	
	_state_machine = TurnStateMachine.new(self.players, self.turn_time_limit)

	# Conecta as requisições dos jogadores ao orquestrador
	for p in self.players:
		if not p.card_placement_request.is_connected(_on_player_card_placement_request):
			p.card_placement_request.connect(_on_player_card_placement_request)
		if not p.meeple_placement_request.is_connected(_on_player_meeple_placement_request):
			p.meeple_placement_request.connect(_on_player_meeple_placement_request)
		if not self.turn_passed.is_connected(p.on_logic_instance_turn_passed):
			self.turn_passed.connect(p.on_logic_instance_turn_passed)
		if not self.card_placed.is_connected(p.on_logic_instance_card_placed):
			self.card_placed.connect(p.on_logic_instance_card_placed)


func start_game() -> void:
	if _game_started:
		return

	_game_started = true

	# Instancia a peça inicial em (0, 0)
	var start_card: CardStructure = _board.place_initial_tile(initial_card_id)
	if start_card:
		card_placed.emit(null, Vector2i.ZERO, CardStructure.CARDROTATION.UP, [] as Array[int], initial_card_id)

	if _state_machine.has_signal("turn_timer_timeout"):
		_state_machine.turn_timer_timeout.connect(pass_turn)

	_state_machine.start_game()
	_advance_to_next_valid_draw()


func pass_turn() -> void:
	if not _game_started:
		return

	current_drawn_card = null
	current_card_id = -1

	_state_machine.next_turn()
	_advance_to_next_valid_draw()


func _advance_to_next_valid_draw() -> void:
	while not _deck.is_empty():
		current_card_id = _deck.draw_card_id()
		current_drawn_card = Catalogue.get_structure(current_card_id)

		# REGRA: Estruturas nulas ou corrompidas do catálogo emitem descarte imediatamente
		if current_drawn_card == null:
			print("[LogicInstance] Peça ID %d com estrutura nula. Descartando..." % current_card_id)
			card_discarded.emit(current_card_id)
			continue

		var valid_positions: Dictionary = _board.get_valid_card_positions(current_drawn_card)

		# Descarte automático e imediato quando a peça não encaixa em lugar nenhum
		if valid_positions.is_empty():
			print("[LogicInstance] Peça ID %d sem posições válidas no tabuleiro. Descartando..." % current_card_id)
			card_discarded.emit(current_card_id)
			continue

		var current_player: Player = _state_machine.get_current_player()
		
		card_drawn.emit(current_player, current_card_id)
		turn_passed.emit(current_player, current_card_id, valid_positions)
		return

	_finish_game()


# --- FACHADA DE CONSULTA DO ESTADO DO TABULEIRO (Para UI, IA e Debug) ---

func get_valid_card_positions() -> Dictionary:
	if current_drawn_card == null or _board == null:
		return {}
	return _board.get_valid_card_positions(current_drawn_card)


func get_valid_meeple_slots() -> Array[int]:
	var current_player: Player = _state_machine.get_current_player() if _state_machine else null
	if current_drawn_card == null or current_player == null:
		return []
	return current_drawn_card.get_valid_meeple_slots(current_player)


# --- REQUISIÇÕES DOS JOGADORES ---

func _on_player_card_placement_request(player: Player, coords: Vector2i, p_rotation: CardStructure.CARDROTATION) -> void:
	if player != _state_machine.get_current_player() or current_drawn_card == null:
		return

	if _board.can_place_card(coords, current_drawn_card, p_rotation):
		_board.place_card(coords, current_drawn_card, p_rotation)
		var valid_slots: Array[int] = current_drawn_card.get_valid_meeple_slots(player)
		card_placed.emit(player, coords, p_rotation, valid_slots, current_card_id)


func _on_player_meeple_placement_request(player: Player, slot_index: int) -> void:
	if player != _state_machine.get_current_player():
		return

	if current_drawn_card and slot_index != CardStructure.SKIP_SLOT_INDEX:
		current_drawn_card.place_meeple(slot_index, player)
		player.use_meeple()

	meeple_placed.emit(player, slot_index)
	pass_turn()


func _finish_game() -> void:
	_game_started = false
	var final_scores: Dictionary = _board.calculate_final_scores(players)
	game_finished.emit(final_scores)