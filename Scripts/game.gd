extends Node3D

enum MPCONFIG {HOST, CLIENT, LOCAL}

var view3D : PackedScene = preload("res://Scenes/View3D.tscn")

@onready var logicinstance  : LogicInstance
@onready var visualinstance : VisualInstance

func _ready():
	# connect players
	var player1 : Player = IOPlayer.new("0", "Player 1", Color.BLUE)
	var player2 : Player = IOPlayer.new("1", "Player 1", Color.RED)
	var players : Array[Player] = [player1, player2]
	# set visual instance
	visualinstance = VisualInstance.new(players, view3D.instantiate())
	add_child(visualinstance)
	# only then, start scene
	logicinstance = LogicInstance.new(players)
	logicinstance.start_game()

func _process(delta):
	if Input.is_key_pressed(KEY_P):
		print(logicinstance.vgrid)
