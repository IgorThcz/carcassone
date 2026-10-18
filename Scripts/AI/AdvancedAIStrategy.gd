class_name AdvancedAIStrategy
extends AIStrategy

## IA Nível Avançado - Avaliação Heurística
## Analisa potencial de pontuação, fecha mosteiros e gerencia a reserva de meeples.

func choose_card_placement(card_id: int, valid_positions: Dictionary[Vector2i, Array], board: Board) -> Dictionary:
	if valid_positions.is_empty():
		return {}

	var card: CardStructure = Catalogue.get_structure(card_id)
	var best_pos: Vector2i = valid_positions.keys()[0]
	var best_rot: CardStructure.CARDROTATION = valid_positions[best_pos][0]
	var max_score: int = -1

	# Avalia heuristicamente cada combinação (posição + rotação)
	for pos in valid_positions.keys():
		for rot in valid_positions[pos]:
			var current_score: int = _evaluate_placement_heuristic(card, pos, rot, board)
			if current_score > max_score:
				max_score = current_score
				best_pos = pos
				best_rot = rot

	return {"pos": best_pos, "rotation": best_rot}


func choose_meeple_placement(player: Player, card: CardStructure, valid_slots: Array[int], _board: Board) -> int:
	if valid_slots.is_empty() or not player.has_available_meeple():
		return CardStructure.SKIP_SLOT_INDEX

	# Gestão de Reserva: Se for o ÚLTIMO meeple, só coloca se a feição valer a pena
	var is_last_meeple: bool = (player.available_meeples == 1)

	var best_slot: int = CardStructure.SKIP_SLOT_INDEX
	var max_slot_value: int = -1

	for slot in valid_slots:
		if slot == CardStructure.SKIP_SLOT_INDEX:
			continue

		var slot_value: int = _evaluate_slot_value(card, slot)

		if is_last_meeple and slot_value < 5:
			continue # Economiza o último meeple para jogadas decisivas

		if slot_value > max_slot_value:
			max_slot_value = slot_value
			best_slot = slot

	return best_slot


## Calcula o valor heurístico de posicionamento da peça no tabuleiro
func _evaluate_placement_heuristic(_card: CardStructure, pos: Vector2i, _rot: int, board: Board) -> int:
	var score: int = 0
	
	# Bônus se a posição ajuda a fechar a vizinhança de Mosteiros ao redor
	if board != null:
		for x in range(-1, 2):
			for y in range(-1, 2):
				if x == 0 and y == 0:
					continue
				var neighbor: CardStructure = board.get_card_at(pos + Vector2i(x, y))
				if neighbor and _card_has_monastery(neighbor):
					score += 3 # Prioriza cercar mosteiros

	return score


## Calcula o valor estratégico de um slot consultando o tipo polimórfico do CardPart
func _evaluate_slot_value(card: CardStructure, slot_index: int) -> int:
	if card == null:
		return 0

	var part: CardPart = card.get_part(slot_index)
	if part == null:
		return 0

	# Atribui peso estratégico com base no tipo real da feição
	match part.get_type():
		CardPart.TYPES.MONASTERY:
			return 10
		CardPart.TYPES.CITY:
			return 7
		CardPart.TYPES.ROAD:
			return 5
		CardPart.TYPES.PAST:
			return 2
		_:
			return 0


## Verifica polimorficamente se a carta possui um mosteiro no centro
func _card_has_monastery(p_card: CardStructure) -> bool:
	if p_card and p_card.middle:
		return p_card.middle.get_type() == CardPart.TYPES.MONASTERY
	return false