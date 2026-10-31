class_name VisualInstance extends Node

#-------------------------------------------------------------------------------
const PACKED_VIEW3D : PackedScene = preload("uid://1ubmmbdpuave")
const PACKED_VIEW2D : PackedScene = preload("uid://1ubmmbdpuave")
const PACKED_HUD    : PackedScene = preload("uid://7ljxslmfnf35")

# ------------------------------------------------------------------------------
enum VIEW_MODE {TRIDIMENSIONAL, BIDIMENSIONAL}
enum INSTANCE_MODE {
	WAITING,
	PLACING_CARD,
	SENT_CARD_PLACEMENT_REQUEST,
	PLACING_MEEPLE,
	SENT_MEEPLE_PLACEMENT_REQUEST
}
var mode : INSTANCE_MODE = INSTANCE_MODE.WAITING

#-------------------------------------------------------------------------------
var view : View
var hud  : GameHUD

var players : Array[Player]
var local_player : Player

#-------------------------------------------------------------------------------
var current_drawn_card_id    : int
var current_valid_positions : Dictionary[Vector2i, Array]

var last_placed_card_pos    : Vector2i = Vector2i.ZERO

var current_valid_indexes   : Array[int]

"---------------------------- INICIALIZAÇÕES -----------------------------------"

func _init(p_players: Array[Player], view_mode: VIEW_MODE) -> void:
	# set players
	if p_players.is_empty():
		# algo tem que ter dado MUITO errado pra isso sair vazio
		return
	players = p_players
	local_player = p_players[0]
	# set view
	view = _make_visualizer(view_mode)
	# set HUD
	hud = PACKED_HUD.instantiate()
	# connect signals
	_setup_connections()

func _ready():
	# add vie and hud to tree
	add_child(view)
	add_child(hud)
	for player : Player in players:
		hud.add_player(player.player_name, player.id, player.color)

func _make_visualizer(view_mode : VIEW_MODE) -> Node:
	if view_mode == VIEW_MODE.BIDIMENSIONAL:
		push_warning("2D View not implemented yet, using 3D instead")
		var view_ : Node = PACKED_VIEW2D.instantiate()
		return view_
	else:
		var view_ : Node = PACKED_VIEW3D.instantiate()
		return view_

func _setup_connections() -> void:
	if not local_player:
		return
	MO.success("SIGNALS CONNECTED")

	# 1. Escuta SINAIS REPASSADOS PELO PLAYER -> Chama métodos na View/HUD
	local_player.turn_started_repass     .connect(_on_turn_started)
	local_player.card_placement_denied   .connect(_on_card_placement_denied_repass)
	local_player.card_placed_repass      .connect(_on_card_placed_repass)
	local_player.meeple_placement_denied .connect(_on_meeple_placement_denied_repass)
	local_player.meeple_placed_repass    .connect(_on_meeple_placed_repass)
	local_player.game_finished_repass    .connect(_on_game_finished_repass)
	local_player.card_discarded_repass   .connect(_on_card_discarded_repass)

	# 2. Escuta AÇÕES DA VIEW 3D -> Chama métodos no controller do Player
	if view and view.has_signal("tile_placement_requested"):
		view.tile_placement_requested.connect(_on_tile_placement_requested)
	if view and view.has_signal("meeple_placement_requested"):
		view.meeple_placement_requested.connect(_on_meeple_placement_requested)

"--------------------- RESPOSTAS A SINAIS DO PLAYER ----------------------------"

# turno foi passado:
# - (sempre)
#   - atualiza na hud o player atual e a carta atual
#   - atualiza na hud a quantidade de cartas restantes
# - (player)
#   - salva configurações do posicionamento da carta
#   - view entra no modo de colocar carta
#   - modo troca para colocando carta
# - (não player)
#   - view sai de qualquer modo
#   - modo troca para espera
func _on_turn_started(
	player_id       : String,
	card_id         : int,
	valid_positions : Dictionary[Vector2i, Array]
) -> void:
	MO.success("TURN STARDED RECEIVED")
	# sempre -------------------------------------------------------------------
	current_drawn_card_id = card_id
	current_valid_positions = valid_positions
	hud.set_current_displayed_card(card_id)
	hud.set_current_player(player_id)
	hud.decrease_card_count()
	# se o player está nessa instancia -----------------------------------------
	for player : Player in players:
		if player is IOPlayer and player.id == player_id:
			view.go_place_card_mode(card_id, valid_positions)
			mode = INSTANCE_MODE.PLACING_CARD
			return
	# se o player não está nessa instancia -------------------------------------
	view.exit_all_modes()
	mode = INSTANCE_MODE.WAITING

