@abstract class_name View extends Node3D

# Sinais para comunicar com a UI Overlay / GameController
signal tile_placement_requested(grid_pos: Vector2i, rot: CardStructure.CARDROTATION)
signal meeple_placement_requested(card_pos: Vector2i, meeple_index: int)

enum STATE {
	PLACING_CARD,
	EXPECTING_ANSWER_CARD,
	PLACING_MEEPLE,
	EXPECTING_ANSWER_MEEPLE,
	WAITING
	}
var state : STATE = STATE.WAITING

"------------------------ APPEARENCE UPDATE ----------------------"

@abstract
func add_card(pos: Vector2i, id : int, rot : CardStructure.CARDROTATION) -> void

@abstract
func add_meeple(card_pos: Vector2i, meeple_index : int) -> void

@abstract
func remove_meeple(card_pos: Vector2i) -> void

"--------------------------- MODE SELECTION ----------------------"

@abstract
func go_place_card_mode(
	card_id : int,
	vadjacents: Dictionary[Vector2i, Array]
) -> void

@abstract
func go_place_meeple_mode(valids: Array[int]) -> void

@abstract
func exit_all_modes() -> void
