class_name LogicInstance extends RefCounted

"---------------------------------- SIGNALS ----------------------------------"

signal turn_passed(
	player: Player,
	card_id: int,
	valid_positions: Dictionary[Vector2i, Array]
	)
signal card_placement_denied(player: Player)
signal card_placed(
	player: Player,
	coords: Vector2i,
	rotation: CardStructure.CARDROTATION,
	meeple_valid_indexes: Array[int],
	card_id : int
	)
signal meeple_placed(player: Player, index: int)
signal meeple_placement_denied(player: Player)
signal game_finished(scores: Dictionary)
signal card_discarded(card_id: int)

"---------------------------------- VARIABLES ----------------------------------"

const IDIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT
]

# Tabela base de quantidades (ID -> Quantidade)
const BASE_CARD_COUNTS: Dictionary[int, int] = {
	0: 4,  1: 4,  2: 4,  3: 4,  4: 4,
	5: 4,  6: 4,  7: 4,  8: 4,  9: 4,
	10: 4, 11: 4, 12: 4, 13: 4, 14: 4,
	15: 4, 16: 4, 17: 4, 18: 4, 19: 4,
	20: 4, 21: 4, 22: 4, 23: 4, 24: 4
}

static var instance : LogicInstance

var players: Array[Player]
var initial_card_id: int = 0

var vgrid: Dictionary[Vector2i, CardStructure] = {}
var vadjacents: Array[Vector2i] = []
var deck: Array[int] = []

var current_player_index: int = 0
var current_drawn_card: CardStructure = null
var current_drawn_card_id: int = -1
var current_drawn_card_pos: Vector2i = Vector2i.ZERO

"---------------------------- INIT / READY / PROCESS ---------------------------"

func _init(p_players: Array[Player], p_initial_card_id: int = 1) -> void:
	players = p_players
	initial_card_id = p_initial_card_id
	instance = self
	current_drawn_card_id = p_initial_card_id
	
	# Conecta os sinais de entrada de todos os jogadores
	for player in players:
		if not player.card_placement_request.is_connected(_on_player_card_placement_request):
			player.card_placement_request.connect(_on_player_card_placement_request)
		if not player.meeple_placement_request.is_connected(_on_player_meeple_placement_request):
			player.meeple_placement_request.connect(_on_player_meeple_placement_request)
		# LogicInstance -> Player (broadcast de estado)
		turn_passed.connect(player.on_logic_instance_turn_passed)
		card_placed.connect(player.on_logic_instance_card_placed)
		meeple_placed.connect(player.on_logic_instance_meeple_placed)
		card_placement_denied.connect(player.on_logic_instance_card_placement_denied)
		meeple_placement_denied.connect(player.on_logic_instance_meeple_placement_denied)
		game_finished.connect(player.on_logic_instance_game_finished)
		card_discarded.connect(player.on_logic_instance_card_discarded)
	# Monta e embaralha o baralho
	for card_id: int in BASE_CARD_COUNTS.keys():
		var count: int = BASE_CARD_COUNTS[card_id]
		for i in range(count):
			deck.append(card_id)
	deck.shuffle()
	
	# Configura a carta inicial no centro (0,0)
	var start_card : CardStructure = Catalogue.get_structure(initial_card_id)
	vgrid[Vector2i.ZERO] = start_card
	start_card.position = Vector2i.ZERO
	update_adjacents(Vector2i.ZERO)

"-------------------------------- SIGNAL BOUND ---------------------------------"

func _on_player_card_placement_request(player: Player, pos: Vector2i, rot: CardStructure.CARDROTATION) -> void:
	if player != players[current_player_index]: 
		return
		
	current_drawn_card.set_rotation(rot)
	if place_current_card(pos):
		current_drawn_card_pos = pos
		var meeple_valids := get_valid_positions_for_meeple()
		card_placed.emit(player, pos, rot, meeple_valids, current_drawn_card_id)
		return
		
	card_placement_denied.emit(player)

func _on_player_meeple_placement_request(player: Player, index: int) -> void:
	if player != players[current_player_index]: 
		return
		
	if place_meeple_at_current_card(index):
		meeple_placed.emit(player, index)
		_resolve_scores_and_closures()
		pass_turn()
		return
		
	meeple_placement_denied.emit(player)

"------------------------------- CARD PLACEMENT --------------------------------"

