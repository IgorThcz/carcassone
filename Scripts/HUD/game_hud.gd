class_name GameHUD extends Control

const PACKED_PLAYER_TRACKER : PackedScene = preload("uid://btvdexw4nwgkr")

@onready var sidebar   : Panel         = $MarginContainer/HBoxContainer/HBoxContainer/sidebar
@onready var playerbar : VBoxContainer = $MarginContainer/HBoxContainer/HBoxContainer/sidebar/VBoxContainer/playerbar
@onready var display   : SubViewport   = $MarginContainer/HBoxContainer/HBoxContainer/sidebar/VBoxContainer/current_card_bar/HBoxContainer/SubViewportContainer/card_display_3D
@onready var mep_opt   : Control       = $MarginContainer/HBoxContainer/HBoxContainer/sidebar/VBoxContainer/current_card_bar/HBoxContainer/SubViewportContainer/meeple_options

signal index_hovered_repass(index : int)
signal index_selected_repass(index : int)

# int -> player tracker
var players : Dictionary[int, PlayerTracker] = {}

func _on_colapse_uncolapse_toggled(toggled_on : bool) -> void:
	sidebar.visible = toggled_on

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
		else: player_tracker.set_current()

func set_meeples_for_player(meeples : int, player_id : String) -> bool:
	var player = players.get(player_id, null)
	if not players: return false
	player.update_meeples(meeples)
	return true

func set_points_for_player(points : int, player_id : String) -> bool:
	var player = players.get(player_id, null)
	if not players: return false
	player.update_meeples(points)
	return true

func set_current_displayed_card(id : int) -> void:
	display.set_card(id)

func _on_meeple_options_index_hovered(index : int) -> void:
	index_hovered_repass.emit(index)

func _on_meeple_options_index_selected(index : int) -> void:
	index_selected_repass.emit(index)

func hide_meeple_selector() -> void:
	mep_opt.hide()

func show_meeple_selector() -> void:
	mep_opt.show()

func configure_meeple_selector(valids : Array[int]) -> void:
	mep_opt.configure(valids)
