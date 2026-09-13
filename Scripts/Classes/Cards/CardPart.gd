@abstract class_name CardPart extends Resource

enum TYPES {CITY, MONASTERY, ROAD, PAST}

var base_card    : CardStructure = null
var extra_points : bool = false

var outer_direction   : Vector2i
var outer_connection  : CardPart        = null
var inner_left        : CardPart
var inner_right       : CardPart

var occupier = null

# static method, receives a list of CardParts and connects them in a line
# setting inner left and inner right atributes
static func connect_inner(card_parts : Array[CardPart]):
	for i in range(len(card_parts)):
		var card_part : CardPart = card_parts[i]
		var previous  : CardPart = card_parts[i-1] if i > 0 else null
		var next      : CardPart = card_parts[i+1] if i < len(card_parts) - 1 else null
		if previous:
			card_part.inner_left = previous
		if next:
			card_part.inner_right = next

func connect_outer(card : CardPart):
	outer_connection = card
	card.outer_connection = self

func get_connections() -> Array[CardPart]:
	var connections : Array[CardPart] = []
	if inner_left       : connections.append(inner_left)
	if inner_right      : connections.append(inner_right)
	if outer_connection : connections.append(outer_connection)
	return connections

func inner_connects_to(card_part : CardPart) -> bool:
	if self == card_part:
		return true
	if inner_right and inner_search(card_part, true):
		return true
	if inner_left and inner_search(card_part, false):
		return true
	return false

func inner_search(card_part : CardPart, search_right : bool = true) -> bool:
	if card_part == self:
		return true
	if search_right and inner_right:
		return inner_right.inner_search(card_part, search_right)
	elif not search_right and inner_left:
		return inner_left.inner_search(card_part, search_right)
	return false


"------------------------------ FOR OVERRIDING ------------------------------"

@abstract func can_receive_meeple() -> bool

@abstract func get_type() -> TYPES

@abstract func calculate_points() -> int

@abstract func is_closed() -> bool

@abstract func update() -> void
