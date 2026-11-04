class_name GameHUD extends Control

const PACKED_PLAYER_TRACKER : PackedScene = preload("uid://btvdexw4nwgkr")

@onready var sidebar    : Panel         = $MarginContainer/HBoxContainer/HBoxContainer/sidebar
@onready var playerbar  : VBoxContainer = $MarginContainer/HBoxContainer/HBoxContainer/sidebar/MarginContainer/VBoxContainer/playerbar
@onready var display    : SubViewport   = $MarginContainer/HBoxContainer/HBoxContainer/sidebar/MarginContainer/VBoxContainer/current_card_bar/HBoxContainer/SubViewportContainer/card_display_3D
@onready var cardcount  : RichTextLabel = $MarginContainer/HBoxContainer/HBoxContainer/sidebar/MarginContainer/VBoxContainer/current_card_bar/cardcount
@onready var clp_button : Button        = $MarginContainer/HBoxContainer/HBoxContainer/VBoxContainer/colapse_uncolapse

var total_cards   : int
var current_cards : int

# int -> player tracker
var players : Dictionary[String, PlayerTracker] = {}

var bar_visible : bool = true

func _ready():
	total_cards = GameManager.active_config.total_tiles
	# sinal de carta não é emitido para a primeira
	current_cards = total_cards - 1
	_set_card_counter()

func _set_card_counter() -> void:
	cardcount.text = "restantes\n"+str(current_cards)+"/"+str(total_cards)

func _on_colapse_uncolapse_pressed():
	bar_visible = not bar_visible
	sidebar.visible = bar_visible
	if bar_visible:
		clp_button.text = "esconder barra"
	else: clp_button.text = "mostrar barra"

# add player with all meeples
func add_player(name_ : String, id : String, color : Color) -> bool:
	# valida o id do player
	if players.has(id): return false
	# create and add to dictionary
	var new : PlayerTracker = PACKED_PLAYER_TRACKER.instantiate()
	players.set(id, new)
	# add to tree
	playerbar.add_child(new)
	# set data
	new.set_data(id, name_, color, 0, GameManager.active_config.meeple_limit)
	return true

func set_current_player(player_id : String):
	for player_tracker : PlayerTracker in players.values():
		if player_tracker.id != player_id:
			player_tracker.set_uncurrent()
		else:
			player_tracker.set_current()

func set_meeples_for_player(meeples : int, player_id : String) -> bool:
	var player = players.get(player_id, null)
	if not players: return false
	player.update_meeples(meeples)
	return true

func set_points_for_player(points : int, player_id : String) -> bool:
	var player = players.get(player_id, null)
	if not players: return false
	player.update_points(points)
	return true

func set_current_displayed_card(id : int) -> void:
	display.set_card(id)

func decrease_card_count() -> void:
	current_cards -= 1
	_set_card_counter()

func launch_ranking_screen(players_ : Array[Player]) -> void:
	$RankingScreen.set_rankings(players_)

func _on_encerrar_agora_pressed():
	launch_ranking_screen(GameManager.active_logic.players)
