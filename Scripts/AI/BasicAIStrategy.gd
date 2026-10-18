class_name BasicAIStrategy
extends AIStrategy

## IA Nível Básico - Decisão Gulosa Simples
## Prioriza colocar a peça na primeira posição válida e aloca meeple sempre que possível.

func choose_card_placement(_card_id: int, valid_positions: Dictionary[Vector2i, Array], _board: Board) -> Dictionary:
	if valid_positions.is_empty():
		return {}

	# Seleciona uma posição e rotação válidas aleatórias
	var positions: Array = valid_positions.keys()
	var selected_pos: Vector2i = positions.pick_random()
	var rotations: Array = valid_positions[selected_pos]
	var selected_rot: CardStructure.CARDROTATION = rotations.pick_random()

	return {"pos": selected_pos, "rotation": selected_rot}


func choose_meeple_placement(player: Player, _card: CardStructure, valid_slots: Array[int], _board: Board) -> int:
	if valid_slots.is_empty() or not player.has_available_meeple():
		return CardStructure.SKIP_SLOT_INDEX

	# Filtra os slots válidos ignorando a opção de pular
	var real_slots: Array[int] = []
	for slot in valid_slots:
		if slot != CardStructure.SKIP_SLOT_INDEX:
			real_slots.append(slot)

	if real_slots.is_empty():
		return CardStructure.SKIP_SLOT_INDEX

	return real_slots.pick_random()