func get_valid_card_positions() -> Dictionary[Vector2i, Array]:
	var valids: Dictionary[Vector2i, Array] = {} # Coord -> Array de CARDROTATION
	
	for position in vadjacents:
		var valid_rotations_at_pos: Array = []
		
		for rotation in CardStructure.CARDROTATION.values():
			current_drawn_card.set_rotation(rotation)
			if validate_card_placement(position):
				valid_rotations_at_pos.append(rotation)
				
		if not valid_rotations_at_pos.is_empty():
			valids[position] = valid_rotations_at_pos
			
	return valids

func place_current_card(pos: Vector2i) -> bool:
	if validate_card_placement(pos):
		for dir in IDIRECTIONS:
			var target: Vector2i = pos + dir
			if vgrid.has(target):
				var neighbor = vgrid[target]
				current_drawn_card.connect_side(neighbor, dir)
		
		vgrid[pos] = current_drawn_card
		current_drawn_card.position = pos
		update_adjacents(pos)
		return true
	return false

func validate_card_placement(pos: Vector2i) -> bool:
	if vgrid.has(pos):
		return false
		
	var has_neighbor: bool = false
	
	for dir in IDIRECTIONS:
		var neighbor_pos: Vector2i = pos + dir
		if vgrid.has(neighbor_pos):
			has_neighbor = true
			var neighbor_card: CardStructure = vgrid[neighbor_pos]
			# Checa se as bordas que se tocam são compatíveis
			if not current_drawn_card.is_side_compatible(neighbor_card, dir):
				return false
				
	return has_neighbor

func update_adjacents(placed_pos: Vector2i) -> void:
	vadjacents.erase(placed_pos)
	for dir in IDIRECTIONS:
		var neighbor: Vector2i = placed_pos + dir
		if not vgrid.has(neighbor) and not vadjacents.has(neighbor):
			vadjacents.append(neighbor)

"------------------------------ MEEPLE PLACEMENT -------------------------------"

func get_valid_positions_for_meeple() -> Array[int]:
	var valids: Array[int] = []
	# -1 representa optar por NAO colocar meeple
	valids.append(-1)
	
	# 0 a 11 são as bordas, 12 representa a parte central (se existir)
	for index in range(-1, 12):
		if validate_meeple_placement(index):
			valids.append(index)
	return valids

func place_meeple_at_current_card(index: int) -> bool:
	if index == -1:
		return true
	if not validate_meeple_placement(index):
		return false
	var player: Player = players[current_player_index]
	return current_drawn_card.place_meeple(index, player)

func validate_meeple_placement(index: int) -> bool:
	var player: Player = players[current_player_index]
	# Garante que o jogador tem meeple disponível no estoque
	if player.has_method("has_available_meeple") and not player.has_available_meeple():
		return false
	return current_drawn_card.can_receive_meeple_at(index)

"-------------------------------- TURN CONTROL ---------------------------------"

func pass_turn() -> void:
	var valid_positions: Dictionary[Vector2i, Array] = {}
	
	while true:
		if deck.is_empty():
			finish_game()
			return
			
		current_drawn_card_id = deck.pop_back()
		current_drawn_card = Catalogue.get_structure(current_drawn_card_id)
		valid_positions = get_valid_card_positions()
		
		# Se encontrou posições válidas, sai do loop e passa a vez. 
		# Se não, descarta a carta e puxa a próxima.
		if not valid_positions.is_empty():
			break
		else:
			card_discarded.emit(current_drawn_card_id)
	
	# Rotação circular de índice de jogadores
	current_player_index = (current_player_index + 1) % players.size()
	var player: Player = players[current_player_index]
	
	turn_passed.emit(player, current_drawn_card_id, valid_positions)

func start_game() -> void:
	# Notifica a carta inicial no tabuleiro (player null pois é o mapa gerando)
	card_placed.emit(
		null, Vector2i.ZERO, CardStructure.CARDROTATION.UP,
		[] as Array[int], current_drawn_card_id
		)
	# Define índice inicial para que o primeiro pass_turn resulte no jogador 0
	current_player_index = players.size() - 1
	pass_turn()

func finish_game() -> void:
	# Coleta a pontuação final de todos para enviar no sinal
	var scores: Dictionary = {}
	for player in players:
		scores[player] = player.score if "score" in player else 0
	game_finished.emit(scores)

func _resolve_scores_and_closures() -> void:
	if current_drawn_card:
		current_drawn_card.update_regions()
		
	# Varre a vizinhança 3x3 para atualizar possíveis monastérios
	for x in range(-1, 2):
		for y in range(-1, 2):
			var npos := current_drawn_card_pos + Vector2i(x, y)
			var card: CardStructure = vgrid.get(npos)
			if card:
				card.monastery_update()

static func has_card_at(pos: Vector2i) -> bool:
	return instance != null and instance.vgrid.has(pos)
