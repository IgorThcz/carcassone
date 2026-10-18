class_name Road extends CardPart

func get_type() -> TYPES:
	return CardPart.TYPES.ROAD

func get_meeple_type() -> Meeple.MEEPLETYPE:
	return Meeple.MEEPLETYPE.BANDIT

func is_closed() -> bool:
	var region = get_region()
	for part in region:
		# Se uma ponta de borda não possui conexão externa, a estrada está aberta
		if part.base_card and part.base_card.sides.has(part):
			if part.outer_connection == null:
				return false
	return true

func calculate_points() -> int:
	var region = get_region()
	var unique_cards: Array[CardStructure] = []
	for part in region:
		if part.base_card and not unique_cards.has(part.base_card):
			unique_cards.append(part.base_card)
	# 1 ponto por peça constitutiva da estrada
	return unique_cards.size()

func update() -> void:
	pass