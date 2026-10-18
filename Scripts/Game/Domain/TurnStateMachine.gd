class_name TurnStateMachine
extends RefCounted

## Delegador de ações para o estado ativo e gerenciador da fila de jogadores/tempo.

signal state_changed(state_name: String)
signal turn_started(player: Player)
signal turn_ended(player: Player)
signal timer_updated(time_remaining: float)
signal turn_timeout(player: Player)
signal turn_timer_timeout() # Sinal de compatibilidade para estouro de tempo
signal match_finished()

var players: Array[Player] = []
var current_player_index: int = 0
var current_state: TurnState = null

# Temporizador de Turno (Padrão 60s)
var turn_time_limit: float = 60.0
var time_remaining: float = 0.0
var is_timer_running: bool = false


## Construtor com suporte aos parâmetros passados por LogicInstance.new(players, time_limit)
func _init(p_players: Array[Player] = [], p_turn_time_limit: float = 60.0) -> void:
	self.players = p_players.duplicate() if not p_players.is_empty() else []
	self.turn_time_limit = maxf(30.0, p_turn_time_limit) # Mínimo garantido de 30s


## Inicia a partida, sorteia a ordem e define o estado inicial
func start_match(p_players: Array[Player] = [], time_limit_seconds: float = -1.0) -> void:
	if not p_players.is_empty():
		players = p_players.duplicate()
		
	if time_limit_seconds > 0.0:
		turn_time_limit = time_limit_seconds

	if players.is_empty():
		push_error("[TurnStateMachine] Não é possível iniciar sem jogadores.")
		return

	players.shuffle() # Sorteio aleatório da ordem de jogada
	current_player_index = 0

	print("[TurnStateMachine] Partida iniciada com limite de %ds/turno. Ordem sorteada:" % int(turn_time_limit))
	for i in range(players.size()):
		print(" - %dº: %s (ID: %s)" % [i + 1, players[i].player_name, players[i].id])

	_start_current_player_turn()


## Para compatibilidade com chamadas da LogicInstance
func start_game() -> void:
	start_match(players, turn_time_limit)


## Transição de Estado (GoF State Pattern)
func change_state(new_state: TurnState) -> void:
	if current_state:
		current_state.exit()

	current_state = new_state
	state_changed.emit(current_state.get_name())
	current_state.enter()


## Avança sequencialmente para o próximo jogador 
func pass_turn() -> void:
	if current_state is MatchFinishedState:
		return

	_stop_timer()
	var previous_player: Player = get_current_player()
	turn_ended.emit(previous_player)

	current_player_index = (current_player_index + 1) % players.size()
	_start_current_player_turn()


## Para compatibilidade com LogicInstance.next_turn()
func next_turn() -> void:
	pass_turn()


## Encerra a partida definitivamente 
func finish_match() -> void:
	_stop_timer()
	change_state(MatchFinishedState.new(self))
	match_finished.emit()


## Inicia o turno do jogador ativo e define o estado inicial (DRAW_TILE)
func _start_current_player_turn() -> void:
	var active_player: Player = get_current_player()

	print("\n[TurnStateMachine] Turno iniciado para: %s" % active_player.player_name)
	turn_started.emit(active_player)

	change_state(DrawTileState.new(self))

	if turn_time_limit > 0.0 and not (active_player is AIPlayer):
		_start_timer(turn_time_limit)


# ---------------------------------------------------------------------------
# DELEGAÇÃO POLIMÓRFICA DE AÇÕES AO ESTADO ATIVO 
# ---------------------------------------------------------------------------

func request_draw_tile() -> bool:
	return current_state.draw_tile() if current_state else false

func request_place_tile(pos: Vector2i, rot: int) -> bool:
	return current_state.place_tile(pos, rot) if current_state else false

func request_place_meeple(slot_index: int) -> bool:
	return current_state.place_meeple(slot_index) if current_state else false

func request_skip_meeple() -> bool:
	return current_state.skip_meeple() if current_state else false

func request_resolve_score() -> bool:
	return current_state.resolve_score() if current_state else false


# ---------------------------------------------------------------------------
# CONTROLE DO TEMPORIZADOR
# ---------------------------------------------------------------------------

func process_timer(delta: float) -> void:
	if not is_timer_running:
		return

	time_remaining -= delta
	timer_updated.emit(maxf(time_remaining, 0.0))

	if time_remaining <= 0.0:
		_stop_timer()
		var player: Player = get_current_player()
		print("[TurnStateMachine] Tempo esgotado para: %s" % player.player_name)
		turn_timeout.emit(player)
		turn_timer_timeout.emit()


func _start_timer(seconds: float) -> void:
	time_remaining = seconds
	is_timer_running = true

func _stop_timer() -> void:
	is_timer_running = false

func get_current_player() -> Player:
	if players.is_empty():
		return null
	return players[current_player_index]

func get_current_state_name() -> String:
	return current_state.get_name() if current_state else "NONE"