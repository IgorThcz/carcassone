class_name City extends CardPart

func get_type() -> TYPES:
	return CardPart.TYPES.CITY

func get_meeple_type() -> Meeple.MEEPLETYPE:
	return Meeple.MEEPLETYPE.KNIGHT

func is_closed() -> bool:
	var region = get_region()
	for part in region:
		if part.base_card and part.base_card.sides.has(part):
			if part.outer_connection == null:
				return false
	return true

func calculate_points() -> int:
	var region = get_region()
	var unique_cards: Array[CardStructure] = []
	var emblem_count: int = 0
	
	for part in region:
		if part.base_card and not unique_cards.has(part.base_card):
			unique_cards.append(part.base_card)
		
		# Soma 1 ponto extra para cada CardPart que representa um brasão na região
		if part.extra_points:
			emblem_count += 1

	var multiplier: int = 2 if is_closed() else 1
	return (unique_cards.size() * multiplier) + (emblem_count * multiplier)

func update() -> void:
	pass