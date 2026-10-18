class_name DrawTileState
extends TurnState

func enter() -> void:
	print("[State] Entrou na fase: DRAW_TILE")

func get_name() -> String:
	return "DRAW_TILE"

func draw_tile() -> bool:
	# Transiciona polimorficamente para a próxima fase
	machine.change_state(PlaceTileState.new(machine))
	return true