class_name AIStrategy
extends RefCounted

## Estratégia Base de Decisão da IA 
## Define o contrato para cálculo de jogadas de peças e alocação de meeples.

## Escolhe a melhor posição e rotação dentre as opções válidas
## Retorna um Dicionário: {"pos": Vector2i, "rotation": CardStructure.CARDROTATION}
func choose_card_placement(_card_id: int, valid_positions: Dictionary[Vector2i, Array], _board: Board) -> Dictionary:
	if valid_positions.is_empty():
		return {}
	
	# Comportamento padrão fallback: pega a primeira posição e rotação disponível
	var first_pos: Vector2i = valid_positions.keys()[0]
	var first_rot: int = valid_positions[first_pos][0]
	return {"pos": first_pos, "rotation": first_rot}


## Escolhe qual slot alocar o meeple (-1 para pular)
func choose_meeple_placement(_player: Player, _card: CardStructure, valid_slots: Array[int], _board: Board) -> int:
	if valid_slots.is_empty():
		return -1
	return -1