# o LogicInstance não pode validar a solicitação de posicionamento de carta
# esse sinal só vale para requests de players dentro da vez
# - (send)
#   - retorna a view ao modo de posicionar carta
#   - modo muda para posicionando carta
func _on_card_placement_denied_repass():
	# se o envio de carta veio daqui -------------------------------------------
	if mode == INSTANCE_MODE.SENT_CARD_PLACEMENT_REQUEST:
		view.go_place_card_mode(current_drawn_card_id, current_valid_positions)
		mode = INSTANCE_MODE.PLACING_CARD

# ultima carta posicionada foi validada e enviada juntamente com as posições
# válidas para o jogador posicionar um meeple
# - (sempre)
#   - salva onde a carta foi posicionada
#   - posicionar carta visualmente na view
# - (send)
#   - (meeples)
#     - salva configurações para o posicionamento
#     - view entra no modo de posicionamento de meeple
#     - modo muda para posicionando meeple
# - (not send)
#   - view sai de qualquer modo
#   - modo troca para espera
func _on_card_placed_repass(
	player_id: String,
	coords: Vector2i,
	rotation: CardStructure.CARDROTATION,
	# vazio se não pode posicionar (por quantidade ou configuração do jogo)
	meeple_valid_indexes: Array[int],
	card_id: int
) -> void:
	MO.success("CARD PLACED RECEIVED")
	if meeple_valid_indexes.is_empty():
		MO.error("BUT MEEPLES IS EMPTY")
	# sempre -------------------------------------------------------------------
	last_placed_card_pos = coords
	view.add_card(coords, card_id, rotation)
	# se estava esperando resposta de posicionamento de carta ------------------
	if mode == INSTANCE_MODE.SENT_CARD_PLACEMENT_REQUEST:
		if not meeple_valid_indexes.is_empty():
			current_valid_indexes = meeple_valid_indexes
			view.go_place_meeple_mode(meeple_valid_indexes)
			mode = INSTANCE_MODE.PLACING_MEEPLE
			return
	# se estava esperando apenas -----------------------------------------------
	view.exit_all_modes()
	mode = INSTANCE_MODE.WAITING

# o LogicInstance não pode validar a solicitação de posicionamento de meeple
# esse sinal só vale para requests de players dentro da vez
# - (send)
#   - retorna a view ao modo de posicionar meeple
#   - modo muda para posicionando meeple
func _on_meeple_placement_denied_repass():
	if mode == INSTANCE_MODE.SENT_MEEPLE_PLACEMENT_REQUEST:
		view.go_place_meeple_mode(current_valid_indexes)
		mode = INSTANCE_MODE.PLACING_MEEPLE

# ultimo meeple posicionado foi validado
# - (sempre)
#   - posicionar meeple visualmente na view
#   - view sai de todos os modos
# - (send)
#   - remove um meeple do player na hud
#   - modo muda para esperando
func _on_meeple_placed_repass(player: Player, index: int) -> void:
	view.add_meeple(last_placed_card_pos, index)
	hud.set_meeples_for_player(player.available_meeples, player.id)
	if mode == INSTANCE_MODE.SENT_MEEPLE_PLACEMENT_REQUEST:
		view.exit_all_modes()
		mode = INSTANCE_MODE.WAITING

# o LogicInstance determinou fim do jogo
# - (sempre)
#   - mostrar tela de resultados
func _on_game_finished_repass(scores: Dictionary) -> void:
	if hud and hud.has_method("show_final_scores"):
		hud.show_final_scores(scores)

# se o LogicInstance comprou uma carta não posicionável do deck
# - (sempre)
#   - diminui a quantidade de cartas restantes em 1
func _on_card_discarded_repass(_card_id: int) -> void:
	hud.decrease_card_count()

"---------------------- ENVIO DE DECISÕES DOS JOGADORES ------------------------"

func _on_tile_placement_requested(grid_pos: Vector2i, rot: CardStructure.CARDROTATION) -> void:
	if local_player and local_player.has_method("request_place_card"):
		MO.success("CARD PLACEMENT REQESTED")
		mode = INSTANCE_MODE.SENT_CARD_PLACEMENT_REQUEST
		local_player.request_place_card(grid_pos, rot)

func _on_meeple_placement_requested(meeple_index: int) -> void:
	if local_player and local_player.has_method("request_place_meeple"):
		MO.success("MEEPLE PLACEMENT REQESTED")
		mode = INSTANCE_MODE.SENT_MEEPLE_PLACEMENT_REQUEST
		local_player.request_place_meeple(meeple_index)
