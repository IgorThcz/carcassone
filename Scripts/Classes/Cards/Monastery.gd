class_name Monastery extends CardPart

const SURROUNDING_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1,  0),                  Vector2i(1,  0),
	Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1)
]

func get_type() -> TYPES:
	return CardPart.TYPES.MONASTERY

func get_meeple_type() -> Meeple.MEEPLETYPE:
	return Meeple.MEEPLETYPE.PRIEST

func is_closed() -> bool:
	return _count_surrounding_cards() == 8

func calculate_points() -> int:
	if base_card == null:
		return 0
	return 1 + _count_surrounding_cards()

func _count_surrounding_cards() -> int:
	if base_card == null:
		return 0

	var count: int = 0
	var board_grid: Dictionary = _get_board_grid()

	if board_grid.is_empty():
		return 0

	for offset in SURROUNDING_OFFSETS:
		var target_pos: Vector2i = base_card.position + offset
		if board_grid.has(target_pos) and board_grid[target_pos] != null:
			count += 1

	return count

func _get_board_grid() -> Dictionary:
	var target_board = null
	
	# 1. Tenta obter o tabuleiro diretamente da carta
	if base_card and "board" in base_card and base_card.board != null:
		target_board = base_card.board
	# 2. Fallback para a lógica global do GameManager
	elif GameManager.active_logic:
		if "_board" in GameManager.active_logic and GameManager.active_logic._board != null:
			target_board = GameManager.active_logic._board
		elif "board" in GameManager.active_logic and GameManager.active_logic.board != null:
			target_board = GameManager.active_logic.board

	if target_board != null:
		if "placed_cards" in target_board:
			return target_board.placed_cards
		elif "board" in target_board:
			return target_board.board
		elif "_grid" in target_board:
			return target_board._grid

	return {}

func update() -> void:
	pass