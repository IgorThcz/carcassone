@abstract class_name Player extends Resource

# ---------------------------------------------------------------------------
# SINAIS PARA ENVIAR AO LOGIC INSTANCE (requests)
# ---------------------------------------------------------------------------
signal card_placement_request(player: Player, pos: Vector2i, rot: CardStructure.CARDROTATION)
signal meeple_placement_request(player: Player, index: int)

# ---------------------------------------------------------------------------
# SINAIS PARA REPASSAR AO VISUAL INSTANCE (informativos; todo observador recebe)
# ---------------------------------------------------------------------------
signal turn_started_repass(card_id: int, valid_positions: Dictionary[Vector2i, Array])
signal card_placed_repass(
	player: Player,
	coords: Vector2i,
	rotation: CardStructure.CARDROTATION,
	meeple_valid_indexes: Array[int],
	card_id: int
	)
signal meeple_placed_repass(player: Player, index: int)
signal game_finished_repass(scores: Dictionary)
signal card_discarded_repass(card_id: int)

# ---------------------------------------------------------------------------
# INFORMATIONS
# ---------------------------------------------------------------------------
var id: String
var player_name: String
var color: Color

var score: int = 0
var total_meeples: int = 7
var available_meeples: int = 7

# cache do último estado recebido, usado para re-decidir em caso de negação
var _current_card_id: int = -1
var _current_valid_positions: Dictionary[Vector2i, Array] = {}
var _current_meeple_valid_indexes: Array[int] = []

func _init(p_id: String, p_name: String, p_color: Color) -> void:
	id = p_id
	player_name = p_name
	color = p_color

# ---------------------------------------------------------------------------
# METODOS DE EMISSÃO DE SINAIS (chamados pela decisão da IA ou pela UI)
# ---------------------------------------------------------------------------
func request_place_card(pos: Vector2i, rot: CardStructure.CARDROTATION) -> void:
	card_placement_request.emit(self, pos, rot)

func request_place_meeple(index: int) -> void:
	meeple_placement_request.emit(self, index)

# ---------------------------------------------------------------------------
# ESSENTIAL CLASS METHODS
# ---------------------------------------------------------------------------
func has_available_meeple() -> bool:
	return available_meeples > 0

func use_meeple() -> void:
	if available_meeples > 0:
		available_meeples -= 1

func return_meeple() -> void:
	if available_meeples < total_meeples:
		available_meeples += 1

func add_score(points: int) -> void:
	score += points

func _is_self(player: Player) -> bool:
	return player == self

# ---------------------------------------------------------------------------
# RECEBIMENTO DOS SINAIS DO LOGIC INSTANCE
# Todo player conectado repassa a informação pra UI (útil pra exibir o estado
# do jogo pra todo mundo). Só quem é o alvo do evento (_is_self) de fato decide
# a próxima jogada.
# ---------------------------------------------------------------------------

func on_logic_instance_turn_passed(
	player: Player,
	card_id: int,
	valid_positions: Dictionary[Vector2i, Array]
) -> void:
	turn_started_repass.emit(card_id, valid_positions)
	if _is_self(player):
		_current_card_id = card_id
		_current_valid_positions = valid_positions
		_decide_card_placement(card_id, valid_positions)

func on_logic_instance_card_placed(
	player: Player,
	coords: Vector2i,
	rotation: CardStructure.CARDROTATION,
	meeple_valid_indexes: Array[int],
	card_id: int
) -> void:
	print("PLAYER CARD PLACED")
	card_placed_repass.emit(player, coords, rotation, meeple_valid_indexes, card_id)
	if _is_self(player):
		_current_meeple_valid_indexes = meeple_valid_indexes
		_decide_meeple_placement(meeple_valid_indexes)

func on_logic_instance_meeple_placed(player: Player, index: int) -> void:
	meeple_placed_repass.emit(player, index)

func on_logic_instance_card_placement_denied(player: Player) -> void:
	if _is_self(player):
		_decide_card_placement(_current_card_id, _current_valid_positions)

func on_logic_instance_meeple_placement_denied(player: Player) -> void:
	if _is_self(player):
		_decide_meeple_placement(_current_meeple_valid_indexes)

func on_logic_instance_game_finished(scores: Dictionary) -> void:
	game_finished_repass.emit(scores)

func on_logic_instance_card_discarded(card_id: int) -> void:
	card_discarded_repass.emit(card_id)

# ---------------------------------------------------------------------------
# HOOKS ABSTRATOS DE DECISÃO
# AI PLAYERS: decidem sozinhos e chamam request_place_card/request_place_meeple.
# IO PLAYERS: disparam os procedimentos de UI que, no fim, chamam essas mesmas
# funções de request quando o jogador humano confirmar a jogada.
# ---------------------------------------------------------------------------

@abstract
func _decide_card_placement(card_id: int, valid_positions: Dictionary[Vector2i, Array]) -> void

@abstract
func _decide_meeple_placement(meeple_valid_indexes: Array[int]) -> void
