class_name Deck
extends RefCounted

## Gerenciador da Pilha de Compras e Descarte 

const BASE_CARD_COUNTS: Dictionary[int, int] = {
	0: 4,  1: 4,  2: 4,  3: 4,  4: 4,
	5: 4,  6: 4,  7: 4,  8: 4,  9: 4,
	10: 4, 11: 4, 12: 4, 13: 4, 14: 4,
	15: 4, 16: 4, 17: 4, 18: 4, 19: 4,
	20: 4, 21: 4, 22: 4, 23: 4, 24: 4
}

var _cards: Array[int] = []
var _discard_pile: Array[int] = []


func _init(target_size: int = 71) -> void:
	_initialize_deck(target_size)


## Monta e embaralha o baralho escalando para qualquer tamanho solicitado
func _initialize_deck(target_size: int) -> void:
	_cards.clear()
	_discard_pile.clear()
	
	var full_pool: Array[int] = []
	for card_id: int in BASE_CARD_COUNTS.keys():
		var count: int = BASE_CARD_COUNTS[card_id]
		for i in range(count):
			full_pool.append(card_id)
			
	full_pool.shuffle()
	
	# Preenche o baralho repetindo o pool até atingir exatamente target_size 
	while _cards.size() < target_size:
		for card_id in full_pool:
			if _cards.size() >= target_size:
				break
			_cards.append(card_id)
			
	_cards.shuffle()
	print("[Deck] Baralho inicializado com %d peças." % _cards.size())


## Saca o ID da próxima carta da pilha
func draw_card_id() -> int:
	if is_empty():
		return -1
	return _cards.pop_back()


## Adiciona uma carta não jogável à pilha de descartes
func discard_card(card_id: int) -> void:
	_discard_pile.append(card_id)
	print("[Deck] Carta ID %d descartada. Total no descarte: %d" % [card_id, _discard_pile.size()])


func is_empty() -> bool:
	return _cards.is_empty()


func has_cards() -> bool:
	return not _cards.is_empty()


func get_remaining_count() -> int:
	return _cards.size()


func get_discarded_count() -> int:
	return _discard_pile.size()