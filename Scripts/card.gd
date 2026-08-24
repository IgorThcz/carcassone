@tool class_name Card extends Node3D

@export_range(1, 24, 1) var card_template : int = 1:
	set(value):
		card_template = value
		reset_to_template()

var structure : CardStruture
var skin      : Node3D = null

func _init(card_model):
	card_template = card_model
	print("_init completed")

func _ready():
	reset_to_template()
	print("_ready completed")

# resets all card data to basic card with template number defined
func reset_to_template():
	# reset structure
	print("requested structure for catalogue")
	structure = Catalogue.get_structure(card_template)
	# reset skin
	if skin: skin.queue_free()
	print("requested skin for catalogue")
	skin = Catalogue.get_skin(card_template)
	add_child(skin)
	# reset rotation
	rotation.y = 0

func rotate_90(times : int):
	# visual rotation
	times = times % 4
	rotation_degrees.y += 90 * times
	rotation_degrees.y = int(rotation_degrees.y) % 360
	# logical rotation
	structure.set_rotation(rotation_degrees.y)












""
