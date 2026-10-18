@tool
class_name Card
extends Node3D

@export_range(1, 24, 1) var card_template: int = 1:
	set(value):
		card_template = value
		reset_to_template()

var structure: CardStructure
var skin: Node3D = null


func _init(card_model: int = 1) -> void:
	card_template = card_model


func _ready() -> void:
	reset_to_template()


## Reseta a estrutura de dados lógica e a skin 3D visual com base no modelo
func reset_to_template() -> void:
	structure = Catalogue.get_structure(card_template)
	
	if skin and is_instance_valid(skin):
		skin.queue_free()
		
	skin = Catalogue.get_skin(card_template)
	if skin:
		add_child(skin)
		
	rotation_degrees.y = 0
	if structure:
		structure.set_rotation(CardStructure.CARDROTATION.UP)


## Rotaciona a carta visualmente e sincroniza o enum lógico da CardStructure
func rotate_90(times: int = 1) -> void:
	times = posmod(times, 4)
	var new_degrees: int = posmod(int(rotation_degrees.y) + (90 * times), 360)
	rotation_degrees.y = new_degrees
	
	var rot_enum: CardStructure.CARDROTATION = _degrees_to_card_rotation(new_degrees)
	if structure:
		structure.set_rotation(rot_enum)


## Sincroniza diretamente a rotação visual e a lógica a partir do enum
func set_card_rotation(rot_enum: CardStructure.CARDROTATION) -> void:
	if structure:
		structure.set_rotation(rot_enum)
		
	match rot_enum:
		CardStructure.CARDROTATION.RIGHT:
			rotation_degrees.y = 90
		CardStructure.CARDROTATION.DOWN:
			rotation_degrees.y = 180
		CardStructure.CARDROTATION.LEFT:
			rotation_degrees.y = 270
		_:
			rotation_degrees.y = 0


## Converte graus angulares (0, 90, 180, 270) para o enum CardStructure.CARDROTATION
func _degrees_to_card_rotation(deg: int) -> CardStructure.CARDROTATION:
	match posmod(deg, 360):
		90:
			return CardStructure.CARDROTATION.RIGHT
		180:
			return CardStructure.CARDROTATION.DOWN
		270:
			return CardStructure.CARDROTATION.LEFT
		_:
			return CardStructure.CARDROTATION.UP