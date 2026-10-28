class_name VisualInstance extends Node

const PACKED_VIEW3D : PackedScene = preload("uid://1ubmmbdpuave")
const PACKED_VIEW2D : PackedScene = preload("uid://1ubmmbdpuave")
const PACKED_HUD    : PackedScene = preload("uid://7ljxslmfnf35")

enum VIEW_MODE {TRIDIMENSIONAL, BIDIMENSIONAL}

var view : Node
var hud  : GameHUD

var players : Array[Player]
var local_player : Player

# cache da última carta colocada, usado pra resolver a posição no meeple_placed_repass
# (que não carrega card_pos)
var _last_placed_card_pos : Vector2i = Vector2i.ZERO

func _init(p_players: Array[Player], mode: VIEW_MODE) -> void:
	# set players
	players = p_players
	local_player = p_players[0]
	# set view
	view = _make_visualizer(mode)
	add_child(view)
	# set HUD
	hud = PACKED_HUD.instantiate()
	add_child(hud)
	# connect signals
	_setup_connections()

func _ready():
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
	MO.sucess("SIGNALS CONNECTED")

	# 1. Escuta SINAIS REPASSADOS PELO PLAYER -> Chama métodos na View/HUD
	local_player.turn_started_repass.connect(_on_turn_started)
	local_player.card_placed_repass.connect(_on_card_placed_repass)
	local_player.meeple_placed_repass.connect(_on_meeple_placed_repass)
	local_player.game_finished_repass.connect(_on_game_finished_repass)
	local_player.card_discarded_repass.connect(_on_card_discarded_repass)

	# 2. Escuta AÇÕES DA VIEW 3D -> Chama métodos no controller do Player
	if view and view.has_signal("tile_placement_requested"):
		view.tile_placement_requested.connect(_on_tile_placement_requested)
	if view and view.has_signal("meeple_placement_requested"):
		view.meeple_placement_requested.connect(_on_meeple_placement_requested)


# ==========================================================
# RESPOSTA A SINAIS REPASSADOS (Player -> VisualInstance -> View/HUD)
# ==========================================================

func _on_turn_started(
	player_id       : String,
	card_id         : int,
	valid_positions : Dictionary[Vector2i, Array]
) -> void:
	MO.sucess("VisualInstance received turn start signal")
	hud.set_current_displayed_card(card_id)
	for player : Player in players:
		if player is IOPlayer and player.id == player_id:
			view.go_place_card_mode(card_id, valid_positions)
			hud.set_current_player(player_id)
			return
	view.exit_all_modes()

func _on_card_placed_repass(
	player_id: String,
	coords: Vector2i,
	rotation: CardStructure.CARDROTATION,
	meeple_valid_indexes: Array[int],
	card_id: int
) -> void:
	MO.sucess("CARD PLACED REPASS RECEIVED")
	_last_placed_card_pos = coords
	# adiciona a carta visualmente
	view.add_card(coords, card_id, rotation)
	# se o player está nessa VisualInstance, entre em modo de colocar meeple
	for player : Player in players:
		if player is IOPlayer and player.id != player_id:
			if (not meeple_valid_indexes.is_empty()) and player.has_available_meeple():
				view.go_place_meeple_mode(meeple_valid_indexes)
				hud.set_current_player(player_id)
			return
	# se não é nehum player desssa VisualInstance, fica em espera
	view.exit_all_modes()

func _on_meeple_placed_repass(player: Player, index: int) -> void:
	if view.has_method("add_meeple"):
		view.add_meeple(_last_placed_card_pos, index)

func _on_game_finished_repass(scores: Dictionary) -> void:
	if hud and hud.has_method("show_final_scores"):
		hud.show_final_scores(scores)

func _on_card_discarded_repass(card_id: int) -> void:
	if hud and hud.has_method("show_discard_feedback"):
		hud.show_discard_feedback(card_id)

# ==========================================================
# AÇÕES DA INTERFACE -> MÉTODOS NOS CONTROLLERS
# ==========================================================

func _on_tile_placement_requested(grid_pos: Vector2i, rot: CardStructure.CARDROTATION) -> void:
	if local_player and local_player.has_method("request_place_card"):
		local_player.request_place_card(grid_pos, rot)

func _on_meeple_placement_requested(meeple_index: int) -> void:
	if local_player and local_player.has_method("request_place_meeple"):
		local_player.request_place_meeple(meeple_index)
