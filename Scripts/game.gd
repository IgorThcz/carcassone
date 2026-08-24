extends Node3D

func _ready():
	var num = 1
	print("\n", Catalogue.models, "\n")
	while true:
		if not Catalogue.get_model(num):
			print("break!")
			break
		print("Card 1 --------- ----------")
		var node : Card = Card.new(num)
		add_child(node)
		node.global_position.x += num * 10
		num += 1
	print(num, " cards created")
