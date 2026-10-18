class_name Board
extends RefCounted

## Responsável por armazenar as peças jogadas, calcular adjacências,
## conectar lados compatíveis e gerenciar o estado topológico do jogo.

const IDIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT
]

# Grade do tabuleiro: Vector2i -> CardStructure
var _grid: Dictionary[Vector2i, CardStructure] = {}

# Lista de posições vazias adjacentes a pelo menos uma peça do tabuleiro
var _adjacents: Array[Vector2i] = []


## Posiciona a peça inicial padrão em Vector2i.ZERO 
func place_initial_tile(initial_card_id: int) -> CardStructure:
	var start_card: CardStructure = Catalogue.get_structure(initial_card_id)
	if not start_card:
		push_error("[Board] Falha ao carregar peça inicial ID %d do Catalogue!" % initial_card_id)
		return null

	_grid[Vector2i.ZERO] = start_card
	start_card.position = Vector2i.ZERO
	start_card.board = self
	_update_adjacents(Vector2i.ZERO)
	return start_card


## Verifica se uma carta pode ser posicionada na coordenada informada
func can_place_card(pos: Vector2i, card: CardStructure, p_rotation: int = 0) -> bool:
	if card == null:
		return false

	if card.has_method("set_rotation"):
		card.set_rotation(p_rotation)
	elif "rotation" in card:
		card.set("rotation", p_rotation)

	return validate_card_placement(pos, card)


## Posiciona uma carta na coordenada, conecta lados e avalia fechamento de estruturas
func place_card(pos: Vector2i, card: CardStructure, p_rotation: int = 0) -> bool:
	if card == null:
		return false

	if card.has_method("set_rotation"):
		card.set_rotation(p_rotation)
	elif "rotation" in card:
		card.set("rotation", p_rotation)

	if not validate_card_placement(pos, card):
		return false

	# Conecta os lados externos com os vizinhos existentes
	for dir in IDIRECTIONS:
		var target: Vector2i = pos + dir
		if _grid.has(target):
			var neighbor: CardStructure = _grid[target]
			card.connect_side(neighbor, dir)

	_grid[pos] = card
	card.position = pos
	card.board = self
	_update_adjacents(pos)
	
	# Avalia se a jogada concluiu estruturas no tabuleiro
	evaluate_turn_closures(card)
	return true


## Valida se a posição e rotação da carta respeitam as regras de encaixe de borda
func validate_card_placement(pos: Vector2i, card: CardStructure) -> bool:
	if _grid.has(pos) or card == null:
		return false

	if _grid.is_empty():
		return true

	var has_neighbor: bool = false

	for dir in IDIRECTIONS:
		var neighbor_pos: Vector2i = pos + dir
		if _grid.has(neighbor_pos):
			has_neighbor = true
			var neighbor_card: CardStructure = _grid[neighbor_pos]
			if not card.is_side_compatible(neighbor_card, dir):
				return false

	return has_neighbor


## Avalia estruturas concluídas após a jogada e devolve meeples aos ocupantes
func evaluate_turn_closures(placed_card: CardStructure) -> void:
	var evaluated_parts: Array[CardPart] = []
	var parts_to_check: Array[CardPart] = []
	
	parts_to_check.append_array(placed_card.sides)
	if placed_card.middle:
		parts_to_check.append(placed_card.middle)

	# Inclui mosteiros vizinhos na grade 3x3 que possam ter sido concluídos por esta jogada
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var check_pos: Vector2i = placed_card.position + Vector2i(dx, dy)
			if _grid.has(check_pos):
				var neighbor_card: CardStructure = _grid[check_pos]
				if neighbor_card.middle and neighbor_card.middle.get_type() == CardPart.TYPES.MONASTERY:
					if not parts_to_check.has(neighbor_card.middle):
						parts_to_check.append(neighbor_card.middle)

	for part in parts_to_check:
		if evaluated_parts.has(part):
			continue

		var region: Array[CardPart] = part.get_region()
		for p in region:
			evaluated_parts.append(p)

		# Consulta o estado diretamente no CardPart via polimorfismo
		if part.is_closed():
			var points: int = part.calculate_points()
			
			# Coleta os ocupantes da região
			var occupiers: Array[Player] = []
			for p in region:
				if p.occupier:
					occupiers.append(p.occupier)

			if not occupiers.is_empty():
				# Atribui pontos aos jogadores com maioria de meeples na estrutura
				var dominant_players: Array[Player] = _get_dominant_players(occupiers)
				for player in dominant_players:
					player.add_score(points)
					print("[Board] Estrutura concluída! %d pontos concedidos a %s." % [points, player.player_name])

				# Devolve todos os meeples presentes na estrutura para suas respectivas reservas
				for p in region:
					if p.occupier:
						p.occupier.return_meeple()
						p.occupier = null


