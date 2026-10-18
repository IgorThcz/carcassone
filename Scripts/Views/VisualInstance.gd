class_name VisualInstance extends Node

var view : Node
var hud  : Control

var players : Array[Player]
var local_player : Player

# cache da última carta colocada, usado pra resolver a posição no meeple_placed_repass
# (que não carrega card_pos)
var _last_placed_card_pos : Vector2i = Vector2i.ZERO

func _init(p_players: Array[Player], visualizer: Node) -> void:
	players = p_players
	view = visualizer
	add_child(view)
	local_player = p_players[0]
	_setup_connections()

func _setup_connections() -> void:
	if not local_player:
		return

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

func _on_turn_started(card_id: int, valid_positions: Dictionary) -> void:
	if view.has_method("place_mode"):
		var valids: Array[Vector2i] = []
		valids.assign(valid_positions.keys())
		view.place_mode(valids)

	if hud and hud.has_method("update_drawn_card"):
		hud.update_drawn_card(card_id)

func _on_card_placed_repass(
	player: Player,
	coords: Vector2i,
	rotation: CardStructure.CARDROTATION,
	meeple_valid_indexes: Array[int],
	card_id: int
) -> void:
	_last_placed_card_pos = coords

	if view.has_method("add_card"):
		view.add_card(coords, card_id, rotation)

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

func _on_meeple_placement_requested(card_pos: Vector2i, meeple_index: int) -> void:
	if local_player and local_player.has_method("request_place_meeple"):
		local_player.request_place_meeple(meeple_index)
