@abstract class_name Player extends Resource

## Classe base abstrata para todos os tipos de jogadores (Humanos e IA).
## Gerencia recursos (meeples, placar) e aplica Template Method para o fluxo de turnos.

# ---------------------------------------------------------------------------
# SINAIS DE REQUISIÇÃO (Para a LogicInstance)
# ---------------------------------------------------------------------------
signal card_placement_request(player: Player, pos: Vector2i, rot: CardStructure.CARDROTATION)
signal meeple_placement_request(player: Player, index: int)

# ---------------------------------------------------------------------------
# SINAIS DE REPASSE (Para observadores e UI)
# ---------------------------------------------------------------------------
signal turn_started_repass(player_id: String, card_id: int, valid_positions: Dictionary[Vector2i, Array])
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
# ATRIBUTOS DE ESTADO E DOMÍNIO
# ---------------------------------------------------------------------------
var id: String
var player_name: String
var color: Color

var score: int = 0
var total_meeples: int = 7
var available_meeples: int = 7

# Cache do último estado recebido para eventuais re-tentativas após negação
var _current_card_id: int = -1
var _current_valid_positions: Dictionary[Vector2i, Array] = {}
var _current_meeple_valid_indexes: Array[int] = []


func _init(p_id: String, p_name: String, p_color: Color) -> void:
	id = p_id
	player_name = p_name
	color = p_color


# ---------------------------------------------------------------------------
# MÉTODOS PÚBLICOS DE REQUISIÇÃO
# ---------------------------------------------------------------------------
func request_place_card(pos: Vector2i, rot: CardStructure.CARDROTATION) -> void:
	card_placement_request.emit(self, pos, rot)


func request_place_meeple(index: int) -> void:
	meeple_placement_request.emit(self, index)


# ---------------------------------------------------------------------------
# REGRAS DE DOMÍNIO
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
# TRATAMENTO DE EVENTOS DA LOGIC INSTANCE (TEMPLATE METHOD)
# ---------------------------------------------------------------------------
func on_logic_instance_turn_passed(
	player: Player,
	card_id: int,
	valid_positions: Dictionary[Vector2i, Array]
) -> void:
	MO.sucess("SIGNAL REPASSED")
	turn_started_repass.emit(player.id, card_id, valid_positions)
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
# HOOKS ABSTRATOS DE DECISÃO (Implementados por AIPlayer e HumanPlayer/IO)
# ---------------------------------------------------------------------------
@abstract
func _decide_card_placement(card_id: int, valid_positions: Dictionary[Vector2i, Array]) -> void

@abstract
func _decide_meeple_placement(meeple_valid_indexes: Array[int]) -> void
