class_name GameHUD extends Control

const PACKED_PLAYER_TRACKER : PackedScene = preload("uid://btvdexw4nwgkr")

@onready var sidebar      : Panel         = $MarginContainer/HBoxContainer/HBoxContainer/sidebar
@onready var vbox_sidebar : VBoxContainer = $MarginContainer/HBoxContainer/HBoxContainer/sidebar/VBsidebar

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
	vbox_sidebar.add_child(new)
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
