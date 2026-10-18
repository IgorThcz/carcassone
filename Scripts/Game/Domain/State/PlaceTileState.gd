class_name PlaceTileState
extends TurnState

func enter() -> void:
	print("[State] Entrou na fase: PLACE_TILE")

func get_name() -> String:
	return "PLACE_TILE"

func place_tile(_pos: Vector2i, _rot: int) -> bool:
	machine.change_state(PlaceMeepleState.new(machine))
	return true