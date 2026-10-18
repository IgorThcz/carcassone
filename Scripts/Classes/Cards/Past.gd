class_name Past extends CardPart

func get_type() -> TYPES:
	return CardPart.TYPES.PAST

func get_meeple_type() -> Meeple.MEEPLETYPE:
	return Meeple.MEEPLETYPE.FARMER

## Campos nunca se fecham durante a partida e só pontuam no final
func is_closed() -> bool:
	return false

## Calcula a pontuação final do campo (3 pontos por cidade concluída em contato)
func calculate_points() -> int:
	var field_region: Array[CardPart] = get_region()
	var counted_city_parts: Array[CardPart] = []
	var completed_cities_count: int = 0

	for past_part in field_region:
		var card: CardStructure = past_part.base_card
		if card == null:
			continue

		# Varre os slots de borda da carta onde esta parte do campo está presente
		for i in range(12):
			if card.sides.size() <= i or card.sides[i] != past_part:
				continue

			# Identifica os slots vizinhos no anel de 12 posições da mesma peça
			var prev_idx: int = (i - 1 + 12) % 12
			var next_idx: int = (i + 1) % 12

			var neighbor_candidates: Array[CardPart] = []
			if card.sides.size() > prev_idx and card.sides[prev_idx]:
				neighbor_candidates.append(card.sides[prev_idx])
			if card.sides.size() > next_idx and card.sides[next_idx]:
				neighbor_candidates.append(card.sides[next_idx])

			# Verifica se algum slot vizinho é uma Cidade
			for neighbor in neighbor_candidates:
				if neighbor.get_type() == CardPart.TYPES.CITY:
					# Ignora se essa cidade já foi contabilizada
					if counted_city_parts.has(neighbor):
						continue

					# Se a cidade estiver concluída, contabiliza e registra toda a sua região
					if neighbor.is_closed():
						completed_cities_count += 1
						var city_region: Array[CardPart] = neighbor.get_region()
						for c_part in city_region:
							if not counted_city_parts.has(c_part):
								counted_city_parts.append(c_part)

	return completed_cities_count * 3

func update() -> void:
	pass