class_name PlaceMeepleState
extends TurnState

func enter() -> void:
	print("[State] Entrou na fase: PLACE_MEEPLE")


func get_name() -> String:
	return "PLACE_MEEPLE"


## Retorna os slots elegíveis da carta atual para consulta pela UI ou pela IA
func get_valid_slots() -> Array[int]:
	if machine and machine.current_card and machine.current_player:
		return machine.current_card.get_valid_meeple_slots(machine.current_player)
	return [CardStructure.SKIP_SLOT_INDEX]


## Executa a alocação do meeple no slot escolhido e avança o estado
func place_meeple(slot_index: int) -> bool:
	if machine == null or machine.current_card == null or machine.current_player == null:
		return false

	# Aplica a alocação diretamente na CardStructure (valida e consome a reserva do jogador)
	var success: bool = machine.current_card.place_meeple(slot_index, machine.current_player)
	if success:
		machine.change_state(ResolveScoreState.new(machine))
		return true

	return false


## Pula a fase de posicionamento de meeple no turno
func skip_meeple() -> bool:
	if machine:
		machine.change_state(ResolveScoreState.new(machine))
		return true
	return false
