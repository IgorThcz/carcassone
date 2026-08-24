class_name CardPart extends Resource

enum TYPES {CITY, MONASTERY, ROAD, PAST, CROSS}

const letter_to_type : Dictionary[String, TYPES] = {
	"C" : TYPES.CITY,
	"M" : TYPES.MONASTERY,
	"R" : TYPES.ROAD,
	"P" : TYPES.PAST,
	"X" : TYPES.CROSS
}

var base_card    : CardStruture = null
var type         : TYPES = TYPES.CITY
var extra_points : bool = false

var outer_direction   : Vector2i
var outer_connection  : CardPart        = null
var inner_connections : Array[CardPart] = []

func _init(letter : String):
	type = letter_to_type.get(letter, "P")

func connect_inner(card_parts : Array):
	for card_part in card_parts:
		if card_part is CardPart:
			inner_connections.append(card_part)

func connect_outer(card : CardPart):
	outer_connection = card
	card.outer_connection = self

func get_size():
	pass

func is_complete():
	pass

func connects_to(part : CardPart) -> bool:
	if inner_connections.has(part):
		return true
	if outer_connection == part:
		return true
	return false

func get_connections() -> Array[CardPart]:
	var connections : Array[CardPart] = inner_connections.duplicate()
	connections.append(outer_connection)
	return connections
