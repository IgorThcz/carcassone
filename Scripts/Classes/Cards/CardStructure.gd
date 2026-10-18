class_name CardStructure extends Resource

enum CARDROTATION {
	UP = 0,
	RIGHT = 1,
	DOWN = 2,
	LEFT = 3
}

const SKIP_SLOT_INDEX: int = -1

static var letter_to_type: Dictionary = {
	"C": City,
	"M": Monastery,
	"R": Road,
	"P": Past,
}

var position: Vector2i
var rotation: CARDROTATION = CARDROTATION.UP

# Primeiro índice do lado superior
var top_index: int = 0

# Os 12 nós de borda da carta
var sides: Array[CardPart] = []

# Nó central (para Mosteiro ou cruzamento)
var middle: CardPart = null

# Indica se um meeple já foi posicionado nesta carta na jogada atual
var has_meeple: bool = false

# Referência ao Board que contém esta carta
var board = null 

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
		part.base_card = self
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
			part.base_card = self
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

func set_rotation(rot: CARDROTATION) -> void:
	rotation = rot


## Retorna o nó CardPart correspondente ao índice solicitado (0..11 para lados, 12 para centro)
func get_part(index: int, ciclic_below_zero: bool = false) -> CardPart:
	if index == 12:
		return middle
	if ciclic_below_zero:
		index = posmod(index, 12)
	if index < 0:
		return middle
	return sides.get((top_index + (3 * rotation) + index) % 12)


## Retorna a lista de índices de slots válidos para receber meeple nesta carta
func get_valid_meeple_slots(player) -> Array[int]:
	var valids: Array[int] = [SKIP_SLOT_INDEX]
	
	if player == null or has_meeple:
		return valids
		
	if player.has_method("has_available_meeple") and not player.has_available_meeple():
		return valids

	# Avalia os 12 slots das bordas
	for i in range(12):
		if can_receive_meeple_at(i):
			valids.append(i)

	# Avalia o slot central se a carta possuir 'middle'
	if middle and can_receive_meeple_at(12):
		valids.append(12)

	return valids


## Valida se um slot específico pode receber um meeple
func can_receive_meeple_at(index: int) -> bool:
	if has_meeple or index == SKIP_SLOT_INDEX:
		return false

	var part: CardPart = get_part(index)
	return part != null and part.can_receive_meeple()


## Aloca o meeple no slot escolhido, consome da reserva do jogador e atualiza o estado
func place_meeple(index: int, player) -> bool:
	if index == SKIP_SLOT_INDEX:
		return true # Opção de não colocar meeple no turno

	if has_meeple or player == null:
		return false

	if player.has_method("has_available_meeple") and not player.has_available_meeple():
		return false

	var part: CardPart = get_part(index)
	if part and part.can_receive_meeple():
		part.occupier = player
		has_meeple = true
		if player.has_method("use_meeple"):
			player.use_meeple()
		return true

	return false


func update_regions() -> void:
	for part in sides:
		part.update()
	if middle:
		middle.update()


func monastery_update() -> void:
	if middle and middle.get_type() == CardPart.TYPES.MONASTERY:
		middle.update()


## Verifica compatibilidade de borda com uma carta vizinha
func is_side_compatible(neighbor_card: CardStructure, dir: Vector2i) -> bool:
	var dir_index: int = _vector_to_rotation(dir)
	var opposite_dir_index: int = _vector_to_rotation(-dir)
	for j in range(3):
		var own_part: CardPart = get_part(3 * dir_index + j)
		var neighbor_part: CardPart = neighbor_card.get_part(3 * opposite_dir_index + (2 - j))
		if own_part.get_type() != neighbor_part.get_type():
			return false
	return true


## Conecta os nós de borda externamente com a carta vizinha (bidirecional)
func connect_side(neighbor_card: CardStructure, dir: Vector2i) -> void:
	var dir_index: int = _vector_to_rotation(dir)
	var opposite_dir_index: int = _vector_to_rotation(-dir)
	for j in range(3):
		var own_part: CardPart = get_part(3 * dir_index + j)
		var neighbor_part: CardPart = neighbor_card.get_part(3 * opposite_dir_index + (2 - j))
		if own_part.get_type() == neighbor_part.get_type():
			own_part.connect_outer(neighbor_part)
			neighbor_part.connect_outer(own_part)


func _vector_to_rotation(dir: Vector2i) -> int:
	match dir:
		Vector2i(0, -1): return CARDROTATION.UP
		Vector2i(1, 0):  return CARDROTATION.RIGHT
		Vector2i(0, 1):  return CARDROTATION.DOWN
		Vector2i(-1, 0): return CARDROTATION.LEFT
		_:
			push_error("is_side_compatible: direção inválida %s" % dir)
			return CARDROTATION.UP