class_name CardStruture extends Resource

var rotation  : int = 0 # (0, 1, 2, 3)
# first position of top side array
var top_index : int = 0

var sides : Array[CardPart] = []

var middle : CardPart

func build(json_entry : Array):
	# auxiliar structures
	var indexes   : Array[Array] = []
	var groups    : Dictionary[String, Array] = {}
	var gr_id     : Dictionary[CardPart, String] = {}
	"CREATE CARD PARTS"
	var stri    : String = json_entry[4] # alone element
	# create card part with type identified from letter
	var part : CardPart = CardPart.new(stri[0]) # letter
	# if has "+", grants extra points
	if stri[-1] == "+": # last character
		part.extra_points = true
	# add to sides
	middle = part
	# anotate group
	stri = stri.replace("+", "")
	gr_id.set(part, stri)
	if groups.has(stri):
		groups.get(stri).append(part)
	else:
		groups.set(stri, [part])
	# anotate indexes
	for i in range(4):
		for j in range(3):
			stri = json_entry[i][j]
			# create card part with type identified from letter
			part = CardPart.new(stri[0]) # letter
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
				groups.set(stri, [part])
			# anotate indexes
			indexes.append([i, j])
	"ASSIGN CONNECTIONS"
	middle.connect_inner(groups.get(gr_id.get(middle)))
	for k in range(len(sides)):
		var card_part : CardPart = sides.get(k)
		card_part.connect_inner(groups.get(gr_id.get(card_part)))

func set_rotation(degrees : float) -> void:
	rotation = int(degrees / 90)

func get_part(index : int, ciclic_below_zero : bool = false) -> CardPart:
	if ciclic_below_zero:
		index = posmod(index, 12)
	if index < 0:
		return middle
	return sides.get((top_index + (3 * rotation) + index) % 12)
