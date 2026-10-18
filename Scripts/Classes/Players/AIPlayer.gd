class_name AIPlayer
extends Player

## Implementação concreta de jogador controlado por IA.
## Preenche os hooks do Template Method delegando o cálculo diretamente para a AIStrategy.

var strategy: AIStrategy


func _init(
	p_id: String, 
	p_name: String, 
	p_color: Color, 
	p_strategy: AIStrategy
) -> void:
	super._init(p_id, p_name, p_color)
	strategy = p_strategy if p_strategy else BasicAIStrategy.new()


## Calcula e envia a requisição de posicionamento da carta
func _decide_card_placement(card_id: int, valid_positions: Dictionary[Vector2i, Array]) -> void:
	if Engine.get_main_loop():
		await Engine.get_main_loop().create_timer(0.1).timeout

	if valid_positions.is_empty():
		return

	# Tenta obter a instância ativa no GameManager ou no singleton do LogicInstance
	var logic: LogicInstance = GameManager.active_logic if GameManager.active_logic else LogicInstance.instance
	if logic == null or logic._state_machine.get_current_player() != self:
		return

	var board: Board = logic._board if logic else null
	var decision: Dictionary = strategy.choose_card_placement(card_id, valid_positions, board)

	if decision.has("pos") and decision.has("rotation"):
		request_place_card(decision["pos"], decision["rotation"])
	else:
		var first_pos: Vector2i = valid_positions.keys()[0]
		var first_rot: CardStructure.CARDROTATION = valid_positions[first_pos][0]
		request_place_card(first_pos, first_rot)


## Calcula e envia a requisição de posicionamento do meeple
func _decide_meeple_placement(meeple_valid_indexes: Array[int]) -> void:
	if Engine.get_main_loop():
		await Engine.get_main_loop().create_timer(0.1).timeout

	var logic: LogicInstance = GameManager.active_logic if GameManager.active_logic else LogicInstance.instance
	if logic == null or logic._state_machine.get_current_player() != self:
		return

	var board: Board = logic._board if logic else null
	var card: CardStructure = logic.current_drawn_card if logic else null

	var chosen_slot: int = strategy.choose_meeple_placement(self, card, meeple_valid_indexes, board)
	request_place_meeple(chosen_slot)