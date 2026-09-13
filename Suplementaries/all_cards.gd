extends Node3D

func _ready():
	for i in range(24):
		var index : int = i + 1
		var skin : AutoSkin = Catalogue.get_skin(index)
		add_child(skin)
		skin.position.x = i * 9
