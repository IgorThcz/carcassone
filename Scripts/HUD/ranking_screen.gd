extends ColorRect

const MENU_PACKED : PackedScene = preload("uid://7lxb01yfn7c6")

@onready var names : Array[RichTextLabel] = [
	$MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/first/VBoxContainer/player,
	$MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/second/VBoxContainer/player,
	$MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/third/VBoxContainer/player
]

@onready var scores : Array[RichTextLabel] = [
	$MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/first/VBoxContainer/points,
	$MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/second/VBoxContainer/points,
	$MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/third/VBoxContainer/points
]

@onready var panels : Array[Panel] = [
	$MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/first,
	$MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/second,
	$MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/third
]

func set_rankings(players : Array[Player]):
	var rank : Array[Player] = players.duplicate()
	rank.sort_custom(func(a, b): return a.score > b.score)
	# percorre os 3 primeiros (se houver) e adiciona ao placar
	for i in range(3):
		if rank.size() >= i + 1:
			var player : Player = rank.get(i)
			names.get(i).text = player.player_name
			scores.get(i).text = str(player.score)
		else: panels.get(i).hide()
	show()

func _on_button_pressed():
	get_tree().change_scene_to_packed(MENU_PACKED)