## Calcula a pontuação final de encerramento para estruturas incompletas
func calculate_final_scores(players: Array[Player]) -> Dictionary:
	var evaluated_parts: Array[CardPart] = []

	for pos in _grid.keys():
		var card: CardStructure = _grid[pos]
		var card_parts: Array[CardPart] = []
		card_parts.append_array(card.sides)
		if card.middle:
			card_parts.append(card.middle)

		for part in card_parts:
			if evaluated_parts.has(part):
				continue

			var region: Array[CardPart] = part.get_region()
			for p in region:
				evaluated_parts.append(p)

			# Estruturas incompletas ao final da partida que contenham meeples
			if not part.is_closed():
				var occupiers: Array[Player] = []
				for p in region:
					if p.occupier:
						occupiers.append(p.occupier)

				if not occupiers.is_empty():
					var points: int = part.calculate_points()
					var dominant_players: Array[Player] = _get_dominant_players(occupiers)
					for player in dominant_players:
						player.add_score(points)
						print("[Board] Fim de jogo: +%d pontos para %s (Estrutura incompleta)." % [points, player.player_name])

	var final_scores: Dictionary = {}
	for player in players:
		final_scores[player] = player.score
	return final_scores


## Retorna posições e rotações válidas para uma carta
func get_valid_card_positions(card: CardStructure) -> Dictionary[Vector2i, Array]:
	var valids: Dictionary[Vector2i, Array] = {}
	if card == null:
		return valids

	for pos in _adjacents:
		var valid_rotations_at_pos: Array = []
		for rotation in CardStructure.CARDROTATION.values():
			if card.has_method("set_rotation"):
				card.set_rotation(rotation)
			elif "rotation" in card:
				card.set("rotation", rotation)

			if validate_card_placement(pos, card):
				valid_rotations_at_pos.append(rotation)

		if not valid_rotations_at_pos.is_empty():
			valids[pos] = valid_rotations_at_pos

	return valids


## Determina a maioria de meeples em uma estrutura (desempate do Carcassonne)
func _get_dominant_players(occupiers: Array[Player]) -> Array[Player]:
	var counts: Dictionary = {}
	var max_count: int = 0

	for p in occupiers:
		counts[p] = counts.get(p, 0) + 1
		if counts[p] > max_count:
			max_count = counts[p]

	var dominant: Array[Player] = []
	for p in counts.keys():
		if counts[p] == max_count:
			dominant.append(p)

	return dominant


## Atualiza a lista de coordenadas adjacentes disponíveis para jogada
func _update_adjacents(placed_pos: Vector2i) -> void:
	_adjacents.erase(placed_pos)
	for dir in IDIRECTIONS:
		var neighbor_pos: Vector2i = placed_pos + dir
		if not _grid.has(neighbor_pos) and not _adjacents.has(neighbor_pos):
			_adjacents.append(neighbor_pos)


func has_card_at(pos: Vector2i) -> bool:
	return _grid.has(pos)


func get_card_at(pos: Vector2i) -> CardStructure:
	return _grid.get(pos, null)


func get_grid() -> Dictionary[Vector2i, CardStructure]:
	return _grid.duplicate()