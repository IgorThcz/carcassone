class_name CardStructure extends Resource

enum CARDROTATION {
	UP = 0,
	RIGHT = 1,
	DOWN = 2,
	LEFT = 3
}

static var letter_to_type : Dictionary = {
	"C" : City,
	"M" : Monastery,
	"R" : Road,
	"P" : Past,
}

var position  : Vector2i
var rotation  : CARDROTATION = CARDROTATION.UP
# first position of top side array
var top_index : int = 0

var sides : Array[CardPart] = []

var middle : CardPart = null

var has_meeple = false

func build(json_entry : Array):
	# auxiliar structures
	var indexes   : Array[Array] = []
	var groups    : Dictionary[String, Array] = {}
	var gr_id     : Dictionary[CardPart, String] = {}
	"CREATE CARD PARTS"
	var stri    : String = json_entry[4] # alone element
	# create card part with type identified from letter
	var part : CardPart = null
	# if is not in dict, stay null for not connecting points
	# else add middle part
	if letter_to_type.has(stri[0]):
		part = letter_to_type[stri[0]].new() # letter
		# if has "+", grants extra points
		if stri[-1] == "+": # last character
			part.extra_points = true
		# add to middle
		middle = part
		# anotate group
		stri = stri.replace("+", "")
		gr_id.set(part, stri)
		if groups.has(stri):
			groups.get(stri).append(part)
		else:
			var array : Array[CardPart] = [part]
			groups.set(stri, array)
	# anotate indexes
	for i in range(4):
		for j in range(3):
			stri = json_entry[i][j]
			# create card part with type identified from letter
			part = letter_to_type[stri[0]].new() as CardPart # letter
			# if has "+", grants extra points
			if stri[-1] == "+": # last character
				part.extra_points = true
			# add to sides
			sides.append(part)
			# anotate group
			stri = stri.replace("+", "")
			gr_id.set(part, stri)
			if groups.has(stri):
				groups.get(stri).append(part)
			else:
				var array : Array[CardPart] = [part]
				groups.set(stri, array)
			# anotate indexes
			indexes.append([i, j])
	"ASSIGN CONNECTIONS"
	for group in groups.keys():
		var array : Array[CardPart] = groups.get(group)
		if len(array) > 1:
			CardPart.connect_inner(array)

func set_rotation(rot : CARDROTATION) -> void:
	rotation = rot

func get_part(index : int, ciclic_below_zero : bool = false) -> CardPart:
	if ciclic_below_zero:
		index = posmod(index, 12)
	if index < 0:
		return middle
	return sides.get((top_index + (3 * rotation) + index) % 12)

func can_receive_meeple_at(index : int):
	if has_meeple: return false
	return get_part(index).can_receive_meeple

func place_meeple(index : int, player):
	if not has_meeple:
		get_part(index).occupier = player
		has_meeple = true

func update_regions():
	for part in sides:
		part.update()
	if middle:
		middle.update()

func monastery_update():
	if middle and middle.get_type() == CardPart.TYPES.MONASTERY:
		middle.update()

func is_side_compatible(neighbor_card : CardStructure, dir : Vector2i) -> bool:
	var dir_index          : int = _vector_to_rotation(dir)
	var opposite_dir_index : int = _vector_to_rotation(-dir)
	for j in range(3):
		var own_part      : CardPart = get_part(3 * dir_index + j)
		# invertido: a ponta "j" de um lado encosta na ponta "2-j" do lado oposto
		var neighbor_part : CardPart = neighbor_card.get_part(3 * opposite_dir_index + (2 - j))
		if own_part.get_type() != neighbor_part.get_type():
			return false
	return true

func connect_side(neighbor_card : CardStructure, dir : Vector2i) -> void:
	var dir_index          : int = _vector_to_rotation(dir)
	var opposite_dir_index : int = _vector_to_rotation(-dir)
	for j in range(3):
		var own_part      : CardPart = get_part(3 * dir_index + j)
		var neighbor_part : CardPart = neighbor_card.get_part(3 * opposite_dir_index + (2 - j))
		if own_part.get_type() == neighbor_part.get_type():
			own_part.connect_outer(neighbor_part)

func _vector_to_rotation(dir : Vector2i) -> int:
	match dir:
		Vector2i(0, -1): return CARDROTATION.UP
		Vector2i(1, 0):  return CARDROTATION.RIGHT
		Vector2i(0, 1):  return CARDROTATION.DOWN
		Vector2i(-1, 0): return CARDROTATION.LEFT
		_:
			push_error("is_side_compatible: direção inválida %s" % dir)
			return CARDROTATION.UP
